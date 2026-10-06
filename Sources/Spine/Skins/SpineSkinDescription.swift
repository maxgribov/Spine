public enum SpineSkinAttachmentKind: String, Equatable {
    case region, mesh, linkedMesh, point, boundingBox
}

public struct SpineSkinEntry: Equatable {
    public let slot: String
    /// Logical placeholder key, not the texture path.
    public let name: String
    public let kind: SpineSkinAttachmentKind
}

public struct SpineSkinDescription: Equatable {
    public let name: String
    public let entries: [SpineSkinEntry]
}

public extension SpineMeshAsset {
    /// Own entries only, in setup-slot and then placeholder-name order.
    /// Serialize access to the asset. No default fallback is included.
    func skinDescription(named name: String) throws -> SpineSkinDescription {
        guard compiled.skinNames.contains(name) else {
            throw SpineRuntimeError(.missingSkin, path: "/skins/" + SpineRuntimeError.pointerComponent(name),
                                    message: "Skin '\(name)' does not exist.")
        }
        let entries = (compiled.skinAttachments[name] ?? [:]).sorted {
            $0.key.slot == $1.key.slot ? $0.key.name < $1.key.name : $0.key.slot < $1.key.slot
        }.map { key, id in
            SpineSkinEntry(slot: compiled.slots[key.slot].name, name: key.name,
                           kind: compiled.attachments[id].sourceKind)
        }
        return SpineSkinDescription(name: name, entries: entries)
    }
}
