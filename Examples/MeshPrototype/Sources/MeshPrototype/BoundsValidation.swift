import SpriteKit
import TriangleRenderer

/// Exercises moving shared edges, not just the symmetric initial fan.
func verifyOptimizedBounds(view: SKView, output: URL) throws -> [String] {
    let texture = SKTexture(data: Data([128,128,128,128]), size: CGSize(width: 1, height: 1))
    let fan = [0,1,4, 1,2,4, 2,3,4, 3,0,4]
    let uv = squareUV + [SIMD2<Float>(0.5,0.5)]
    let baseline = try TriangleMeshNode(texture: texture, positions: square + [SIMD2(64,64)], uvs: uv, indices: fan, boundsMode: .mesh)
    let optimized = try TriangleMeshNode(texture: texture, positions: square + [SIMD2(64,64)], uvs: uv, indices: fan, boundsMode: .triangle)
    let reference = SKSpriteNode(texture: texture, size: CGSize(width: 128, height: 128))
    reference.anchorPoint = .zero
    let crop = CGRect(x: -64, y: -64, width: 320, height: 320)
    func render(_ node: SKNode) throws -> CGImage {
        try capture(view: view, node: node, crop: crop)
    }
    var maximum = 0, compared = 0, edgePixels = 0
    func compare(_ expected: CGImage, _ actual: CGImage, name: String) throws {
        guard expected.width == actual.width, expected.height == actual.height else { throw PrototypeError("Bounds capture sizes differ") }
        let a = try bitmap(expected), b = try bitmap(actual)
        var bad = 0
        for pixel in 0..<(a.count/4) {
            let differences = (0..<4).map { abs(Int(a[pixel*4+$0])-Int(b[pixel*4+$0])) }
            maximum = max(maximum, differences.max()!)
            if differences.max()! <= 2 { continue }
            let x = pixel % expected.width, y = pixel / expected.width
            var low = [Int](repeating: 255, count: 4), high = [Int](repeating: 0, count: 4)
            for row in max(0,y-1)...min(expected.height-1,y+1) {
                for column in max(0,x-1)...min(expected.width-1,x+1) {
                    for channel in 0..<4 {
                        let value = Int(a[(row*expected.width+column)*4+channel])
                        low[channel] = min(low[channel],value); high[channel] = max(high[channel],value)
                    }
                }
            }
            // Analytic edges and SpriteKit's quad rasterizer can disagree at
            // a silhouette pixel. Allow only a one-pixel existing alpha edge,
            // bounded by its neighborhood. Flat interiors (shared seams) remain
            // strict: neither a hole nor doubled alpha can pass this condition.
            let edge = high[3]-low[3] > 2 && (0..<4).allSatisfy {
                Int(b[pixel*4+$0]) >= low[$0]-2 && Int(b[pixel*4+$0]) <= high[$0]+2
            }
            if edge { edgePixels += 1 } else { bad += 1 }
        }
        compared += 1
        if bad > 0 {
            try save(expected, to: output.appendingPathComponent("\(name)-expected.png"))
            try save(actual, to: output.appendingPathComponent("\(name)-actual.png"))
            throw PrototypeError("\(name): \(bad) channels differ; maximum \(maximum)")
        }
    }
    for frame in 0..<48 {
        let phase = Float(frame)*0.37
        let center = SIMD2<Float>(64 + sin(phase)*63.875, 64 + cos(phase*1.3)*63.875)
        for mesh in [baseline, optimized] { try mesh.updatePositions(square + [center]) }
        // Rotate, mirror, minify and translate both the reference and the meshes.
        for node in [reference as SKNode, baseline, optimized] {
            node.position = CGPoint(x: 45.37, y: 35.19)
            node.zRotation = CGFloat(sin(phase)*0.4)
            let scale: CGFloat = frame.isMultiple(of: 3) ? 0.37 : 1.1
            node.xScale = frame.isMultiple(of: 2) ? scale : -scale
            node.yScale = scale
            node.alpha = 0.5
        }
        let expected = try render(reference)
        try compare(expected, render(baseline), name: "fan-\(frame)-baseline")
        try compare(expected, render(optimized), name: "fan-\(frame)-tight")
    }
    for skin in ["goblin", "goblingirl"] {
        let old = try Goblin(skin: skin, boundsMode: .mesh)
        let new = try Goblin(skin: skin, boundsMode: .triangle)
        for node in [old, new] { node.position = CGPoint(x: 100.37, y: -10.19); node.setScale(0.65); node.alpha = 0.5 }
        for frame in 0..<16 {
            let time = Float(frame)/16
            try old.sample(time: time); try new.sample(time: time)
            try compare(render(old), render(new), name: "\(skin)-\(frame)-bounds")
        }
    }
    let result = "Moving bounds: \(compared) image comparisons, 0 interior mismatches (>2/255), \(edgePixels) one-pixel alpha-edge differences; raw maximum \(maximum)/255."
    print(result)
    return [result]
}

/// A shared material must not leak projection/UV state between overlapping meshes.
func verifySharedMaterial(view: SKView) throws -> String {
    let texture = checkerTexture()
    let shared = TriangleMeshNode.Material(texture: texture)
    let roots = [SKNode(), SKNode()]
    var groups: [[TriangleMeshNode]] = []
    for (group, root) in roots.enumerated() {
        var meshes: [TriangleMeshNode] = []
        for index in 0..<3 {
            let material = group == 0 ? TriangleMeshNode.Material(texture: texture) : shared
            let node = try TriangleMeshNode(material: material, positions: square, uvs: squareUV, indices: [0,1,2, 0,2,3])
            node.position = CGPoint(x: 40+index*31, y: 45+index*17)
            node.zPosition = CGFloat(index)
            node.alpha = 0.6
            root.addChild(node); meshes.append(node)
        }
        groups.append(meshes)
    }
    var maximum = 0
    for frame in 0..<16 {
        for meshes in groups {
            for (index, node) in meshes.enumerated() {
                var positions = square
                positions[2].x += Float(frame*3)
                // Fold the quad, reversing one triangle; updates cached UV order.
                if frame.isMultiple(of: 3) { positions[2].y = -24 }
                try node.updatePositions(positions)
                node.zRotation = CGFloat(frame+index)*0.03
                node.xScale = index == 1 ? -0.8 : 0.9
                node.yScale = 0.7+CGFloat(index)*0.1
            }
        }
        let crop = CGRect(x: -100, y: -40, width: 420, height: 320)
        let expected = try bitmap(capture(view: view, node: roots[0], crop: crop))
        let actual = try bitmap(capture(view: view, node: roots[1], crop: crop))
        guard expected.count == actual.count else { throw PrototypeError("Shared-material image sizes differ") }
        for index in expected.indices {
            maximum = max(maximum, abs(Int(expected[index])-Int(actual[index])))
        }
        guard maximum <= 2 else { throw PrototypeError("Shared material changed pixels by \(maximum)/255") }
    }
    let result = "Shared material: 16 overlapping/folded mesh comparisons passed; maximum difference \(maximum)/255."
    print(result)
    return result
}
