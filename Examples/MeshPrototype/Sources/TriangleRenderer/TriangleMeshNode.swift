import SpriteKit

public enum MeshError: Error, Equatable {
    case invalidGeometry
}

/// Experimental analytical triangle rasterizer. UVs address a complete texture,
/// with (0, 0) at the bottom left. No implicit SKTextureAtlas/subtexture mapping.
/// All triangle quads share the mesh bounds to keep shared-edge calculations
/// identical. This favors correctness over fill rate: overdraw is O(triangles).
public final class TriangleMeshNode: SKNode {
    public let indices: [Int]
    public let uvs: [SIMD2<Float>]
    public private(set) var positions: [SIMD2<Float>]
    public var triangleCount: Int { indices.count / 3 }

    private let sprites: [SKSpriteNode]
    private let values: [[SKAttributeValue]]
    private static let attributeNames = ["a_e0", "a_e1", "a_e2", "a_uv0", "a_uv1", "a_uv2", "a_inverseArea"]
    private static let white = SKTexture(data: Data([255, 255, 255, 255]), size: CGSize(width: 1, height: 1))

    public init(texture: SKTexture, positions: [SIMD2<Float>], uvs: [SIMD2<Float>], indices: [Int]) throws {
        guard positions.count >= 3, uvs.count == positions.count, !indices.isEmpty,
              indices.count.isMultiple(of: 3), indices.allSatisfy({ positions.indices.contains($0) }),
              positions.allSatisfy(Self.finite), uvs.allSatisfy(Self.finite) else { throw MeshError.invalidGeometry }
        self.positions = positions
        self.uvs = uvs
        self.indices = indices
        // SpriteKit's sampler for a texture uniform is linear on the tested
        // backend even when filteringMode is nearest. Snap UVs explicitly.
        let imageSize = texture.filteringMode == .nearest ? texture.cgImage() : nil
        let shader = SKShader(source: Self.source, uniforms: [
            SKUniform(name: "u_image", texture: texture),
            SKUniform(name: "u_pixelSize", vectorFloat2: SIMD2(Float(imageSize?.width ?? 1), Float(imageSize?.height ?? 1))),
            SKUniform(name: "u_nearest", float: texture.filteringMode == .nearest ? 1 : 0)
        ])
        shader.attributes = Self.attributeNames.enumerated().map { index, name in
            SKAttribute(name: name, type: index < 3 ? .vectorFloat4 : index < 6 ? .vectorFloat2 : .float)
        }
        sprites = stride(from: 0, to: indices.count, by: 3).map { _ in
            let sprite = SKSpriteNode(texture: Self.white)
            sprite.anchorPoint = .zero
            sprite.shader = shader
            return sprite
        }
        values = sprites.map { _ in Self.attributeNames.map { _ in SKAttributeValue() } }
        super.init()
        for (index, sprite) in sprites.enumerated() {
            // Preserve triangle order even with ignoresSiblingOrder enabled.
            sprite.zPosition = CGFloat(index) * 0.000001
            addChild(sprite)
        }
        try updatePositions(positions)
    }

    required init?(coder: NSCoder) { fatalError("Use init(texture:positions:uvs:indices:)") }

    public func updatePositions(_ positions: [SIMD2<Float>]) throws {
        guard positions.count == uvs.count, positions.allSatisfy(Self.finite) else { throw MeshError.invalidGeometry }
        self.positions = positions
        var minimum = positions[0], maximum = positions[0]
        for p in positions {
            minimum = SIMD2(min(minimum.x, p.x), min(minimum.y, p.y))
            maximum = SIMD2(max(maximum.x, p.x), max(maximum.y, p.y))
        }
        let extent = maximum - minimum
        guard extent.x > 0, extent.y > 0 else {
            sprites.forEach { $0.isHidden = true }
            return
        }
        let normalized = positions.map { ($0 - minimum) / extent }
        for (triangle, sprite) in sprites.enumerated() {
            var ids = Array(indices[(triangle * 3)..<(triangle * 3 + 3)])
            var area = Self.cross(normalized[ids[1]] - normalized[ids[0]], normalized[ids[2]] - normalized[ids[0]])
            if area < 0 { ids.swapAt(1, 2); area = -area }
            sprite.isHidden = area <= 1e-12
            if sprite.isHidden { continue }
            sprite.position = CGPoint(x: CGFloat(minimum.x), y: CGFloat(minimum.y))
            sprite.size = CGSize(width: CGFloat(extent.x), height: CGFloat(extent.y))
            let edges = [(ids[1], ids[2]), (ids[2], ids[0]), (ids[0], ids[1])]
            for (i, pair) in edges.enumerated() {
                // Canonical endpoint ordering gives a shared edge identical
                // coefficients (up to sign) in both adjacent triangles.
                let low = normalized[min(pair.0, pair.1)], high = normalized[max(pair.0, pair.1)]
                let sign: Float = pair.0 < pair.1 ? 1 : -1
                let delta = (high - low) * sign
                let coefficients = SIMD3(low.y - high.y, high.x - low.x,
                                         low.x * high.y - high.x * low.y) * sign
                let inclusive: Float = delta.y > 0 || (delta.y == 0 && delta.x < 0) ? 1 : 0
                values[triangle][i].vectorFloat4Value = SIMD4(coefficients.x, coefficients.y, coefficients.z, inclusive)
                values[triangle][i + 3].vectorFloat2Value = uvs[ids[i]]
            }
            values[triangle][6].floatValue = 1 / area
            for (name, value) in zip(Self.attributeNames, values[triangle]) { sprite.setValue(value, forAttribute: name) }
        }
    }

    private static func finite(_ p: SIMD2<Float>) -> Bool { p.x.isFinite && p.y.isFinite }
    private static func cross(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float { a.x * b.y - a.y * b.x }

    private static let source = """
    bool covered(float distance, float inclusive) {
        return distance > 0.0 || (distance == 0.0 && inclusive > 0.5);
    }
    void main() {
        vec3 p = vec3(v_tex_coord, 1.0);
        float e0 = dot(a_e0.xyz, p);
        float e1 = dot(a_e1.xyz, p);
        float e2 = dot(a_e2.xyz, p);
        if (!covered(e0, a_e0.w) || !covered(e1, a_e1.w) || !covered(e2, a_e2.w)) discard;
        vec2 uv = (a_uv0 * e0 + a_uv1 * e1 + a_uv2 * e2) * a_inverseArea;
        if (u_nearest > 0.5) uv = (floor(uv * u_pixelSize) + vec2(0.5)) / u_pixelSize;
        gl_FragColor = texture2D(u_image, uv) * v_color_mix.a;
    }
    """
}
