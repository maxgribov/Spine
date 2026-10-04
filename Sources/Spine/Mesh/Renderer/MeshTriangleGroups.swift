import SpriteKit

/// Consecutive triangles only: never reorder across a group or attachment.
/// Each group rasterizes one AABB and composites its triangles in index order.
final class MeshTriangleGroups: SKNode {
    let groupSize: Int
    let indices: [Int]
    let uvs: [SIMD2<Float>]
    let sprites: [SKSpriteNode]
    private let names: [String]
    private let values: [[SKAttributeValue]]
    private let attributeMaps:[[String:SKAttributeValue]]
    private var lastWinding: [Bool?]
    private var previousProjection:(SIMD3<Float>,SIMD3<Float>)?

    static func names(size: Int) -> [String] {
        (0..<size).flatMap { i in (0..<5).map { "a_t\(i)_\($0)" } } + ["a_rasterX", "a_rasterY", "a_tint"]
    }
    static func source(size: Int, boundsMode: MeshTriangleNode.BoundsMode) -> String {
        let position = boundsMode == .mesh ? "v_tex_coord" : "vec2(dot(a_rasterX, vec3(gl_FragCoord.xy, 1.0)), dot(a_rasterY, vec3(gl_FragCoord.xy, 1.0)))"
        let triangles = (0..<size).map { i in
            """
            {
                float e0 = dot(a_t\(i)_0.xyz, p);
                float e1 = dot(a_t\(i)_1.xyz, p);
                float e2 = dot(a_t\(i)_2.xyz, p);
                if (a_t\(i)_4.z > 0.0 && covered(e0, a_t\(i)_0.w) && covered(e1, a_t\(i)_1.w) && covered(e2, a_t\(i)_2.w)) {
                    vec2 uv = (a_t\(i)_3.xy * e0 + a_t\(i)_3.zw * e1 + a_t\(i)_4.xy * e2) * a_t\(i)_4.z;
                    if (u_nearest > 0.5) uv = (floor(uv * u_pixelSize) + vec2(0.5)) / u_pixelSize;
                    // Apply inherited alpha to EACH triangle before source-over.
                    vec4 sampleColor = texture2D(u_image, uv) * vec4(a_tint.rgb * a_tint.a, a_tint.a) * v_color_mix.a;
                    result = sampleColor + result * (1.0 - sampleColor.a);
                }
            }
            """
        }.joined(separator: "\n")
        return """
        bool covered(float distance, float inclusive) {
            return distance > 0.0 || (distance == 0.0 && inclusive > 0.5);
        }
        void main() {
            vec3 p = vec3(\(position), 1.0);
            vec4 result = vec4(0.0);
            \(triangles)
            if (result.a == 0.0) discard;
            gl_FragColor = result;
        }
        """
    }

    init(shader: SKShader, white: SKTexture, size: Int, indices: [Int], uvs: [SIMD2<Float>]) {
        groupSize = size; self.indices = indices; self.uvs = uvs
        let attributeNames=Self.names(size:size)
        names = attributeNames
        sprites = stride(from: 0, to: indices.count/3, by: size).map { _ in
            let sprite = SKSpriteNode(texture: white)
            sprite.anchorPoint = .zero; sprite.shader = shader
            return sprite
        }
        let rows=sprites.map { _ in attributeNames.indices.map {index in
            (index==size*5 || index==size*5+1) ? SKAttributeValue(vectorFloat3:.zero):SKAttributeValue(vectorFloat4:.zero)
        }}
        values=rows
        attributeMaps=rows.map {Dictionary(uniqueKeysWithValues:zip(attributeNames,$0))}
        lastWinding = [Bool?](repeating: nil, count: indices.count/3)
        super.init()
        for (index, sprite) in sprites.enumerated() {
            sprite.zPosition = CGFloat(index*size)*0.000001
            addChild(sprite)
            // Unused slots in the last group remain explicitly disabled.
            for slot in 0..<size { set(SIMD4<Float>.zero, group: index, attribute: slot*5+4) }
            sprite.attributeValues=attributeMaps[index]
        }
    }
    required init?(coder: NSCoder) { fatalError("Use designated initializer") }

