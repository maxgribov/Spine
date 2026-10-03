import SpriteKit
import TriangleRenderer

// Fixture-specific 4.1 player, deliberately separate from the production runtime.
// It implements only the channels used by the bundled, pinned Goblins example.
typealias Object = [String: Any]
private func number(_ object: Object, _ key: String, _ fallback: Float = 0) -> Float {
    (object[key] as? NSNumber)?.floatValue ?? fallback
}
private func array(_ object: Object, _ key: String) -> [Float] {
    (object[key] as? [NSNumber] ?? []).map { $0.floatValue }
}
struct PrototypeError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}

private struct Transform {
    var a: Float = 1, b: Float = 0, c: Float = 0, d: Float = 1, x: Float = 0, y: Float = 0
    func point(_ p: SIMD2<Float>) -> SIMD2<Float> { SIMD2(a*p.x + b*p.y + x, c*p.x + d*p.y + y) }
    func appending(_ rhs: Transform) -> Transform {
        let p = point(SIMD2(rhs.x, rhs.y))
        return Transform(a: a*rhs.a+b*rhs.c, b: a*rhs.b+b*rhs.d,
                         c: c*rhs.a+d*rhs.c, d: c*rhs.b+d*rhs.d, x: p.x, y: p.y)
    }
}

private struct Region {
    let x: Float, y: Float, width: Float, height: Float
    let rotated: Bool
    func uv(_ source: SIMD2<Float>, page: SIMD2<Float>) -> SIMD2<Float> {
        // Spine atlas positions and mesh UVs use a top-left origin.
        let p = rotated ? SIMD2(x + source.y * height, y + (1-source.x) * width)
                        : SIMD2(x + source.x * width, y + source.y * height)
        return SIMD2(p.x/page.x, 1-p.y/page.y)
    }
}

private struct Influence {
    let bone: Int
    let position: SIMD2<Float>
    let weight: Float
}
// Compile the same ten-segment 4.1 Bezier approximation once at load time.
// Absolute time/value control points are not normalized easing curves.
private struct ScalarTimeline {
    struct Frame {
        let time: Float, value: Float
        let points: [SIMD2<Float>]
        let stepped: Bool
    }
    let frames: [Frame]
    init(_ raw: [Object], key: String, channel: Int = 0, fraction: Bool = false) {
        frames = raw.enumerated().map { index, frame in
            let time = number(frame, "time"), value: Float = fraction ? 0 : number(frame, key)
            var points: [SIMD2<Float>] = []
            let curve = array(frame, "curve"), offset = channel*4
            if index+1 < raw.count {
                let end = number(raw[index+1], "time"), to: Float = fraction ? 1 : number(raw[index+1], key)
                if curve.count >= offset+4 {
                    func bezier(_ a: Float, _ b: Float, _ c: Float, _ d: Float, _ t: Float) -> Float {
                        let u = 1-t
                        return u*u*u*a + 3*u*u*t*b + 3*u*t*t*c + t*t*t*d
                    }
                    points = (1...10).map { step in
                        let t = Float(step)/10
                        return SIMD2(bezier(time, curve[offset], curve[offset+2], end, t),
                                     bezier(value, curve[offset+1], curve[offset+3], to, t))
                    }
                } else { points = [SIMD2(end, to)] }
            }
            return Frame(time: time, value: value, points: points, stepped: frame["curve"] as? String == "stepped")
        }
    }
    func sample(_ time: Float) -> Float {
        guard let index = frames.lastIndex(where: { $0.time <= time }) else { return 0 }
        return sample(time, index: index)
    }
    func sample(_ time: Float, index: Int) -> Float {
        let frame = frames[index]
        if frame.stepped { return frame.value }
        var previous = SIMD2(frame.time, frame.value)
        for point in frame.points {
            if time <= point.x {
                return point.x > previous.x ? previous.y + (point.y-previous.y)*(time-previous.x)/(point.x-previous.x) : point.y
            }
            previous = point
        }
        return previous.y
    }
}
private struct BonePose {
    let parent: Int?
    let x: Float, y: Float, rotation: Float, shearX: Float, shearY: Float, scaleX: Float, scaleY: Float
    let rotate: ScalarTimeline, translateX: ScalarTimeline, translateY: ScalarTimeline
}
private struct DeformTimeline {
    let curve: ScalarTimeline
    let values: [[Float]]
    let zero: [Float]
    init(_ frames: [Object], count: Int) throws {
        zero = [Float](repeating: 0, count: count)
        curve = ScalarTimeline(frames, key: "", fraction: true)
        values = try frames.map { frame in
            var result = [Float](repeating: 0, count: count)
            let values = array(frame, "vertices"), start = Int(number(frame, "offset"))
            guard start >= 0, start+values.count <= count else { throw PrototypeError("Invalid deform offset") }
            result.replaceSubrange(start..<(start+values.count), with: values)
            return result
        }
    }
    func sample(_ time: Float) -> [Float] {
        guard let index = curve.frames.lastIndex(where: { $0.time <= time }) else { return zero }
        let from = values[index]
        guard index+1 < values.count else { return from }
        let fraction = curve.sample(time, index: index), to = values[index+1]
        return zip(from, to).map { $0 + ($1-$0)*fraction }
    }
}
private struct Part {
    let slot: Int, key: String
    let node: TriangleMeshNode
    let influences: [[Influence]]
    let deform: DeformTimeline
}

