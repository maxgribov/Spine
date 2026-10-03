import SpriteKit
import TriangleRenderer

/// Compare grouped source-over against separately blended triangle nodes.
func verifyTriangleGroups(view: SKView, output: URL) throws -> String {
    let texture = checkerTexture()
    let fan = [0,1,4, 1,2,4, 2,3,4, 3,0,4]
    let positions = square + [SIMD2<Float>(64,64)]
    let uvs = squareUV + [SIMD2<Float>(0.5,0.5)]
    var comparisons = 0, maximum = 0
    func compare(_ reference: CGImage, _ candidate: CGImage, name: String) throws {
        guard reference.width == candidate.width, reference.height == candidate.height else { throw PrototypeError("Group capture sizes differ") }
        let a = try bitmap(reference), b = try bitmap(candidate)
        var bad = 0, localMaximum = 0
        for index in a.indices {
            let delta = abs(Int(a[index])-Int(b[index]))
            localMaximum = max(localMaximum,delta)
            if delta > 2 { bad += 1 }
        }
        maximum = max(maximum,localMaximum); comparisons += 1
        if bad > 0 {
            try save(reference, to: output.appendingPathComponent("\(name)-reference.png"))
            try save(candidate, to: output.appendingPathComponent("\(name)-candidate.png"))
            throw PrototypeError("Grouped rendering \(name): \(bad) channels >2/255, max \(localMaximum)")
        }
    }
    for mode in TriangleMeshNode.BoundsMode.allCases {
        for groupSize in [TriangleMeshNode.GroupSize.two, .four] {
            // Five triangles exercises a partial final group. Duplicate coverage
            // with a different UV tests ordered color blending, not just alpha.
            let vertices = positions + [SIMD2(12,8),SIMD2(115,12),SIMD2(12,115)]
            let uv = uvs + [SIMD2(0.8,0.2),SIMD2(0.95,0.2),SIMD2(0.8,0.4)]
            let indices = fan + [5,6,7]
            let reference = try TriangleMeshNode(texture: texture, positions: vertices, uvs: uv, indices: indices, boundsMode: mode, groupSize: .one)
            let candidate = try TriangleMeshNode(texture: texture, positions: vertices, uvs: uv, indices: indices, boundsMode: mode, groupSize: groupSize)
            let roots = [SKNode(),SKNode()]
            for (root, node) in zip(roots, [reference,candidate]) {
                root.alpha = 0.7
                root.addChild(node)
                node.alpha = 0.6
                node.position = CGPoint(x: 150.37,y: 100.19)
            }
            for frame in 0..<24 {
                var pose = vertices
                let phase = Float(frame)*0.43
                pose[4] = SIMD2(64+sin(phase)*140,64+cos(phase*1.3)*140)
                // Disable then recover geometry inside a partially active group.
                if frame == 9 { pose[4] = pose[0] }
                if frame == 10 { pose = pose.map { SIMD2($0.x,0) } }
                for node in [reference,candidate] {
                    try node.updatePositions(pose)
                    node.zRotation = CGFloat(sin(phase)*0.3)
                    node.xScale = frame.isMultiple(of: 2) ? 0.75 : -0.75
                    node.yScale = 0.8
                }
                let crop = CGRect(x: -80,y: -80,width: 420,height: 420)
                try compare(capture(view: view, node: roots[0], crop: crop), capture(view: view, node: roots[1], crop: crop),
                            name: "groups-\(groupSize.rawValue)-\(mode.rawValue)-\(frame)")
            }
        }
    }
    for skin in ["goblin","goblingirl"] {
        let reference = try Goblin(skin: skin, groupSize: .one)
        for groupSize in [TriangleMeshNode.GroupSize.two, .four] {
            let candidate = try Goblin(skin: skin, groupSize: groupSize)
            for node in [reference,candidate] { node.position = CGPoint(x: 150.37,y: 10.19); node.setScale(0.65); node.alpha = 0.5 }
            for frame in 0..<16 {
                let time = Float(frame)/16
                try reference.sample(time: time); try candidate.sample(time: time)
                let crop = CGRect(x: 0,y: 0,width: 320,height: 320)
                try compare(capture(view: view, node: reference, crop: crop), capture(view: view, node: candidate, crop: crop),
                            name: "groups-\(groupSize.rawValue)-\(skin)-\(frame)")
            }
        }
    }
    let result = "Triangle groups: \(comparisons) comparisons passed, max channel difference \(maximum)/255."
    print(result)
    return result
}
