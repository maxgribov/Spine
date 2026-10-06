/// A complete ordered appearance over one fixed single-skin base.
public struct SpineSkinComposition: Equatable {
    public let baseSkin: String
    public let layers: [SpineSkinLayer]

    public init(baseSkin: String, layers: [SpineSkinLayer]) {
        self.baseSkin = baseSkin
        self.layers = layers
    }
}

public enum SpineSkinLayer: Equatable {
    /// Adds only the skin's own keys, overriding earlier matching keys.
    case overlay(skin: String)
    /// Replaces every state of the selected slots with the skin's own entries.
    case replace(skin: String, slots: [String])
    /// Removes every state of the selected slots, without fallback.
    case hide(slots: [String])
}

public extension SpineMeshAsset {
    /// Checks content without creating scene objects or changing any live Skeleton.
    /// Serialize access to the asset; this does not preflight the render context.
    func validate(skinComposition: SpineSkinComposition) throws {
        _ = try SkinCompositionResolver.resolve(skinComposition, in: compiled)
    }
}

public extension Skeleton {
    var skinComposition: SpineSkinComposition? { meshRuntime?.skinComposition }

    /// Atomically changes region layers, preserving playback. Finish with prepareMeshes
    /// before rendering. Serialize with scene updates; Spine event callbacks are allowed.
    func apply(skinComposition: SpineSkinComposition) throws {
        guard let runtime=meshRuntime else {
            throw SpineRuntimeError(.unsupportedFeature,path:"/runtime/skinComposition",message:"Skin composition requires a compiled mesh asset.")
        }
        try runtime.applyComposition(skinComposition)
    }
}
