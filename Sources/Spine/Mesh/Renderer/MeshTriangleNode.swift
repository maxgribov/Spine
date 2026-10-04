import SpriteKit

enum MeshRendererError: Error, Equatable {
    case invalidGeometry
}

/// Internal analytical triangle rasterizer ported from the validated prototype. UVs address a complete texture,
/// with (0, 0) at the bottom left. No implicit SKTextureAtlas/subtexture mapping.
/// Triangle bounds reduce fragment work; mesh bounds remain as an A/B baseline.
final class MeshTriangleNode: SKNode {
    enum BoundsMode: String, CaseIterable { case mesh, triangle }
    enum GroupSize: Int, CaseIterable { case one = 1, two = 2, four = 4 }
    let boundsMode: BoundsMode
    let groupSize: GroupSize
    let indices: [Int]
    let uvs: [SIMD2<Float>]
    private(set) var positions: [SIMD2<Float>]
    var triangleCount: Int { indices.count / 3 }
    /// Geometric area in mesh units, not a hardware fragment counter.
    private(set) var submittedQuadArea: Double = 0
    private(set) var coveredTriangleArea: Double = 0

    private let grouped: MeshTriangleGroups?
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
    private var previousTint:SIMD4<Float>?
    private var validationGeneration:UInt64=0

    /// Share a material between meshes using the same atlas page and bounds mode.
    /// It contains only immutable texture uniforms; transforms are per-node attributes.
    final class Material {
        let boundsMode: BoundsMode
        let groupSize: GroupSize
        fileprivate let shader: SKShader
        fileprivate let white = SKTexture(data: Data([255,255,255,255]), size: CGSize(width:1,height:1))
        fileprivate static let names = ["a_e0", "a_e1", "a_e2", "a_uv0", "a_uv1", "a_uv2", "a_inverseArea", "a_rasterX", "a_rasterY"]
        init(texture: SKTexture, pixelSize: CGSize, boundsMode: BoundsMode = .triangle, groupSize: GroupSize = .two) {
            self.boundsMode = boundsMode
            self.groupSize = groupSize
            // Uniform samplers use linear filtering on the tested backend;
            // nearest sampling explicitly snaps to texel centers.
            let singleSource = MeshTriangleNode.source.replacingOccurrences(of: "MESH_POSITION", with:
                boundsMode == .mesh ? "v_tex_coord" : "vec2(dot(a_rasterX, vec3(gl_FragCoord.xy, 1.0)), dot(a_rasterY, vec3(gl_FragCoord.xy, 1.0)))")
            let source = groupSize == .one ? singleSource : MeshTriangleGroups.source(size: groupSize.rawValue, boundsMode: boundsMode)
            shader = SKShader(source: source, uniforms: [
                SKUniform(name: "u_image", texture: texture),
                SKUniform(name: "u_pixelSize", vectorFloat2: SIMD2(Float(pixelSize.width), Float(pixelSize.height))),
                SKUniform(name: "u_nearest", float: texture.filteringMode == .nearest ? 1 : 0)
            ])
            if groupSize != .one {
                shader.attributes = MeshTriangleGroups.names(size: groupSize.rawValue).enumerated().map { index, name in
                    SKAttribute(name: name, type: index < groupSize.rawValue*5 || index == groupSize.rawValue*5+2 ? .vectorFloat4 : .vectorFloat3)
                }
                return
            }
            shader.attributes = (Array(Self.names.prefix(boundsMode == .triangle ? 9 : 7))+["a_tint"]).enumerated().map { index, name in
                SKAttribute(name: name, type: name == "a_tint" || index < 3 ? .vectorFloat4 : index < 6 ? .vectorFloat2 : index == 6 ? .float : .vectorFloat3)
            }
        }
    }

    convenience init(texture: SKTexture, positions: [SIMD2<Float>], uvs: [SIMD2<Float>], indices: [Int],
                            boundsMode: BoundsMode = .triangle, groupSize: GroupSize = .two) throws {
        try self.init(material: Material(texture: texture, pixelSize: texture.size(), boundsMode: boundsMode, groupSize: groupSize), positions: positions, uvs: uvs, indices: indices)
    }

