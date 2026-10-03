import SpriteKit

/// The binding can be copied by SpriteKit. It contains no execution-local state.
private final class MeshActionBinding {
    weak var owner: Skeleton?
    let epoch: UInt64
    let clip: MeshClip
    let identity = UUID()

    init(owner: Skeleton, epoch: UInt64, clip: MeshClip) {
        self.owner = owner; self.epoch = epoch; self.clip = clip
    }
}

struct MeshPlaybackSnapshot {
    let epoch: UInt64
    let executionID: UInt64?
    let beginCount: UInt64
    let endCount: UInt64
    let time: TimeInterval
    let deform: [[Float]]
    let activeAttachments: [String?]
    let drawOrder: [Int]
}

final class MeshRuntime {
    private struct Execution {
        let id: UInt64
        let bindingID: UUID
        var previousTime: TimeInterval = -1
        var nextEvent = 0
        var cursors: [Int]
    }

    let asset: SpineMeshAsset
    let bones: [Bone]
    let slots: [Slot]
    let managedVisuals = SKNode()
    private(set) var epoch: UInt64 = 0
    private var nextExecutionID: UInt64 = 0
    private var completedExecutions: UInt64 = 0
    private var execution: Execution?
    private(set) var playbackError: SpineRuntimeError?
    private var frameError: SpineRuntimeError?
    private(set) var preparedContext: SpineMeshFrameContext?
    private(set) var time: TimeInterval = 0
    private(set) var deform: [[Float]]
    private(set) var activeAttachments: [String?]
    private(set) var drawOrder: [Int]
    private(set) var selectedSkin: String

    init(asset: SpineMeshAsset, owner: Skeleton, skin: String?) throws {
        let compiled = asset.compiled
        let selected = skin ?? (compiled.skinNames.contains("default") ? "default" : compiled.skinNames.first ?? "default")
        guard compiled.skinNames.contains(selected) else {
            throw SpineRuntimeError(.missingSkin, path: "/skins/" + SpineRuntimeError.pointerComponent(selected), message: "Skin not found.")
        }
        self.asset = asset; selectedSkin = selected
        bones = compiled.bones.map(Bone.init)
        slots = compiled.slots.enumerated().map { Slot($0.element, $0.offset) }
        deform = compiled.deformComponentCounts.map { Array(repeating: 0, count: $0) }
        activeAttachments = compiled.slots.map(\.attachment)
        drawOrder = Array(compiled.slots.indices)
        for (index, model) in compiled.bones.enumerated() {
            if let parent = model.parent, let parentIndex = compiled.bones.firstIndex(where: { $0.name == parent }) {
                bones[parentIndex].addChild(bones[index])
            } else { owner.addChild(bones[index]) }
        }
        for (index, model) in compiled.slots.enumerated() {
            if let bone = compiled.bones.firstIndex(where: { $0.name == model.bone }) { bones[bone].addChild(slots[index]) }
        }
        managedVisuals.name = "_spine_mesh_render"
        owner.addChild(managedVisuals)
    }

    var snapshot: MeshPlaybackSnapshot {
        MeshPlaybackSnapshot(epoch: epoch, executionID: execution?.id, beginCount: nextExecutionID,
                             endCount: completedExecutions, time: time,
                             deform: deform, activeAttachments: activeAttachments, drawOrder: drawOrder)
    }

    func action(named name: String, owner: Skeleton) throws -> SKAction {
        guard let clip = asset.compiled.clips.first(where: { $0.name == name }) else {
            throw SpineRuntimeError(.missingAnimation, path: "/animations/" + SpineRuntimeError.pointerComponent(name), message: "Animation not found.")
        }
        let binding = MeshActionBinding(owner: owner, epoch: epoch, clip: clip)
        // Caller precondition: the action and its copies/containers run on their owner.
        // .run boundaries execute once, unlike zero-duration custom callbacks at speed < 1.
        // The timed callback does not reliably receive t=0, so begin samples setup+t=0.
        return .sequence([
            .run {
                guard let owner = binding.owner, let runtime = owner.meshRuntime else { return }
                runtime.begin(binding, owner: owner)
            },
            .customAction(withDuration: clip.duration) { node, elapsed in
                guard let owner = binding.owner, node === owner, let runtime = owner.meshRuntime else { return }
                runtime.sample(binding, at: min(clip.duration, TimeInterval(elapsed)), owner: owner)
            },
            .run {
                guard let owner = binding.owner, let runtime = owner.meshRuntime else { return }
                runtime.end(binding, owner: owner)
            }
        ])
    }

