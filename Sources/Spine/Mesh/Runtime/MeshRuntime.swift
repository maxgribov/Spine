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

struct MeshPlaybackSnapshot: Equatable {
    let epoch: UInt64
    let executionID: UInt64?
    let beginCount: UInt64
    let endCount: UInt64
    let time: TimeInterval
    let deform: [[Float]]
    let activeAttachments: [String?]
    let drawOrder: [Int]
    let requestedAttachments: [String?]
    let cursors: [Int]
    let attachmentCursors: [Int]
    let deformCursors: [Int]
    let nextEvent: Int?
    let previousTime: TimeInterval?
}

final class MeshRuntime {
    private struct Execution {
        let id: UInt64
        let bindingID: UUID
        var previousTime: TimeInterval = -1
        var nextEvent = 0
        var cursors: [Int]
        var attachmentCursors:[Int]
        var deformCursors:[Int]
        var drawCursor=0
    }

    let asset: SpineMeshAsset
    let bones: [Bone]
    let slots: [Slot]
    private(set) var managedVisuals = SKNode()
    private(set) var setupRenderer:MeshSetupRenderer?
    private(set) var epoch: UInt64 = 0
    private var nextExecutionID: UInt64 = 0
    private var completedExecutions: UInt64 = 0
    private var execution: Execution?
    private(set) var playbackError: SpineRuntimeError?
    private var frameError: SpineRuntimeError?
    private(set) var preparedContext: SpineMeshFrameContext?
    private(set) var time: TimeInterval = 0
    private(set) var slotStates:[MeshSlotState]
    private var skinLookup:[MeshAttachmentKey:Int]
    var deform:[[Float]] {slotStates.map(\.deform)}
    var activeAttachments:[String?] {slotStates.map(\.activeName)}
    private(set) var drawOrder: [Int]
    private(set) var selectedSkin: String
    private(set) var skinComposition: SpineSkinComposition?
    private var compositionSlots = Set<Int>()
    // Internal transaction fault seam; invoked only while nodes are detached.
    var compositionStageCheck: ((SKNode) throws -> Void)?

    init(asset: SpineMeshAsset, owner: Skeleton, skin: String?) throws {
        let compiled = asset.compiled
        let selected = skin ?? (compiled.skinNames.contains("default") ? "default" : compiled.skinNames.first ?? "default")
        guard compiled.skinNames.contains(selected) else {
            throw SpineRuntimeError(.missingSkin, path: "/skins/" + SpineRuntimeError.pointerComponent(selected), message: "Skin not found.")
        }
        self.asset = asset; selectedSkin = selected
        bones = compiled.bones.map(Bone.init)
        slots = compiled.slots.enumerated().map { Slot($0.element, $0.offset) }
        slotStates=compiled.slots.enumerated().map {MeshSlotState(color:SIMD4($0.element.color.channels.map(Float.init)),deformCount:compiled.deformComponentCounts[$0.offset])}
        skinLookup=compiled.skinAttachments["default"] ?? [:]
        for (key,id) in compiled.skinAttachments[selected] ?? [:] {skinLookup[key]=id}
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
        restoreSetup()
        if !compiled.attachments.isEmpty {
            setupRenderer=try MeshSetupRenderer(compiled:compiled,resources:asset.rendererResources,bones:bones,slots:slots,root:managedVisuals,skin:selected)
            setupRenderer!.installLogicalAttachments(states:slotStates)
        }
    }

