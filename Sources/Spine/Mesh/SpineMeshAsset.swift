import SpriteKit

/// Validated immutable Spine 4.1 setup data and resources for opt-in mesh rendering.
public final class SpineMeshAsset {
    let compiled: CompiledMeshSkeleton
    let rendererResources:MeshRendererResources
    public var animationNames: [String] { compiled.sourceAnimationNames }
    public var skinNames: [String] { compiled.skinNames }

    public convenience init(json: Data, textures: SpineMeshTextureProvider) throws {
        #if os(tvOS) || os(watchOS)
        throw SpineRuntimeError(.unsupportedPlatform,path:"/runtime/platform",message:"Meshes are not supported on this platform.")
        #else
        do {
            let model=try JSONDecoder().decode(SpineModel.self,from:json)
            try self.init(model:model,textures:textures)
        } catch {throw MeshAssetCompiler.wrap(error)}
        #endif
    }

    public init(model: SpineModel, textures: SpineMeshTextureProvider) throws {
        #if os(tvOS) || os(watchOS)
        throw SpineRuntimeError(.unsupportedPlatform,path:"/runtime/platform",message:"Meshes are not supported on this platform.")
        #else
        compiled=try MeshAssetCompiler(model:model).compile(textures:textures)
        rendererResources=MeshRendererResources(attachments:compiled.attachments)
        #endif
    }

    init(compiled: CompiledMeshSkeleton) { self.compiled = compiled;rendererResources=MeshRendererResources(attachments:compiled.attachments) }
}
