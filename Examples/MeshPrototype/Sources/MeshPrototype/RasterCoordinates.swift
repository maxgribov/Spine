import SpriteKit
import TriangleRenderer

/// Supplies one common framebuffer coordinate system to all triangles of a mesh.
func prepareRasterCoordinates(root: SKNode, pointToPixels: (CGPoint) -> CGPoint) {
    func visit(_ node: SKNode) {
        if let mesh = node as? TriangleMeshNode, mesh.boundsMode == .triangle {
            let origin = pointToPixels(root.convert(.zero, from: mesh))
            let x = pointToPixels(root.convert(CGPoint(x: 1024, y: 0), from: mesh))
            let y = pointToPixels(root.convert(CGPoint(x: 0, y: 1024), from: mesh))
            mesh.prepareForRendering(localToPixels: CGAffineTransform(a: (x.x-origin.x)/1024, b: (x.y-origin.y)/1024,
                c: (y.x-origin.x)/1024, d: (y.y-origin.y)/1024, tx: origin.x, ty: origin.y))
            return
        }
        if !node.isHidden { node.children.forEach(visit) }
    }
    visit(root)
}
func prepareRasterCoordinates(scene: SKScene, view: SKView) {
    let scale = view.window?.backingScaleFactor ?? 1
    prepareRasterCoordinates(root: scene) { point in
        let p = scene.convertPoint(toView: point)
        return CGPoint(x: p.x*scale, y: (view.isFlipped ? p.y : view.bounds.height-p.y)*scale)
    }
}
func prepareRasterCoordinates(root: SKNode, crop: CGRect, scale: CGFloat, topLeftOrigin: Bool = false) {
    // SKView.texture(from:) flips its offscreen target; native Metal drawables
    // and SKRenderer use the top-left Metal fragment coordinate origin.
    prepareRasterCoordinates(root: root) {
        CGPoint(x: ($0.x-crop.minX)*scale, y: (topLeftOrigin ? crop.maxY-$0.y : $0.y-crop.minY)*scale)
    }
}
func capture(view: SKView, node: SKNode, crop: CGRect) throws -> CGImage {
    let root: SKNode
    // SKView texture(from:) includes the captured node's own transform.
    // An identity wrapper makes the conversion's coordinate system explicit.
    if node is SKScene { root = node }
    else {
        guard node.parent == nil else { throw PrototypeError("Capture expects a detached root") }
        root = SKNode(); root.addChild(node)
    }
    defer { if root !== node { node.removeFromParent() } }
    let scale = view.window?.backingScaleFactor ?? 1
    prepareRasterCoordinates(root: root, crop: crop, scale: scale)
    guard let texture = view.texture(from: root, crop: crop) else { throw PrototypeError("Capture failed") }
    let image = texture.cgImage()
    guard image.width == Int(crop.width*scale), image.height == Int(crop.height*scale) else {
        throw PrototypeError("Unexpected offscreen pixel density")
    }
    return image
}