    private func begin(_ binding: MeshActionBinding, owner: Skeleton) {
        guard binding.epoch == epoch, playbackError == nil else { return }
        guard execution == nil else {
            let error = SpineRuntimeError(.concurrentClip,
                path: "/runtime/animations/" + SpineRuntimeError.pointerComponent(binding.clip.name),
                message: "Only one Spine clip execution may be active on a mesh Skeleton.")
            playbackError = error; managedVisuals.isHidden = true
            owner.meshDiagnosticHandler?(error)
            return
        }
        nextExecutionID &+= 1
        execution = Execution(id: nextExecutionID, bindingID: binding.identity,
                              cursors: Array(repeating: 0, count: binding.clip.channels.count))
        restoreSetup()
        sample(binding, at: 0, owner: owner)
    }

    private func matches(_ binding: MeshActionBinding, executionID: UInt64) -> Bool {
        binding.epoch == epoch && playbackError == nil
            && execution?.id == executionID && execution?.bindingID == binding.identity
    }

    private func sample(_ binding: MeshActionBinding, at elapsed: TimeInterval, owner: Skeleton) {
        guard binding.epoch == epoch, playbackError == nil,
              let current = execution, current.bindingID == binding.identity,
              elapsed >= current.previousTime else { return }
        let id = current.id
        for (index, channel) in binding.clip.channels.enumerated() {
            var cursor = execution!.cursors[index]
            let defaultValue: Float
            switch channel.target {
            case .boneScaleX, .boneScaleY: defaultValue = 1
            default: defaultValue = 0
            }
            let value = channel.timeline.sample(Float(elapsed), default: defaultValue, cursor: &cursor)
            execution!.cursors[index] = cursor
            switch channel.target {
            case .boneX(let bone): bones[bone].position.x = bones[bone].model.position.x + CGFloat(value)
            case .boneY(let bone): bones[bone].position.y = bones[bone].model.position.y + CGFloat(value)
            case .boneRotation(let bone): bones[bone].zRotation = (bones[bone].model.rotation + CGFloat(value)) * degreeToRadiansFactor
            case .boneScaleX(let bone): bones[bone].xScale = bones[bone].model.scale.dx * CGFloat(value)
            case .boneScaleY(let bone): bones[bone].yScale = bones[bone].model.scale.dy * CGFloat(value)
            case let .deform(slot, component): deform[slot][component] = value
            }
        }
        time = elapsed
        execution!.previousTime = elapsed
        // Advance the cursor BEFORE external code, then recheck the captured execution.
        while matches(binding, executionID: id), let next = execution?.nextEvent,
              next < binding.clip.events.count, binding.clip.events[next].time <= elapsed {
            let event = binding.clip.events[next]
            execution!.nextEvent += 1
            owner.eventTriggered?(event.value)
            guard matches(binding, executionID: id) else { return }
        }
    }

    private func end(_ binding: MeshActionBinding, owner: Skeleton) {
        guard binding.epoch == epoch, playbackError == nil,
              let current = execution, current.bindingID == binding.identity else { return }
        sample(binding, at: binding.clip.duration, owner: owner)
        // A final event may stop/restart playback. Never release its new lease.
        guard matches(binding, executionID: current.id) else { return }
        execution = nil
        completedExecutions &+= 1
    }

    func stop(resetToSetupPose: Bool) {
        epoch &+= 1
        execution = nil; playbackError = nil
        if resetToSetupPose { restoreSetup() }
        managedVisuals.isHidden = frameError != nil || preparedContext?.isSingular == true
    }

    private func restoreSetup() {
        for bone in bones { bone.dropToDefaults() }
        activeAttachments = asset.compiled.slots.map(\.attachment)
        drawOrder = Array(asset.compiled.slots.indices)
        for slot in deform.indices {
            for component in deform[slot].indices { deform[slot][component] = 0 }
        }
        time = 0
    }

    func validateSkin(_ name: String) throws {
        guard asset.skinNames.contains(name) else {
            throw SpineRuntimeError(.missingSkin, path: "/skins/" + SpineRuntimeError.pointerComponent(name), message: "Skin not found.")
        }
        guard name == selectedSkin else {
            throw SpineRuntimeError(.unsupportedFeature, path: "/skins/" + SpineRuntimeError.pointerComponent(name), message: "Skin replacement requires the mesh attachment runtime.")
        }
    }

    /// All recoverable frame failures share one incident and stay hidden through stop/reset.
    /// Only a successful prepare clears the incident and allows visibility to recover.
    func rejectFrame(message: String, owner: Skeleton) throws -> Never {
        let error = SpineRuntimeError(.invalidRenderContext, path: "/runtime/frame", message: message)
        managedVisuals.isHidden = true
        if frameError == nil { frameError = error; owner.meshDiagnosticHandler?(error) }
        throw error
    }

    func prepare(_ context: SpineMeshFrameContext, owner: Skeleton) throws {
        if let error = playbackError { managedVisuals.isHidden = true; throw error }
        guard context.isValid else {
            try rejectFrame(message: "Frame transform and positive integral pixel dimensions must be finite.", owner: owner)
        }
        frameError = nil; preparedContext = context
        managedVisuals.isHidden = context.isSingular
    }
}