final class Goblin: SKNode {
    private static var materials: [TriangleMeshNode.BoundsMode: TriangleMeshNode.Material] = [:]
    let skinName: String
    let duration: Float
    private let slots: [Object]
    private let bonePoses: [BonePose]
    private let slotFrames: [[(time: Float, name: String?)]]
    private let setupAttachments: [String?]
    private var transforms: [Transform]
    private var parts: [Part] = []
    private let wire = SKShapeNode()
    var showsWireframe = false { didSet { wire.isHidden = !showsWireframe } }
    var triangleCount: Int { parts.filter { !$0.node.isHidden }.reduce(0) { $0 + $1.node.triangleCount } }
    var submittedQuadArea: Double { parts.filter { !$0.node.isHidden }.reduce(0) { $0 + $1.node.submittedQuadArea } }
    var coveredTriangleArea: Double { parts.filter { !$0.node.isHidden }.reduce(0) { $0 + $1.node.coveredTriangleArea } }

    func vertexSnapshot() -> [[String: Any]] {
        parts.filter { !$0.node.isHidden }.map { part in
            ["slot": slots[part.slot]["name"] as! String, "attachment": part.key,
             "vertices": part.node.positions.flatMap { [Double($0.x), Double($0.y)] },
             "uvs": part.node.uvs.flatMap { [Double($0.x), Double($0.y)] }]
        }
    }

