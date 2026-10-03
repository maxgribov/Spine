import SpriteKit

public enum MeshError: Error, Equatable {
    case invalidGeometry
}

/// Experimental analytical triangle rasterizer. UVs address a complete texture,
/// with (0, 0) at the bottom left. No implicit SKTextureAtlas/subtexture mapping.
/// Triangle bounds reduce fragment work; mesh bounds remain as an A/B baseline.
public final class TriangleMeshNode: SKNode {
    public enum BoundsMode: String, CaseIterable { case mesh, triangle }
    public let boundsMode: BoundsMode
    public let indices: [Int]
    public let uvs: [SIMD2<Float>]
    public private(set) var positions: [SIMD2<Float>]
    public var triangleCount: Int { indices.count / 3 }
    /// Geometric area in mesh units, not a hardware fragment counter.
    public private(set) var submittedQuadArea: Double = 0
    public private(set) var coveredTriangleArea: Double = 0

    private let sprites: [SKSpriteNode]
    private let values: [[SKAttributeValue]]
    private let attributeNames: [String]
    private var rasterX = SIMD3<Float>(1,0,0)
    private var rasterY = SIMD3<Float>(0,1,0)
    private var lastWinding: [Bool?]
    private var normalized: [SIMD2<Float>]
    private var localToPixels: CGAffineTransform?
    private var meshMinimum = SIMD2<Float>.zero
    private var meshExtent = SIMD2<Float>(repeating: 1)
    private var projectionWasSingular = false
    private var rasterAttributesInitialized = false
    private static let white = SKTexture(data: Data([255, 255, 255, 255]), size: CGSize(width: 1, height: 1))

    /// Share a material between meshes using the same atlas page and bounds mode.
    /// It contains only immutable texture uniforms; transforms are per-node attributes.
    public final class Material {
        public let boundsMode: BoundsMode
        fileprivate let shader: SKShader
        fileprivate static let names = ["a_e0", "a_e1", "a_e2", "a_uv0", "a_uv1", "a_uv2", "a_inverseArea", "a_rasterX", "a_rasterY"]
        public init(texture: SKTexture, boundsMode: BoundsMode = .triangle) {
            self.boundsMode = boundsMode
            // Uniform samplers use linear filtering on the tested backend;
            // nearest sampling explicitly snaps to texel centers.
            let imageSize = texture.filteringMode == .nearest ? texture.cgImage() : nil
            let source = TriangleMeshNode.source.replacingOccurrences(of: "MESH_POSITION", with:
                boundsMode == .mesh ? "v_tex_coord" : "vec2(dot(a_rasterX, vec3(gl_FragCoord.xy, 1.0)), dot(a_rasterY, vec3(gl_FragCoord.xy, 1.0)))")
            shader = SKShader(source: source, uniforms: [
                SKUniform(name: "u_image", texture: texture),
                SKUniform(name: "u_pixelSize", vectorFloat2: SIMD2(Float(imageSize?.width ?? 1), Float(imageSize?.height ?? 1))),
                SKUniform(name: "u_nearest", float: texture.filteringMode == .nearest ? 1 : 0)
            ])
            shader.attributes = Self.names.prefix(boundsMode == .triangle ? 9 : 7).enumerated().map { index, name in
                SKAttribute(name: name, type: index < 3 ? .vectorFloat4 : index < 6 ? .vectorFloat2 : index == 6 ? .float : .vectorFloat3)
            }
        }
    }

    public convenience init(texture: SKTexture, positions: [SIMD2<Float>], uvs: [SIMD2<Float>], indices: [Int],
                            boundsMode: BoundsMode = .triangle) throws {
        try self.init(material: Material(texture: texture, boundsMode: boundsMode), positions: positions, uvs: uvs, indices: indices)
    }

