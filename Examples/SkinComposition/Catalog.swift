import Foundation
import Spine

struct CatalogItem {
    let skin: String
    let slots: Set<String>
    let hidden: Set<String>
}

enum CatalogError: Error { case area(String), conflict(String) }

struct Wardrobe {
    static let teams = ["blue", "orange", "purple", "pink"]
    var hat = 0, clothes = 0, team = 0
    var earring = true
    var composition: SpineSkinComposition {
        .init(baseSkin: "base", layers: [
            .replace(skin: "hat/" + (hat == 0 ? "a" : "b"), slots: ["hat-front", "hat-back"]),
            .replace(skin: "clothes/" + (clothes == 0 ? "a" : "b"), slots: ["torso", "sleeves"]),
            .hide(slots: earring ? ["bandana"] : ["bandana", "earring"]),
            .overlay(skin: "team/" + Self.teams[team])
        ])
    }

    static func validate(_ items: [CatalogItem], asset: SpineMeshAsset) throws {
        var occupied = Set<String>()
        for item in items {
            let entries = try asset.skinDescription(named: item.skin).entries
            guard Set(entries.map(\.slot)) == item.slots, entries.allSatisfy({ $0.kind == .region }) else { throw CatalogError.area(item.skin) }
            let area = item.slots.union(item.hidden)
            guard occupied.isDisjoint(with: area) else { throw CatalogError.conflict(item.skin) }
            occupied.formUnion(area)
            var layers: [SpineSkinLayer] = [.replace(skin: item.skin, slots: item.slots.sorted())]
            if !item.hidden.isEmpty { layers.append(.hide(slots: item.hidden.sorted())) }
            try asset.validate(skinComposition: .init(baseSkin: "base", layers: layers))
        }
    }

    static func validateAll(asset: SpineMeshAsset) throws -> Int {
        for hat in ["a", "b"] {
            for clothes in ["a", "b"] {
                try validate([.init(skin: "hat/" + hat, slots: ["hat-front", "hat-back"], hidden: ["bandana"]),
                              .init(skin: "clothes/" + clothes, slots: ["torso", "sleeves"], hidden: [])], asset: asset)
            }
        }
        var count = 0
        for hat in 0..<2 { for clothes in 0..<2 { for team in 0..<4 { for earring in [false, true] {
            try asset.validate(skinComposition: Wardrobe(hat: hat, clothes: clothes, team: team, earring: earring).composition)
            count += 1
        } } } }
        let item = CatalogItem(skin: "hat/a", slots: ["hat-front", "hat-back"], hidden: ["bandana"])
        do { try validate([item, item], asset: asset); throw CatalogError.area("Conflict check failed") }
        catch CatalogError.conflict { }
        return count
    }
}