    init(material: Material, positions: [SIMD2<Float>], uvs: [SIMD2<Float>], indices: [Int]) throws {
        guard uvs.count == positions.count,
              indices.count.isMultiple(of: 3), indices.allSatisfy({ positions.indices.contains($0) }),
              positions.allSatisfy(Self.finite), uvs.allSatisfy(Self.finite) else { throw MeshRendererError.invalidGeometry }
        self.positions = positions
        self.uvs = uvs
        self.indices = indices
        self.boundsMode = material.boundsMode
        self.groupSize = material.groupSize
        normalized = positions
        lastWinding = [Bool?](repeating: nil, count: indices.count/3)
        let attributeNames = Array(Material.names.prefix(material.boundsMode == .triangle ? 9 : 7))+["a_tint"]
        self.attributeNames = attributeNames
        let shader = material.shader
        grouped = material.groupSize == .one ? nil : MeshTriangleGroups(shader: shader, white: material.white, size: material.groupSize.rawValue, indices: indices, uvs: uvs)
        sprites = stride(from: 0, to: material.groupSize == .one ? indices.count : 0, by: 3).map { _ in
            let sprite = SKSpriteNode(texture: material.white)
            sprite.anchorPoint = .zero
            sprite.shader = shader
            return sprite
        }
        values = sprites.map { _ in attributeNames.map { _ in SKAttributeValue() } }
        super.init()
        if let grouped = grouped { addChild(grouped) }
        for (index, sprite) in sprites.enumerated() {
            // Preserve triangle order even with ignoresSiblingOrder enabled.
            sprite.zPosition = CGFloat(index) * 0.000001
            addChild(sprite)
        }
        setTint(SIMD4<Float>(repeating:1))
        try updatePositions(positions)
    }

    required init?(coder: NSCoder) { fatalError("Use init(texture:positions:uvs:indices:)") }

    /// Reserve a bounded local z interval for this mesh inside a scene layer.
    /// Must be positive and finite. Triangle order is preserved within [0, span).
    func setTriangleDepthSpan(_ span: CGFloat) {
        precondition(span.isFinite && span > 0)
        if let grouped = grouped { grouped.setDepthSpan(span) }
        else {
            for (index, sprite) in sprites.enumerated() {
                sprite.zPosition = span * CGFloat(index) / CGFloat(triangleCount)
            }
        }
    }

    func updatePositions(_ positions: [SIMD2<Float>]) throws {
        validationGeneration &+= 1
        do {try validateDerivedValues(positions, transform:localToPixels)}
        catch {hideGeometry();throw error}
        for i in positions.indices { self.positions[i] = positions[i] }
        rebuildGeometry()
    }

    func setTint(_ tint:SIMD4<Float>) {
        guard previousTint != tint else {return}
        previousTint=tint
        if let grouped=grouped {grouped.setTint(tint)}
        else {
            for (index,sprite) in sprites.enumerated() {
                values[index][attributeNames.count-1].vectorFloat4Value=tint
                sprite.setValue(values[index][attributeNames.count-1],forAttribute:"a_tint")
            }
        }
    }

    private func rebuildGeometry() {
        guard !positions.isEmpty else {return}
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
            grouped?.hideGeometry()
            return
        }
        updateRasterAttributes(minimum: minimum, extent: extent,deferGroupedCommit:true)
        for index in positions.indices { normalized[index] = (positions[index] - minimum) / extent }
        let inverse = localToPixels?.inverted() ?? .identity
        let padding = SIMD2<Float>(Float(abs(inverse.a)+abs(inverse.c)), Float(abs(inverse.b)+abs(inverse.d)))
        if let grouped = grouped {
            let area = grouped.update(positions: positions, normalized: normalized, minimum: minimum, maximum: maximum,
                                      padding: padding, boundsMode: boundsMode)
            submittedQuadArea = area.quad; coveredTriangleArea = area.triangle
            return
        }
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

    struct ValidatedGeometry {
        fileprivate let owner:MeshTriangleNode,transform:CGAffineTransform,positions:[SIMD2<Float>],singular:Bool
        fileprivate let generation:UInt64
    }
    /// Pure preflight used by the renderer before committing any attachment.
    func validateForRendering(localToPixels transform:CGAffineTransform,positions:[SIMD2<Float>])throws->ValidatedGeometry {
        let determinant=transform.a*transform.d-transform.b*transform.c
        guard [transform.a,transform.b,transform.c,transform.d,transform.tx,transform.ty,determinant].allSatisfy(\.isFinite) else {
            throw SpineRuntimeError(.invalidRenderContext,path:"/runtime/frame",message:"Frame projection is not finite.")
        }
        if determinant==0 {
            guard positions.count==uvs.count,positions.allSatisfy(Self.finite) else {throw geometryError("Nonfinite input geometry.")}
        } else {try validateDerivedValues(positions,transform:transform)}
        validationGeneration &+= 1
        return ValidatedGeometry(owner:self,transform:transform,positions:positions,singular:determinant==0,generation:validationGeneration)
    }

    /// Required for tight bounds after pose/ancestor/camera changes, before
    /// rendering. The transform maps mesh-local coordinates to framebuffer
    /// pixels in the actual target's fragment-coordinate convention. Shared screen coordinates avoid cracks from
    /// separately interpolated per-quad texture coordinates.
    func prepareForRendering(localToPixels transform: CGAffineTransform, positions candidate:[SIMD2<Float>]? = nil) throws {
        let input=candidate ?? positions
        guard boundsMode == .triangle else {try updatePositions(input);return}
        do {
            let validated=try validateForRendering(localToPixels:transform,positions:input)
            commit(validated,geometryChanged:candidate != nil)
        } catch {hideGeometry();throw error}
    }

