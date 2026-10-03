import CoreGraphics

/// Maps skeleton-local coordinates to the actual target's fragment coordinates.
public struct SpineMeshFrameContext {
    public let skeletonToPixels: CGAffineTransform
    public let pixelSize: CGSize

    public init(skeletonToPixels: CGAffineTransform, pixelSize: CGSize) {
        self.skeletonToPixels = skeletonToPixels; self.pixelSize = pixelSize
    }

    var isValid: Bool {
        let t = skeletonToPixels
        return [t.a, t.b, t.c, t.d, t.tx, t.ty, pixelSize.width, pixelSize.height].allSatisfy(\.isFinite)
            && pixelSize.width > 0 && pixelSize.height > 0
            && pixelSize.width.rounded() == pixelSize.width && pixelSize.height.rounded() == pixelSize.height
    }
    var isSingular: Bool {
        let t = skeletonToPixels
        return t.a * t.d - t.b * t.c == 0
    }
}
