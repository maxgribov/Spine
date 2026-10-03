import Foundation

/// Capability observations from the same decoder, never an alternate JSON loader.
struct SpineFeatureIssue {
    enum Kind { case knownUnsupported, obsoleteMeshLayout }
    let path: String
    let name: String
    let kind: Kind

    static func pointer(_ keys: [CodingKey]) -> String {
        keys.map { "/" + ($0.intValue.map(String.init) ?? $0.stringValue).replacingOccurrences(of: "~",with: "~0").replacingOccurrences(of: "/",with: "~1") }.joined()
    }

    static func inspect(_ decoder: Decoder) -> [SpineFeatureIssue] {
        typealias Object = KeyedDecodingContainer<SpineNameKey>
        func key(_ name: String) -> SpineNameKey { SpineNameKey(stringValue: name)! }
        func child(_ object: Object, _ name: String) -> Object? { try? object.nestedContainer(keyedBy: SpineNameKey.self,forKey:key(name)) }
        var result: [SpineFeatureIssue] = []
        func observe(_ object: Object, _ name: String, _ kind: Kind = .knownUnsupported, ignoreEmpty:Bool = false) {
            guard object.contains(key(name)) else { return }
            if ignoreEmpty {
                if let array=try? object.nestedUnkeyedContainer(forKey:key(name)),array.isAtEnd {return}
                if let object=child(object,name),object.allKeys.isEmpty {return}
            }
            result.append(.init(path:pointer(object.codingPath+[key(name)]),name:name,kind:kind))
        }
        guard let root = try? decoder.container(keyedBy:SpineNameKey.self) else { return [] }
        if var bones=try? root.nestedUnkeyedContainer(forKey:key("bones")) {
            while !bones.isAtEnd {
                guard let bone=try? bones.nestedContainer(keyedBy:SpineNameKey.self) else {break}
                if (try? bone.decode(Bool.self,forKey:key("skin"))) == true {observe(bone,"skin")}
            }
        }
        if var skins = try? root.nestedUnkeyedContainer(forKey:key("skins")) {
            while !skins.isAtEnd {
                guard let skin = try? skins.nestedContainer(keyedBy:SpineNameKey.self) else { break }
                for name in ["bones","ik","transform","path"] { observe(skin,name,ignoreEmpty:true) }
                if let slots = child(skin,"attachments") {
                    for slotKey in slots.allKeys {
                        guard let attachments = child(slots,slotKey.stringValue) else { continue }
                        for attachmentKey in attachments.allKeys {
                            guard let attachment = child(attachments,attachmentKey.stringValue) else { continue }
                            observe(attachment,"sequence")
                            if (try? attachment.decode(String.self,forKey:key("type"))) == "linkedmesh" {
                                observe(attachment,"deform",.obsoleteMeshLayout)
                            }
                        }
                    }
                }
            }
        }
        if let animations = child(root,"animations") {
            for animationKey in animations.allKeys {
                guard let animation = child(animations,animationKey.stringValue) else { continue }
                observe(animation,"deform",.obsoleteMeshLayout)
                for name in ["ik","transform","path"] { observe(animation,name,ignoreEmpty:true) }
                if let bones = child(animation,"bones") {
                    for bone in bones.allKeys {
                        guard let channels = child(bones,bone.stringValue) else { continue }
                        for name in ["shear","shearx","sheary"] { observe(channels,name) }
                    }
                }
                if let slots = child(animation,"slots") {
                    for slot in slots.allKeys {
                        guard let channels = child(slots,slot.stringValue) else { continue }
                        for name in ["rgba2","rgb2"] { observe(channels,name) }
                    }
                }
                if let skins = child(animation,"attachments") {
                    for skin in skins.allKeys {
                        guard let slots = child(skins,skin.stringValue) else { continue }
                        for slot in slots.allKeys {
                            guard let attachments = child(slots,slot.stringValue) else { continue }
                            for attachment in attachments.allKeys {
                                guard let channels = child(attachments,attachment.stringValue) else { continue }
                                observe(channels,"sequence")
                            }
                        }
                    }
                }
            }
        }
        return result.sorted { $0.path < $1.path }
    }
}
