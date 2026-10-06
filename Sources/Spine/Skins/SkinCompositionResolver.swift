/// Content-only resolution shared by validation and the runtime transaction.
/// It reads immutable compiled values and never constructs scene resources.
enum SkinCompositionResolver {
    struct Result {
        let lookup: [MeshAttachmentKey: Int]
        let touchedSlots: Set<Int>
    }

    static func resolve(_ composition: SpineSkinComposition, in asset: CompiledMeshSkeleton) throws -> Result {
        try requireSkin(composition.baseSkin, in: asset, path: "/composition/baseSkin")
        var lookup = asset.skinAttachments["default"] ?? [:]
        lookup.merge(asset.skinAttachments[composition.baseSkin] ?? [:]) { _, new in new }
        let protected = Set(lookup.compactMap { key, id in
            asset.attachments[id].sourceKind == .region ? nil : key.slot
        })
        let slotIndices = Dictionary(uniqueKeysWithValues: asset.slots.enumerated().map { ($0.element.name, $0.offset) })
        let required = requiredStates(in: asset)
        var touched = Set<Int>()

        for (index, layer) in composition.layers.enumerated() {
            let path = "/composition/layers/\(index)"
            let skin: String?
            let names: [String]?
            let replaces: Bool
            switch layer {
            case .overlay(let name): skin = name; names = nil; replaces = false
            case .replace(let name, let slots): skin = name; names = slots; replaces = true
            case .hide(let slots): skin = nil; names = slots; replaces = false
            }
            if let skin = skin { try requireSkin(skin, in: asset, path: path + "/skin") }
            let own = skin.flatMap { asset.skinAttachments[$0] } ?? [:]
            let selected: Set<Int>
            if let names = names {
                guard !names.isEmpty else {
                    throw SpineRuntimeError(.invalidSkinComposition, path: path + "/slots", message: "Slots must not be empty.")
                }
                var seen = Set<String>(), indices = Set<Int>()
                for (offset, name) in names.enumerated() {
                    let location = path + "/slots/\(offset)"
                    guard seen.insert(name).inserted else {
                        throw SpineRuntimeError(.invalidSkinComposition, path: location, message: "Duplicate slot '\(name)'.")
                    }
                    guard let slot = slotIndices[name] else {
                        throw SpineRuntimeError(.missingSlot, path: location, message: "Slot '\(name)' does not exist.")
                    }
                    indices.insert(slot)
                }
                selected = indices
            } else { selected = Set(own.keys.map(\.slot)) }

            for slot in selected.sorted() where protected.contains(slot) {
                throw SpineRuntimeError(.unsupportedFeature, path: path + "/slots/" + escape(asset.slots[slot].name),
                                        message: "Base skin '\(composition.baseSkin)' protects slot '\(asset.slots[slot].name)' containing non-region states.")
            }
            let entries = own.filter { selected.contains($0.key.slot) }.sorted {
                $0.key.slot == $1.key.slot ? $0.key.name < $1.key.name : $0.key.slot < $1.key.slot
            }
            for (key, id) in entries where asset.attachments[id].sourceKind != .region {
                let kind = asset.attachments[id].sourceKind.rawValue
                throw SpineRuntimeError(.unsupportedFeature, path: attachmentPath(path, slot: asset.slots[key.slot].name, name: key.name),
                                        message: "Skin '\(skin ?? "")', slot '\(asset.slots[key.slot].name)', attachment '\(key.name)' has unsupported type '\(kind)'.")
            }
            if replaces {
                for slot in selected.sorted() {
                    for name in required[slot].keys.sorted() where own[MeshAttachmentKey(slot: slot, name: name)] == nil {
                        let source = required[slot][name] ?? "setup"
                        throw SpineRuntimeError(.incompleteSkinComposition,
                                                path: attachmentPath(path, slot: asset.slots[slot].name, name: name),
                                                message: "Skin '\(skin ?? "")' is missing slot '\(asset.slots[slot].name)', attachment '\(name)' required by \(source).")
                    }
                }
            }
            if names != nil { lookup = lookup.filter { !selected.contains($0.key.slot) } }
            for (key, id) in entries { lookup[key] = id }
            touched.formUnion(selected)
        }
        return Result(lookup: lookup, touchedSlots: touched)
    }

    private static func requiredStates(in asset: CompiledMeshSkeleton) -> [[String: String]] {
        var required = asset.slots.map { slot -> [String: String] in
            slot.attachment.map { [$0: "setup"] } ?? [:]
        }
        for clip in asset.clips.sorted(by: { $0.name < $1.name }) {
            for timeline in clip.attachments {
                for key in timeline.keys {
                    if let name = key.name, required[timeline.slot][name] == nil {
                        required[timeline.slot][name] = "clip '\(clip.name)'"
                    }
                }
            }
        }
        return required
    }

    private static func requireSkin(_ name: String, in asset: CompiledMeshSkeleton, path: String) throws {
        guard asset.skinNames.contains(name) else {
            throw SpineRuntimeError(.missingSkin, path: path, message: "Skin '\(name)' does not exist.")
        }
    }

    private static func escape(_ name: String) -> String { SpineRuntimeError.pointerComponent(name) }
    private static func attachmentPath(_ path: String, slot: String, name: String) -> String {
        path + "/attachments/" + escape(slot) + "/" + escape(name)
    }
}