    var snapshot: MeshPlaybackSnapshot {
        MeshPlaybackSnapshot(epoch: epoch, executionID: execution?.id, beginCount: nextExecutionID,
                             endCount: completedExecutions, time: time,
                             deform: deform, activeAttachments: activeAttachments, drawOrder: drawOrder,
                             requestedAttachments:slotStates.map(\.requestedName),cursors:execution?.cursors ?? [],
                             attachmentCursors:execution?.attachmentCursors ?? [],deformCursors:execution?.deformCursors ?? [],
                             nextEvent:execution?.nextEvent,previousTime:execution?.previousTime)
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
                              cursors:Array(repeating:0,count:binding.clip.channels.count),
                              attachmentCursors:Array(repeating:0,count:binding.clip.attachments.count),
                              deformCursors:Array(repeating:0,count:binding.clip.deforms.count))
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
            case let .slotColor(slot,component):defaultValue=slotStates[slot].setupColor[component]
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
            case let .deform(slot, component): slotStates[slot].deform[component] = value
            case let .slotColor(slot,component):slotStates[slot].color[component]=value
            }
        }
        let sampleTime=Float(elapsed)
        for (index,timeline) in binding.clip.attachments.enumerated() {
            guard let first=timeline.keys.first,sampleTime>=first.time else {continue}
            var cursor=execution!.attachmentCursors[index]
            while cursor+1<timeline.keys.count && timeline.keys[cursor+1].time<=sampleTime {cursor+=1}
            execution!.attachmentCursors[index]=cursor
            selectAttachment(timeline.keys[cursor].name,slot:timeline.slot)
        }
        if let first=binding.clip.drawOrders.first,sampleTime>=first.time {
            var cursor=execution!.drawCursor
            while cursor+1<binding.clip.drawOrders.count && binding.clip.drawOrders[cursor+1].time<=sampleTime {cursor+=1}
            execution!.drawCursor=cursor;drawOrder=binding.clip.drawOrders[cursor].order
        }
        for (index,timeline) in binding.clip.deforms.enumerated() {
            let state=slotStates[timeline.slot]
            guard state.deformSourceID==timeline.attachmentID,let first=timeline.keys.first else {continue}
            guard sampleTime>=first.time else {for i in state.deform.indices {state.deform[i]=0};continue}
            var cursor=execution!.deformCursors[index]
            while cursor+1<timeline.keys.count && timeline.keys[cursor+1].time<=sampleTime {cursor+=1}
            execution!.deformCursors[index]=cursor
            let frame=timeline.keys[cursor]
            var curveCursor=0
            let fraction=frame.progress?.sample(sampleTime,default:0,cursor:&curveCursor) ?? 0
            for vertex in frame.deltas.indices {
                let value:SIMD2<Float>
                if cursor+1<timeline.keys.count {value=frame.deltas[vertex]+(timeline.keys[cursor+1].deltas[vertex]-frame.deltas[vertex])*fraction}
                else {value=frame.deltas[vertex]}
                state.deform[vertex*2]=value.x;state.deform[vertex*2+1]=value.y
            }
        }
        setupRenderer?.updateLogicalActivity(states:slotStates)
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

    private func sourceID(_ id:Int?)->Int? {
        guard let id=id,case .mesh(let mesh)=asset.compiled.attachments[id].content else {return nil}
        return mesh.deformSourceID
    }
    private func selectAttachment(_ name:String?,slot:Int) {
        slotStates[slot].requestedName=name
        let id=name.flatMap {skinLookup[.init(slot:slot,name:$0)]}
        let fixture=asset.compiled.attachments.isEmpty && asset.compiled.sourceAnimations.isEmpty && !asset.compiled.clips.isEmpty
        slotStates[slot].select(id != nil || fixture ? name:nil,id:id,source:sourceID(id))
    }
    private func restoreSetup() {
        for bone in bones {bone.dropToDefaults()}
        for slot in slotStates.indices {
            selectAttachment(asset.compiled.slots[slot].attachment,slot:slot)
            slotStates[slot].color=slotStates[slot].setupColor
            for component in slotStates[slot].deform.indices {slotStates[slot].deform[component]=0}
        }
        drawOrder=Array(asset.compiled.slots.indices);time=0
        setupRenderer?.updateLogicalActivity(states:slotStates)
    }

    func validateSkin(_ name:String)throws {
        guard asset.skinNames.contains(name) else {
            throw SpineRuntimeError(.missingSkin,path:"/skins/"+SpineRuntimeError.pointerComponent(name),message:"Skin not found.")
        }
    }
    func applySkin(_ name:String,owner:Skeleton)throws {
        try validateSkin(name)
        guard name != selectedSkin || skinComposition != nil else {return}
        var lookup=asset.compiled.skinAttachments["default"] ?? [:]
        for (key,id) in asset.compiled.skinAttachments[name] ?? [:] {lookup[key]=id}
        let nextStates=slotStates.enumerated().map {slot,state->MeshSlotState in
            let next=state.copied()
            let old=state.activeName.flatMap {lookup[.init(slot:slot,name:$0)]}
            let fallback=asset.compiled.slots[slot].attachment.flatMap {lookup[.init(slot:slot,name:$0)]}
            let id=old ?? fallback
            next.select(id.map {asset.compiled.attachments[$0].name},id:id,source:sourceID(id))
            next.requestedName=next.activeName
            return next
        }
        let root=SKNode();root.name=managedVisuals.name
        let renderer=try MeshSetupRenderer(compiled:asset.compiled,resources:asset.rendererResources,bones:bones,slots:slots,root:root,skin:name)
        // Construction above touches neither live slot state nor logical point/physics nodes.
        setupRenderer?.removeLogicalAttachments(states:slotStates)
        managedVisuals.removeFromParent();owner.addChild(root)
        managedVisuals=root;setupRenderer=renderer;slotStates=nextStates;skinLookup=lookup;selectedSkin=name
        skinComposition=nil;compositionSlots=[]
        root.isHidden=playbackError != nil || frameError != nil || preparedContext?.isSingular == true
        renderer.installLogicalAttachments(states:slotStates)
    }

    func applyComposition(_ composition:SpineSkinComposition)throws {
        if skinComposition == composition {return}
        let result=try SkinCompositionResolver.resolve(composition,in:asset.compiled)
        guard composition.baseSkin == selectedSkin else {
            throw SpineRuntimeError(.skinCompositionBaseMismatch,path:"/composition/baseSkin",message:"Composition base must match the selected single skin '\(selectedSkin)'.")
        }
        let changed=compositionSlots.union(result.touchedSlots)
        var nextStates=slotStates
        for slot in changed {
            let next=slotStates[slot].copied()
            let id=next.requestedName.flatMap {result.lookup[.init(slot:slot,name:$0)]}
            next.select(id.map {asset.compiled.attachments[$0].name},id:id,source:sourceID(id))
            nextStates[slot]=next
        }
        let staged=try setupRenderer?.stageRegions(lookup:result.lookup,slots:changed,resources:asset.rendererResources,check:compositionStageCheck)
        // No throws, scene callbacks, physics transitions or resampling after this boundary.
        if let staged=staged {setupRenderer?.commitRegions(staged,slots:changed)}
        slotStates=nextStates;skinLookup=result.lookup;skinComposition=composition;compositionSlots=result.touchedSlots
    }

    /// All recoverable frame failures share one incident and stay hidden through stop/reset.
    /// Only a successful prepare clears the incident and allows visibility to recover.
    func rejectFrame(message: String, owner: Skeleton) throws -> Never {
        let error = SpineRuntimeError(.invalidRenderContext, path: "/runtime/frame", message: message)
        managedVisuals.isHidden = true
        if frameError == nil { frameError = error; owner.meshDiagnosticHandler?(error) }
        throw error
    }

    func prepare(_ context: SpineMeshFrameContext, owner: Skeleton, viewError:String?=nil) throws {
        let numericError=setupRenderer?.reconcile(owner:owner,states:slotStates)
        if let error=playbackError {managedVisuals.isHidden=true;throw error}
        do {
            if let error=numericError {throw error}
            if let message=viewError {try rejectFrame(message:message,owner:owner)}
            guard context.isValid else {try rejectFrame(message:"Frame transform and positive integral pixel dimensions must be finite.",owner:owner)}
            var ancestor=owner.parent
            while let node=ancestor {
                let unsupported:Bool
                if let scene=node as? SKScene {
                    #if os(watchOS)
                    unsupported=scene.shouldRasterize
                    #else
                    unsupported=scene.shouldRasterize || (scene.shouldEnableEffects && scene.filter != nil)
                    #endif
                }
                else {unsupported=node is SKEffectNode || node is SKCropNode}
                if unsupported {
                    throw SpineRuntimeError(.unsupportedFeature,path:"/runtime/nodes/"+SpineRuntimeError.pointerComponent(node.name ?? String(describing:type(of:node))),message:"Mesh rendering does not support effect/crop intermediate framebuffers.")
                }
                ancestor=node.parent
            }
            try setupRenderer?.prepare(owner:owner,context:context,states:slotStates,drawOrder:drawOrder)
        }
        catch let error as SpineRuntimeError {
            managedVisuals.isHidden=true
            if frameError?.code != error.code || frameError?.path != error.path {frameError=error;owner.meshDiagnosticHandler?(error)}
            throw error
        }
        frameError = nil; preparedContext = context
        managedVisuals.isHidden = context.isSingular
    }
}
