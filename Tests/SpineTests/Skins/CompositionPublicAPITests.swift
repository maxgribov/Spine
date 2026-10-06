#if os(macOS) || os(iOS)
import XCTest
import Spine

/// Intentionally uses only exported library API and actual bundled JSON/PNG.
final class CompositionPublicAPITests: XCTestCase {
    private struct CatalogItem {
        let skin: String
        let slots: Set<String>
        let hidden: Set<String>
    }
    private enum CatalogError: Error { case incorrectArea, forbiddenConflict }

    private func validateCatalog(_ items: [CatalogItem], asset: SpineMeshAsset) throws {
        var occupied = Set<String>()
        for item in items {
            let metadata = try asset.skinDescription(named: item.skin)
            guard Set(metadata.entries.map(\.slot)) == item.slots,
                  metadata.entries.allSatisfy({ $0.kind == .region }) else { throw CatalogError.incorrectArea }
            let area = item.slots.union(item.hidden)
            guard occupied.isDisjoint(with: area) else { throw CatalogError.forbiddenConflict }
            occupied.formUnion(area)
            var layers: [SpineSkinLayer] = [.replace(skin: item.skin, slots: item.slots.sorted())]
            if !item.hidden.isEmpty { layers.append(.hide(slots: item.hidden.sorted())) }
            try asset.validate(skinComposition: .init(baseSkin: "base", layers: layers))
        }
    }

    func testPublicValidationMetadataAndThirtyTwoOutfits() throws {
        let root = try XCTUnwrap(Bundle.module.resourceURL).appendingPathComponent("Mesh41/skin-composition")
        let provider = try SpineAtlasTextureProvider(
            atlasText: String(contentsOf: root.appendingPathComponent("swatch.atlas"), encoding: .utf8),
            pageData: ["swatch.png": Data(contentsOf: root.appendingPathComponent("swatch.png"))])
        let asset = try SpineMeshAsset(json: Data(contentsOf: root.appendingPathComponent("wardrobe.json")), textures: provider)
        let hat = CatalogItem(skin: "hat/a", slots: ["hat-front", "hat-back"], hidden: ["bandana"])
        let clothes = CatalogItem(skin: "clothes/a", slots: ["torso", "sleeves"], hidden: [])
        try validateCatalog([hat, clothes], asset: asset)
        XCTAssertThrowsError(try validateCatalog([hat, hat], asset: asset)) {
            guard case CatalogError.forbiddenConflict = $0 else { return XCTFail("Wrong catalog error") }
        }
        XCTAssertThrowsError(try validateCatalog([CatalogItem(skin: "hat/a", slots: ["torso"], hidden: [])], asset: asset)) {
            guard case CatalogError.incorrectArea = $0 else { return XCTFail("Wrong catalog error") }
        }
        var count = 0
        for hat in ["a", "b"] {
            for clothes in ["a", "b"] {
                for earring in [false, true] {
                    for team in ["blue", "orange", "purple", "pink"] {
                        let look = SpineSkinComposition(baseSkin: "base", layers: [
                            .replace(skin: "hat/" + hat, slots: ["hat-front", "hat-back"]),
                            .replace(skin: "clothes/" + clothes, slots: ["torso", "sleeves"]),
                            .hide(slots: earring ? ["bandana"] : ["bandana", "earring"]),
                            .overlay(skin: "team/" + team)
                        ])
                        try asset.validate(skinComposition: look)
                        XCTAssertEqual(look, SpineSkinComposition(baseSkin: look.baseSkin, layers: look.layers))
                        count += 1
                    }
                }
            }
        }
        XCTAssertEqual(count, 32)
        do {
            try asset.validate(skinComposition: .init(baseSkin: "base", layers: [.hide(slots: [])]))
            XCTFail("Expected invalidSkinComposition")
        } catch let error as SpineRuntimeError {
            XCTAssertEqual(error.code, .invalidSkinComposition)
        }
    }
}
#endif