    init(skin: String, boundsMode: TriangleMeshNode.BoundsMode = .triangle) throws {
        skinName = skin
        let directory = Bundle.module.resourceURL!
        let json = try Data(contentsOf: directory.appendingPathComponent("goblins-pro.json"))
        guard let root = try JSONSerialization.jsonObject(with: json) as? Object,
              let skeleton = root["skeleton"] as? Object, skeleton["spine"] as? String == "4.1.17",
              let bones = root["bones"] as? [Object], let slots = root["slots"] as? [Object],
              let skins = root["skins"] as? [Object], let animations = root["animations"] as? Object,
              let animation = animations["walk"] as? Object else { throw PrototypeError("Unexpected Goblins fixture") }
        for key in ["ik", "transform", "path"] where !(root[key] as? [Object] ?? []).isEmpty {
            throw PrototypeError("Fixture player does not support \(key) constraints")
        }
        guard Set(animation.keys).isSubset(of: ["bones", "slots", "attachments"]) else {
            throw PrototypeError("Unsupported animation group")
        }
        for bone in bones where (bone["transform"] as? String ?? "normal") != "normal" {
            throw PrototypeError("Fixture player only supports normal transform inheritance")
        }
        self.slots = slots
        let boneAnimations = animation["bones"] as? [String: Object] ?? [:]
        var compiledBones: [BonePose] = [], indexByName: [String: Int] = [:]
        for (index, bone) in bones.enumerated() {
            let name = bone["name"] as! String, timelines = boneAnimations[name] ?? [:]
            guard Set(timelines.keys).isSubset(of: ["rotate", "translate"]) else { throw PrototypeError("Unsupported bone timeline") }
            let parent = (bone["parent"] as? String).flatMap { indexByName[$0] }
            if bone["parent"] != nil && parent == nil { throw PrototypeError("Invalid bone order") }
            compiledBones.append(BonePose(parent: parent, x: number(bone,"x"), y: number(bone,"y"),
                rotation: number(bone,"rotation"), shearX: number(bone,"shearX"), shearY: number(bone,"shearY"),
                scaleX: number(bone,"scaleX",1), scaleY: number(bone,"scaleY",1),
                rotate: ScalarTimeline(timelines["rotate"] as? [Object] ?? [], key: "value"),
                translateX: ScalarTimeline(timelines["translate"] as? [Object] ?? [], key: "x"),
                translateY: ScalarTimeline(timelines["translate"] as? [Object] ?? [], key: "y", channel: 1)))
            indexByName[name] = index
        }
        bonePoses = compiledBones
        transforms = [Transform](repeating: Transform(), count: bones.count)
        let slotTimelines = animation["slots"] as? [String: Object] ?? [:]
        setupAttachments = slots.map { $0["attachment"] as? String }
        slotFrames = slots.map { slot in
            (slotTimelines[slot["name"] as! String]?["attachment"] as? [Object] ?? []).map {
                (number($0, "time"), $0["name"] as? String)
            }
        }
        func lastTime(_ value: Any) -> Float {
            if let object = value as? Object { return max(number(object, "time"), object.values.map(lastTime).max() ?? 0) }
            if let list = value as? [Any] { return list.map(lastTime).max() ?? 0 }
            return 0
        }
        duration = lastTime(animation)
        let atlas = try String(contentsOf: directory.appendingPathComponent("goblins.atlas"), encoding: .utf8)
        var regions: [String: Region] = [:], current = "", bounds: [Float] = [], rotated = false
        var page = SIMD2<Float>(1024, 128)
        func finishRegion() throws {
            if bounds.isEmpty { return }
            guard bounds.count == 4 else { throw PrototypeError("Invalid atlas bounds") }
            regions[current] = Region(x: bounds[0], y: bounds[1], width: bounds[2], height: bounds[3], rotated: rotated)
        }
        for raw in atlas.components(separatedBy: .newlines) where !raw.isEmpty {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if !raw.hasPrefix("\t") && !raw.hasPrefix(" ") {
                try finishRegion(); current = line; bounds = []; rotated = false
            } else if line.hasPrefix("bounds:") {
                bounds = line.dropFirst(7).split(separator: ",").compactMap { Float($0.trimmingCharacters(in: .whitespaces)) }
            } else if line.hasPrefix("size:") {
                let values = line.dropFirst(5).split(separator: ",").compactMap { Float($0.trimmingCharacters(in: .whitespaces)) }
                guard values.count == 2 else { throw PrototypeError("Invalid atlas size") }
                page = SIMD2(values[0], values[1])
            } else if line.hasPrefix("rotate:") {
                guard line == "rotate: 90" else { throw PrototypeError("Unsupported atlas rotation") }
                rotated = true
            } else if !line.hasPrefix("filter:") { throw PrototypeError("Unsupported atlas property: \(line)") }
        }
        try finishRegion()
        guard let image = NSImage(contentsOf: directory.appendingPathComponent("goblins.png")) else {
            throw PrototypeError("Missing atlas image")
        }
        let material: TriangleMeshNode.Material
        if let cached = Self.materials[boundsMode] { material = cached }
        else {
            let texture = SKTexture(image: image)
            texture.filteringMode = .linear
            material = TriangleMeshNode.Material(texture: texture, boundsMode: boundsMode)
            Self.materials[boundsMode] = material
        }
        let skinMaps = Dictionary(uniqueKeysWithValues: skins.map { ($0["name"] as! String, $0["attachments"] as! [String: Object]) })
        guard let selected = skinMaps[skin] else { throw PrototypeError("Missing skin \(skin)") }
        super.init()
        let boneIndices = Dictionary(uniqueKeysWithValues: bones.enumerated().map { ($1["name"] as! String, $0) })
        func resolve(_ model: Object, _ slot: String, _ owner: String, _ key: String,
                     visited: Set<String> = []) throws -> (Object, String, String) {
            guard model["type"] as? String == "linkedmesh" else { return (model, owner, key) }
            let parentSkin = model["skin"] as? String ?? "default"
            guard let parentKey = model["parent"] as? String,
                  let parent = skinMaps[parentSkin]?[slot]?[parentKey] as? Object else { throw PrototypeError("Missing linked mesh parent") }
            let identity = parentSkin + "/" + slot + "/" + parentKey
            guard !visited.contains(identity) else { throw PrototypeError("Linked mesh cycle") }
            let resolved = try resolve(parent, slot, parentSkin, parentKey, visited: visited.union([identity]))
            return (resolved.0, (model["timelines"] as? Bool ?? true) ? resolved.1 : owner,
                    (model["timelines"] as? Bool ?? true) ? resolved.2 : key)
        }
        for (slotIndex, slot) in slots.enumerated() {
            let slotName = slot["name"] as! String
            guard let bone = boneIndices[slot["bone"] as! String] else { throw PrototypeError("Missing slot bone") }
            var attachments = skinMaps["default"]?[slotName] ?? [:]
            attachments.merge(selected[slotName] ?? [:]) { _, new in new }
            for key in attachments.keys.sorted() {
                let model = attachments[key] as! Object
                let owner = selected[slotName]?[key] != nil ? skin : "default"
                let (geometry, timelineSkin, timelineKey) = try resolve(model, slotName, owner, key)
                let path = model["path"] as? String ?? model["name"] as? String ?? key
                guard let region = regions[path] else { throw PrototypeError("Missing atlas region \(path)") }
                let type = geometry["type"] as? String ?? "region"
                var uv: [SIMD2<Float>] = [], influences: [[Influence]] = [], indices: [Int] = []
                var weighted = false
                if type == "mesh" {
                    let rawUV = array(geometry, "uvs"), vertices = array(geometry, "vertices")
                    guard rawUV.count.isMultiple(of: 2) else { throw PrototypeError("Invalid mesh UVs") }
                    uv = stride(from: 0, to: rawUV.count, by: 2).map { region.uv(SIMD2(rawUV[$0], rawUV[$0+1]), page: page) }
                    indices = (geometry["triangles"] as? [Int]) ?? []
                    weighted = vertices.count != rawUV.count
                    var cursor = 0
                    for _ in uv {
                        if weighted {
                            guard cursor < vertices.count else { throw PrototypeError("Truncated weights") }
                            let count = Int(vertices[cursor]); cursor += 1
                            guard count > 0, cursor+count*4 <= vertices.count else { throw PrototypeError("Invalid weights") }
                            var vertex: [Influence] = []
                            for _ in 0..<count {
                                let index = Int(vertices[cursor])
                                guard bones.indices.contains(index) else { throw PrototypeError("Invalid bone index") }
                                vertex.append(Influence(bone: index, position: SIMD2(vertices[cursor+1], vertices[cursor+2]), weight: vertices[cursor+3]))
                                cursor += 4
                            }
                            influences.append(vertex)
                        } else {
                            influences.append([Influence(bone: bone, position: SIMD2(vertices[cursor], vertices[cursor+1]), weight: 1)])
                            cursor += 2
                        }
                    }
                    guard cursor == vertices.count else { throw PrototypeError("Trailing vertex data") }
                } else if type == "region" {
                    let halfWidth = number(model, "width")/2, halfHeight = number(model, "height")/2
                    let radians = number(model, "rotation") * .pi / 180
                    let scaleX = number(model, "scaleX", 1), scaleY = number(model, "scaleY", 1)
                    let local = Transform(a: cos(radians)*scaleX, b: -sin(radians)*scaleY,
                                          c: sin(radians)*scaleX, d: cos(radians)*scaleY,
                                          x: number(model, "x"), y: number(model, "y"))
                    let corners = [SIMD2(-halfWidth, -halfHeight), SIMD2(halfWidth, -halfHeight), SIMD2(halfWidth, halfHeight), SIMD2(-halfWidth, halfHeight)]
                    influences = corners.map { [Influence(bone: bone, position: local.point($0), weight: 1)] }
                    uv = [SIMD2<Float>(0,1), SIMD2(1,1), SIMD2(1,0), SIMD2(0,0)].map { region.uv($0, page: page) }
                    indices = [0,1,2, 0,2,3]
                } else { throw PrototypeError("Unsupported attachment \(type)") }
                for object in [model, slot] {
                    guard (object["color"] as? String ?? "ffffffff").lowercased() == "ffffffff",
                          object["dark"] == nil, (object["blend"] as? String ?? "normal") == "normal" else {
                        throw PrototypeError("Fixture player only supports white tint and normal blending")
                    }
                }
                let node = try TriangleMeshNode(material: material, positions: influences.map { $0[0].position }, uvs: uv, indices: indices)
                node.zPosition = CGFloat(slotIndex)
                node.name = slotName + "/" + key
                addChild(node)
                parts.append(Part(slot: slotIndex, key: key, node: node, influences: influences,
                                  deform: try DeformTimeline(
                                    (animation["attachments"] as? [String: [String: [String: Object]]])?[timelineSkin]?[slotName]?[timelineKey]?["deform"] as? [Object] ?? [],
                                    count: weighted ? influences.reduce(0) { $0 + $1.count*2 } : influences.count*2)))
            }
        }
        wire.strokeColor = NSColor.systemYellow.withAlphaComponent(0.7)
        wire.lineWidth = 0.45; wire.zPosition = 100; wire.isHidden = true
        addChild(wire)
        try sample(time: 0)
    }