    /// The token can only be constructed by this node's pure preflight.
    func canCommit(_ validated:ValidatedGeometry)->Bool {validated.owner === self && validated.generation==validationGeneration}
    func commit(_ validated:ValidatedGeometry,geometryChanged:Bool=true) {
        precondition(canCommit(validated))
        validationGeneration &+= 1
        if validated.singular {hideGeometry();return}
        let transform=validated.transform,input=validated.positions
        let paddingChanged=localToPixels?.a != transform.a || localToPixels?.b != transform.b
            || localToPixels?.c != transform.c || localToPixels?.d != transform.d
        localToPixels=transform
        if geometryChanged {for i in input.indices {positions[i]=input[i]}}
        if geometryChanged || paddingChanged || projectionWasSingular {
            projectionWasSingular=false
            rebuildGeometry()
        } else if meshExtent.x>0,meshExtent.y>0 {updateRasterAttributes(minimum:meshMinimum,extent:meshExtent)}
    }

    private func hideGeometry() {
        validationGeneration &+= 1
        sprites.forEach {$0.isHidden=true};grouped?.hideGeometry();projectionWasSingular=true
    }
    private func geometryError(_ message:String)->SpineRuntimeError {
        SpineRuntimeError(.invalidGeometry,path:"/runtime/geometry",message:message)
    }
    private func validateDerivedValues(_ candidate:[SIMD2<Float>],transform:CGAffineTransform?)throws {
        guard candidate.count==uvs.count,candidate.allSatisfy(Self.finite) else {throw geometryError("Nonfinite or mismatched geometry.")}
        let inverse=transform?.inverted() ?? .identity
        let inverseValues=[inverse.a,inverse.b,inverse.c,inverse.d,inverse.tx,inverse.ty]
        let padding=SIMD2(Float(abs(inverse.a)+abs(inverse.c)),Float(abs(inverse.b)+abs(inverse.d)))
        guard inverseValues.allSatisfy({$0.isFinite && Float($0).isFinite}),Self.finite(padding) else {
            throw SpineRuntimeError(.invalidRenderContext,path:"/runtime/frame",message:"Frame inverse/padding cannot be represented by shader Floats.")
        }
        guard let first=candidate.first else {return}
        var minimum=first,maximum=first
        for p in candidate {
            minimum=SIMD2(min(minimum.x,p.x),min(minimum.y,p.y));maximum=SIMD2(max(maximum.x,p.x),max(maximum.y,p.y))
        }
        let extent=maximum-minimum
        guard Self.finite(extent) else {throw geometryError("Mesh extent cannot be represented by shader Floats.")}
        guard extent.x>0,extent.y>0 else {return}
        for p in candidate where !Self.finite((p-minimum)/extent) {throw geometryError("Normalized geometry is not finite.")}
        // Check the enclosing padded bound: every individual triangle/group bound is contained in it.
        let low=boundsMode == .triangle ? minimum-padding:minimum
        let high=boundsMode == .triangle ? maximum+padding:maximum
        guard Self.finite(low),Self.finite(high),Self.finite(high-low) else {
            throw SpineRuntimeError(.invalidRenderContext,path:"/runtime/frame",message:"Padded sprite bounds cannot be represented by shader Floats.")
        }
        if boundsMode == .triangle,transform != nil {
            let (x,y)=projection(inverse:inverse,minimum:minimum,extent:extent)
            guard [x.x,x.y,x.z,y.x,y.y,y.z].allSatisfy(\.isFinite) else {throw geometryError("Raster coefficients cannot be represented by shader Floats.")}
        }
    }
    private func projection(inverse:CGAffineTransform,minimum:SIMD2<Float>,extent:SIMD2<Float>)->(SIMD3<Float>,SIMD3<Float>) {
        let x=SIMD3(Float(inverse.a/CGFloat(extent.x)),Float(inverse.c/CGFloat(extent.x)),Float((inverse.tx-CGFloat(minimum.x))/CGFloat(extent.x)))
        let y=SIMD3(Float(inverse.b/CGFloat(extent.y)),Float(inverse.d/CGFloat(extent.y)),Float((inverse.ty-CGFloat(minimum.y))/CGFloat(extent.y)))
        return (x,y)
    }

    private func updateRasterAttributes(minimum: SIMD2<Float>, extent: SIMD2<Float>,deferGroupedCommit:Bool=false) {
        guard let inverse = localToPixels?.inverted(), boundsMode == .triangle else { return }
        let (x,y)=projection(inverse:inverse,minimum:minimum,extent:extent)
        guard x != rasterX || y != rasterY || !rasterAttributesInitialized else { return }
        rasterX = x; rasterY = y; rasterAttributesInitialized = true
        grouped?.setProjection(x: x, y: y,deferCommit:deferGroupedCommit)
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
        gl_FragColor = texture2D(u_image, uv) * vec4(a_tint.rgb * a_tint.a, a_tint.a) * v_color_mix.a;
    }
    """
}