    func setDepthSpan(_ span: CGFloat) {
        for (index, sprite) in sprites.enumerated() {
            sprite.zPosition = span * CGFloat(index*groupSize) / CGFloat(indices.count/3)
        }
    }

    func hideGeometry() { sprites.forEach { $0.isHidden = true } }

    func setProjection(x: SIMD3<Float>, y: SIMD3<Float>,deferCommit:Bool=false) {
        if let previous=previousProjection,previous.0==x,previous.1==y {return}
        previousProjection=(x,y)
        for (group, sprite) in sprites.enumerated() {
            for (offset, vector) in [x,y].enumerated() {
                let index = groupSize*5+offset
                values[group][index].vectorFloat3Value = vector

            }
            if !deferCommit {sprite.attributeValues=attributeMaps[group]}
        }
    }
    func setTint(_ tint:SIMD4<Float>) {
        for group in sprites.indices {set(tint,group:group,attribute:groupSize*5+2);sprites[group].attributeValues=attributeMaps[group]}
    }
    private func set(_ value: SIMD4<Float>, group: Int, attribute: Int) {
        values[group][attribute].vectorFloat4Value = value

    }

    func update(positions: [SIMD2<Float>], normalized: [SIMD2<Float>], minimum: SIMD2<Float>, maximum: SIMD2<Float>,
                padding: SIMD2<Float>, boundsMode: MeshTriangleNode.BoundsMode) -> (quad: Double, triangle: Double) {
        let extent = maximum-minimum
        var quads = 0.0, triangles = 0.0
        for (group, sprite) in sprites.enumerated() {
            var low = SIMD2<Float>(repeating: .infinity), high = SIMD2<Float>(repeating: -.infinity)
            var visible = false
            for slot in 0..<groupSize {
                let triangle = group*groupSize+slot
                guard triangle < indices.count/3 else { break }
                let i0 = indices[triangle*3]
                var i1 = indices[triangle*3+1], i2 = indices[triangle*3+2]
                let a = normalized[i1]-normalized[i0], b = normalized[i2]-normalized[i0]
                var area = a.x*b.y-a.y*b.x
                let reversed = area < 0
                if reversed { swap(&i1,&i2); area = -area }
                guard area > 1e-12 else {
                    set(.zero, group: group, attribute: slot*5+4)
                    continue
                }
                visible = true
                for id in [i0,i1,i2] {
                    let p = positions[id]
                    low = SIMD2(min(low.x,p.x),min(low.y,p.y))
                    high = SIMD2(max(high.x,p.x),max(high.y,p.y))
                }
                triangles += Double(area)*Double(extent.x)*Double(extent.y)/2
                func edge(_ a: Int, _ b: Int, _ index: Int) {
                    let low = normalized[min(a,b)], high = normalized[max(a,b)]
                    let sign: Float = a < b ? 1 : -1
                    let delta = (high-low)*sign
                    let c = SIMD3(low.y-high.y, high.x-low.x, low.x*high.y-high.x*low.y)*sign
                    let inclusive: Float = delta.y > 0 || (delta.y == 0 && delta.x < 0) ? 1 : 0
                    set(SIMD4(c.x,c.y,c.z,inclusive), group: group, attribute: slot*5+index)
                }
                edge(i1,i2,0); edge(i2,i0,1); edge(i0,i1,2)
                if lastWinding[triangle] != reversed {
                    set(SIMD4(uvs[i0].x,uvs[i0].y,uvs[i1].x,uvs[i1].y), group: group, attribute: slot*5+3)
                    lastWinding[triangle] = reversed
                }
                set(SIMD4(uvs[i2].x,uvs[i2].y,1/area,0), group: group, attribute: slot*5+4)
            }
            sprite.attributeValues=attributeMaps[group]
            sprite.isHidden = !visible
            guard visible else { continue }
            if boundsMode == .mesh { low = minimum; high = maximum }
            else { low -= padding; high += padding }
            let size = high-low
            sprite.position = CGPoint(x: CGFloat(low.x),y: CGFloat(low.y))
            sprite.size = CGSize(width: CGFloat(size.x),height: CGFloat(size.y))
            quads += Double(size.x)*Double(size.y)
        }
        return (quads,triangles)
    }
}
