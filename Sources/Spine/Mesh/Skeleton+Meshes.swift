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

    /// Inspect-only mesh renderer node from the selected/default skin.
    func meshAttachmentNode(named: String, inSlot: String) -> SKNode? { meshRuntime?.setupRenderer?.meshNode(named:named,slot:inSlot) }

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
        let scene=self.scene!
        #if os(macOS)
        let scale=view.window?.backingScaleFactor ?? view.convertToBacking(CGSize(width:1,height:1)).width
        #else
        let scale=view.contentScaleFactor
        #endif
        func pixel(_ point:CGPoint)->CGPoint {
            let p=scene.convertPoint(toView:convert(point,to:scene))
            #if os(macOS)
            return CGPoint(x:(p.x-view.bounds.minX)*scale,y:(view.isFlipped ? p.y-view.bounds.minY:view.bounds.maxY-p.y)*scale)
            #else
            return CGPoint(x:(p.x-view.bounds.minX)*scale,y:(p.y-view.bounds.minY)*scale)
            #endif
        }
        let origin=pixel(.zero),x=pixel(CGPoint(x:1024,y:0)),y=pixel(CGPoint(x:0,y:1024))
        let transform=CGAffineTransform(a:(x.x-origin.x)/1024,b:(x.y-origin.y)/1024,c:(y.x-origin.x)/1024,d:(y.y-origin.y)/1024,tx:origin.x,ty:origin.y)
        try runtime.prepare(SpineMeshFrameContext(skeletonToPixels:transform,pixelSize:CGSize(width:(view.bounds.width*scale).rounded(),height:(view.bounds.height*scale).rounded())),owner:self)
    }
    #endif

    func prepareMeshes(for context: SpineMeshFrameContext) throws {
        try meshRuntime?.prepare(context, owner: self)
    }
}
