import SpriteKit

public enum SkeletonRuntimeMode { case legacy, meshes }

public extension Skeleton {
    // Mesh clip actions (including copies and containers) must run on their creating
    // Skeleton. Foreign-node execution has no validation or mutation-safety guarantee.
    convenience init(meshAsset: SpineMeshAsset, skin: String? = nil) throws {
        self.init(skins: [], animations: [])
        meshRuntime = try MeshRuntime(asset: meshAsset, owner: self, skin: skin)
    }

    var runtimeMode: SkeletonRuntimeMode { meshRuntime == nil ? .legacy : .meshes }
    var meshPlaybackError: SpineRuntimeError? { meshRuntime?.playbackError }
    var meshDiagnosticHandler: ((SpineRuntimeError) -> Void)? {
        get { meshDiagnosticCallback }
        set { meshDiagnosticCallback = newValue }
    }

    /// Mesh geometry/attachment lookup is connected in the following integration phase.
    func meshAttachmentNode(named: String, inSlot: String) -> SKNode? { nil }

    /// Invalidate all previously obtained clip actions. Remove external action containers separately.
    func stopMeshAnimation(resetToSetupPose: Bool = false) {
        meshRuntime?.stop(resetToSetupPose: resetToSetupPose)
    }

    #if os(iOS) || os(macOS) || os(tvOS)
    func prepareMeshes(in view: SKView) throws {
        guard let runtime = meshRuntime else { return }
        if let error = runtime.playbackError { throw error }
        guard scene != nil, scene === view.scene else {
            try runtime.rejectFrame(message: "The Skeleton must belong to the SKView's current scene.", owner: self)
        }
        throw SpineRuntimeError(.unsupportedFeature, path: "/runtime/frame", message: "Native framebuffer mapping is not implemented in the lifecycle shell. Use an explicit frame context.")
    }
    #endif

    func prepareMeshes(for context: SpineMeshFrameContext) throws {
        try meshRuntime?.prepare(context, owner: self)
    }
}
