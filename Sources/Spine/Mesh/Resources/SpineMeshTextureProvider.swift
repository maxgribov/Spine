import SpriteKit

public protocol SpineMeshTextureProvider {
    func region(named path: String) throws -> SpineMeshTextureRegion
}

public struct SpineMeshTextureRegion {
    public let texture: SKTexture
    public let pixelSize: CGSize
    public let originalSize: CGSize
    public let trimRect: CGRect
    public let uvTransform: CGAffineTransform

    public init(texture: SKTexture, pixelSize: CGSize, originalSize: CGSize,
                trimRect: CGRect, uvTransform: CGAffineTransform) throws {
        // Signature shell. Resource validation/atlas loading lands with compilation.
        throw SpineRuntimeError(.unsupportedFeature, path: "/runtime/resources",
                                message: "Mesh texture resources are not implemented in the lifecycle shell.")
    }
}

public final class SpineAtlasTextureProvider: SpineMeshTextureProvider {
    public init(atlasText: String, pageData: [String: Data]) throws {
        throw SpineRuntimeError(.unsupportedFeature, path: "/runtime/resources",
                                message: "Spine atlas loading is not implemented in the lifecycle shell.")
    }
    public func region(named path: String) throws -> SpineMeshTextureRegion {
        throw SpineRuntimeError(.unsupportedFeature, path: "/textures/" + SpineRuntimeError.pointerComponent(path),
                                message: "Spine atlas loading is not implemented in the lifecycle shell.")
    }
}
