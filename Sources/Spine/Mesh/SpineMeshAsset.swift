import SpriteKit

/// Immutable input for the opt-in mesh runtime. JSON compilation follows in phase 3.
public final class SpineMeshAsset {
    let compiled: CompiledMeshSkeleton
    public var animationNames: [String] { compiled.clips.map(\.name) }
    public var skinNames: [String] { compiled.skinNames }

    public convenience init(json: Data, textures: SpineMeshTextureProvider) throws {
        // Deliberately no second decoder or temporary schema fallback.
        let model = try JSONDecoder().decode(SpineModel.self, from: json)
        try self.init(model: model, textures: textures)
    }

    public init(model: SpineModel, textures: SpineMeshTextureProvider) throws {
        #if os(tvOS) || os(watchOS)
        throw SpineRuntimeError(.unsupportedPlatform, path: "/runtime/platform", message: "Meshes are not supported on this platform.")
        #else
        throw SpineRuntimeError(.unsupportedFeature, path: "/runtime/loading", message: "Mesh asset compilation is not implemented in the lifecycle shell.")
        #endif
    }

    init(compiled: CompiledMeshSkeleton) { self.compiled = compiled }
}