    required init?(coder: NSCoder) { fatalError("Use init(skin:)") }

    func sample(time: Float) throws {
        let t = max(0, time)
        for (index, bone) in bonePoses.enumerated() {
            let rotation = bone.rotation + bone.rotate.sample(t)
            let x = bone.x + bone.translateX.sample(t), y = bone.y + bone.translateY.sample(t)
            let rx = (rotation + bone.shearX) * .pi / 180
            let ry = (rotation + 90 + bone.shearY) * .pi / 180
            let local = Transform(a: cos(rx)*bone.scaleX, b: cos(ry)*bone.scaleY,
                                  c: sin(rx)*bone.scaleX, d: sin(ry)*bone.scaleY, x: x, y: y)
            transforms[index] = bone.parent.map { transforms[$0].appending(local) } ?? local
        }
        let active = slots.indices.map { index in
            slotFrames[index].last(where: { $0.time <= t }).map { $0.name } ?? setupAttachments[index]
        }
        let path = showsWireframe ? CGMutablePath() : nil
        for part in parts {
            part.node.isHidden = active[part.slot] != part.key
            if part.node.isHidden { continue }
            let deform = part.deform.sample(t)
            var offset = 0
            let positions = part.influences.map { influences -> SIMD2<Float> in
                var result = SIMD2<Float>.zero
                for influence in influences {
                    let delta = SIMD2(deform[offset], deform[offset+1]); offset += 2
                    result += transforms[influence.bone].point(influence.position + delta) * influence.weight
                }
                return result
            }
            try part.node.updatePositions(positions)
            if showsWireframe {
                for start in stride(from: 0, to: part.node.indices.count, by: 3) {
                    for vertex in 0..<3 {
                        let p = positions[part.node.indices[start+vertex]]
                        let point = CGPoint(x: CGFloat(p.x), y: CGFloat(p.y))
                        if vertex == 0 { path?.move(to: point) } else { path?.addLine(to: point) }
                    }
                    path?.closeSubpath()
                }
            }
        }
        wire.path = showsWireframe ? path : nil
    }
}