    public init(material: Material, positions: [SIMD2<Float>], uvs: [SIMD2<Float>], indices: [Int]) throws {
        guard positions.count >= 3, uvs.count == positions.count, !indices.isEmpty,
              indices.count.isMultiple(of: 3), indices.allSatisfy({ positions.indices.contains($0) }),
              positions.allSatisfy(Self.finite), uvs.allSatisfy(Self.finite) else { throw MeshError.invalidGeometry }
        self.positions = positions
        self.uvs = uvs
        self.indices = indices
        self.boundsMode = material.boundsMode
        normalized = positions
        lastWinding = [Bool?](repeating: nil, count: indices.count/3)
        let attributeNames = Array(Material.names.prefix(material.boundsMode == .triangle ? 9 : 7))
        self.attributeNames = attributeNames
        let shader = material.shader
        sprites = stride(from: 0, to: indices.count, by: 3).map { _ in
            let sprite = SKSpriteNode(texture: Self.white)
            sprite.anchorPoint = .zero
            sprite.shader = shader
            return sprite
        }
        values = sprites.map { _ in attributeNames.map { _ in SKAttributeValue() } }
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
        meshMinimum = minimum; meshExtent = extent
        submittedQuadArea = 0
        coveredTriangleArea = 0
        guard extent.x > 0, extent.y > 0 else {
            sprites.forEach { $0.isHidden = true }
            return
        }
        updateRasterAttributes(minimum: minimum, extent: extent)
        for index in positions.indices { normalized[index] = (positions[index] - minimum) / extent }
        let inverse = localToPixels?.inverted() ?? .identity
        let padding = SIMD2<Float>(Float(abs(inverse.a)+abs(inverse.c)), Float(abs(inverse.b)+abs(inverse.d)))
        for (triangle, sprite) in sprites.enumerated() {
            let i0 = indices[triangle*3]
            var i1 = indices[triangle*3+1], i2 = indices[triangle*3+2]
            var area = Self.cross(normalized[i1] - normalized[i0], normalized[i2] - normalized[i0])
            let reversed = area < 0
            if reversed { swap(&i1, &i2); area = -area }
            sprite.isHidden = area <= 1e-12
            if sprite.isHidden { continue }
            var quadMin = minimum, quadMax = maximum
            if boundsMode == .triangle {
                let p0 = positions[i0], p1 = positions[i1], p2 = positions[i2]
                quadMin = SIMD2(min(p0.x, min(p1.x, p2.x)), min(p0.y, min(p1.y, p2.y)))
                quadMax = SIMD2(max(p0.x, max(p1.x, p2.x)), max(p0.y, max(p1.y, p2.y)))
                // Pad in local units to keep SpriteKit quad rasterization from
                // clipping a pixel on an inclusive analytic triangle boundary.
                quadMin -= padding
                quadMax += padding
            }
            let quadSize = quadMax - quadMin
            sprite.position = CGPoint(x: CGFloat(quadMin.x), y: CGFloat(quadMin.y))
            sprite.size = CGSize(width: CGFloat(quadSize.x), height: CGFloat(quadSize.y))
            submittedQuadArea += Double(quadSize.x) * Double(quadSize.y)
            coveredTriangleArea += Double(area) * Double(extent.x) * Double(extent.y) / 2
            func edge(_ a: Int, _ b: Int, _ index: Int) {
                // Compute identical shared-edge coefficients, up to sign.
                let low = normalized[min(a,b)], high = normalized[max(a,b)]
                let sign: Float = a < b ? 1 : -1
                let delta = (high-low)*sign
                let c = SIMD3(low.y-high.y, high.x-low.x, low.x*high.y-high.x*low.y)*sign
                let inclusive: Float = delta.y > 0 || (delta.y == 0 && delta.x < 0) ? 1 : 0
                values[triangle][index].vectorFloat4Value = SIMD4(c.x,c.y,c.z,inclusive)
                sprite.setValue(values[triangle][index], forAttribute: attributeNames[index])
            }
            edge(i1,i2,0); edge(i2,i0,1); edge(i0,i1,2)
            if lastWinding[triangle] != reversed {
                values[triangle][3].vectorFloat2Value = uvs[i0]
                values[triangle][4].vectorFloat2Value = uvs[i1]
                values[triangle][5].vectorFloat2Value = uvs[i2]
                for index in 3...5 { sprite.setValue(values[triangle][index], forAttribute: attributeNames[index]) }
                lastWinding[triangle] = reversed
            }
            values[triangle][6].floatValue = 1 / area
            sprite.setValue(values[triangle][6], forAttribute: attributeNames[6])
        }
    }

    /// Required for tight bounds after pose/ancestor/camera changes, before
    /// rendering. The transform maps mesh-local coordinates to framebuffer
    /// pixels in the actual target's fragment-coordinate convention. Shared screen coordinates avoid cracks from
    /// separately interpolated per-quad texture coordinates.
    public func prepareForRendering(localToPixels transform: CGAffineTransform) {
        guard boundsMode == .triangle else { return }
        let determinant = transform.a*transform.d-transform.b*transform.c
        guard [transform.a, transform.b, transform.c, transform.d, transform.tx, transform.ty].allSatisfy(\.isFinite),
              determinant.isFinite, abs(determinant) > 1e-12 else {
            sprites.forEach { $0.isHidden = true }
            projectionWasSingular = true
            return
        }
        let paddingChanged = localToPixels?.a != transform.a || localToPixels?.b != transform.b
            || localToPixels?.c != transform.c || localToPixels?.d != transform.d
        localToPixels = transform
        if paddingChanged || projectionWasSingular {
            projectionWasSingular = false
            try? updatePositions(positions)
        } else if meshExtent.x > 0 && meshExtent.y > 0 {
            updateRasterAttributes(minimum: meshMinimum, extent: meshExtent)
        }
    }

    private func updateRasterAttributes(minimum: SIMD2<Float>, extent: SIMD2<Float>) {
        guard let inverse = localToPixels?.inverted(), boundsMode == .triangle else { return }
        let x = SIMD3(Float(inverse.a)/extent.x, Float(inverse.c)/extent.x, (Float(inverse.tx)-minimum.x)/extent.x)
        let y = SIMD3(Float(inverse.b)/extent.y, Float(inverse.d)/extent.y, (Float(inverse.ty)-minimum.y)/extent.y)
        guard x != rasterX || y != rasterY || !rasterAttributesInitialized else { return }
        rasterX = x; rasterY = y; rasterAttributesInitialized = true
        for (index, sprite) in sprites.enumerated() {
            values[index][7].vectorFloat3Value = x
            values[index][8].vectorFloat3Value = y
            sprite.setValue(values[index][7], forAttribute: attributeNames[7])
            sprite.setValue(values[index][8], forAttribute: attributeNames[8])
        }
    }

    private static func finite(_ p: SIMD2<Float>) -> Bool { p.x.isFinite && p.y.isFinite }
    private static func cross(_ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float { a.x * b.y - a.y * b.x }

    private static let source = """
    bool covered(float distance, float inclusive) {
        return distance > 0.0 || (distance == 0.0 && inclusive > 0.5);
    }
    void main() {
        vec3 p = vec3(MESH_POSITION, 1.0);
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
