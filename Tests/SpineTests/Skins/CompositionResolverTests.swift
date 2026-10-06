#if os(macOS) || os(iOS)
import XCTest
@testable import Spine

func wardrobeJSON(_ name: String = "wardrobe") throws -> [String: Any] {
    try XCTUnwrap(JSONSerialization.jsonObject(with: meshResource("skin-composition/\(name).json")) as? [String: Any])
}
func wardrobeAsset(_ json: [String: Any]? = nil) throws -> SpineMeshAsset {
    try SpineMeshAsset(json: jsonData(json ?? wardrobeJSON()), textures: TestMeshTextures())
}
func compositionError(_ asset: SpineMeshAsset, _ layers: [SpineSkinLayer], _ code: SpineRuntimeError.Code,
                      _ path: String, base: String = "base", message: String? = nil,
                      file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertThrowsError(try asset.validate(skinComposition: .init(baseSkin: base, layers: layers)), file: file, line: line) {
        guard let error = $0 as? SpineRuntimeError else { return XCTFail("Wrong error \($0)", file: file, line: line) }
        XCTAssertEqual(error.code, code, file: file, line: line)
        XCTAssertEqual(error.path, path, file: file, line: line)
        if let message = message { XCTAssertTrue(error.message.contains(message), error.message, file: file, line: line) }
    }
}

final class CompositionResolverTests: XCTestCase {
    func testEarringFixtureHasVisibleSetupAndExplicitHideRemovesIt() throws {
        for name in ["wardrobe", "mixed"] {
            let asset = try wardrobeAsset(wardrobeJSON(name))
            let slot = try XCTUnwrap(asset.compiled.slots.firstIndex { $0.name == "earring" })
            let request = try XCTUnwrap(asset.compiled.slots[slot].attachment)
            XCTAssertEqual(request, "front")
            let visible = try SkinCompositionResolver.resolve(.init(baseSkin: "base", layers: []), in: asset.compiled)
            let hidden = try SkinCompositionResolver.resolve(.init(baseSkin: "base", layers: [.hide(slots: ["earring"])]), in: asset.compiled)
            XCTAssertNotNil(visible.lookup[.init(slot: slot, name: request)])
            XCTAssertNil(hidden.lookup[.init(slot: slot, name: request)])
            compositionError(asset, [.replace(skin: "empty", slots: ["earring"])], .incompleteSkinComposition,
                             "/composition/layers/0/attachments/earring/front", message: "setup")
        }
    }

    func testBaseDefaultAndSelectedSubset() throws {
        let asset = try wardrobeAsset()
        let result = try SkinCompositionResolver.resolve(.init(baseSkin: "base", layers: [
            .replace(skin: "hat/a", slots: ["hat-front"])
        ]), in: asset.compiled)
        XCTAssertEqual(result.touchedSlots, [0])
        XCTAssertEqual(result.lookup[.init(slot: 0, name: "side")], asset.compiled.skinAttachments["hat/a"]?[.init(slot: 0, name: "side")])
        XCTAssertEqual(result.lookup[.init(slot: 1, name: "front")], asset.compiled.skinAttachments["base"]?[.init(slot: 1, name: "front")])
        compositionError(asset, [], .missingSkin, "/composition/baseSkin", base: "Base")
        var json = try wardrobeJSON()
        json["skins"] = (json["skins"] as? [[String: Any]])?.filter { $0["name"] as? String != "default" }
        XCTAssertNoThrow(try wardrobeAsset(json).validate(skinComposition: .init(baseSkin: "base", layers: [])))
        json["skins"] = []; json["animations"] = [:]; json["slots"] = []
        let empty = try wardrobeAsset(json)
        XCTAssertEqual(try empty.skinDescription(named: "default").entries, [])
        XCTAssertNoThrow(try empty.validate(skinComposition: .init(baseSkin: "default", layers: [])))
    }

    func testHideHasNoFallbackAndLaterOverlayOpensOnlyOwnKeys() throws {
        let asset = try wardrobeAsset()
        let layers: [SpineSkinLayer] = [.overlay(skin: "hat/a"), .hide(slots: ["hat-front"]), .overlay(skin: "partial")]
        let result = try SkinCompositionResolver.resolve(.init(baseSkin: "base", layers: layers), in: asset.compiled)
        XCTAssertNotNil(result.lookup[.init(slot: 0, name: "front")])
        XCTAssertNil(result.lookup[.init(slot: 0, name: "side")])
        let replaced = try SkinCompositionResolver.resolve(.init(baseSkin: "base", layers: layers + [.replace(skin: "hat/b", slots: ["hat-front"])]), in: asset.compiled)
        XCTAssertEqual(replaced.lookup[.init(slot: 0, name: "side")], asset.compiled.skinAttachments["hat/b"]?[.init(slot: 0, name: "side")])
        let restored = try SkinCompositionResolver.resolve(.init(baseSkin: "base", layers: [.overlay(skin: "empty"), .overlay(skin: "default"), .overlay(skin: "default")]), in: asset.compiled)
        XCTAssertEqual(restored.lookup[.init(slot: 0, name: "side")], asset.compiled.skinAttachments["default"]?[.init(slot: 0, name: "side")])
    }

    func test_resolve_inheritsDefaultOnlyWhenPresent_andBaseOverridesMatchingKeys() throws {
        // Given: base owns front but deliberately omits side.
        var json = try wardrobeJSON()
        var skins = try XCTUnwrap(json["skins"] as? [[String: Any]])
        var entries = try XCTUnwrap(skins[1]["attachments"] as? [String: [String: Any]])
        entries["hat-front"]?.removeValue(forKey: "side")
        skins[1]["attachments"] = entries
        json["skins"] = skins
        let asset = try wardrobeAsset(json)
        // Trace: default keys load first, then matching base front overwrites;
        // absent base side inherits. Recompiling without default leaves side absent.
        // When
        let result = try SkinCompositionResolver.resolve(.init(baseSkin: "base", layers: []), in: asset.compiled)
        json["skins"] = skins.filter { $0["name"] as? String != "default" }
        let withoutDefault = try wardrobeAsset(json)
        let noFallback = try SkinCompositionResolver.resolve(.init(baseSkin: "base", layers: []), in: withoutDefault.compiled)
        // Then
        XCTAssertEqual(result.lookup[.init(slot: 0, name: "front")],
                       try XCTUnwrap(asset.compiled.skinAttachments["base"]?[.init(slot: 0, name: "front")]))
        XCTAssertEqual(result.lookup[.init(slot: 0, name: "side")],
                       try XCTUnwrap(asset.compiled.skinAttachments["default"]?[.init(slot: 0, name: "side")]))
        XCTAssertNil(noFallback.lookup[.init(slot: 0, name: "side")])
    }

    func test_resolve_replacementRemovesUnrequestedBaseKeys_andRemovingHideRestoresBase() throws {
        // Given: spare is a base-only key, never demanded by setup or clips.
        var json = try wardrobeJSON()
        var skins = try XCTUnwrap(json["skins"] as? [[String: Any]])
        var entries = try XCTUnwrap(skins[1]["attachments"] as? [String: [String: Any]])
        entries["hat-front"]?["spare"] = ["type": "region", "path": "swatch", "width": 16, "height": 16]
        skins[1]["attachments"] = entries
        json["skins"] = skins
        let asset = try wardrobeAsset(json)
        // Trace: replace validates required front/side then removes ALL slot keys;
        // hide also removes all keys. A new empty descriptor resolves the base afresh.
        // When
        let replaced = try SkinCompositionResolver.resolve(.init(baseSkin: "base", layers: [
            .replace(skin: "hat/a", slots: ["hat-front"])
        ]), in: asset.compiled)
        let hidden = try SkinCompositionResolver.resolve(.init(baseSkin: "base", layers: [
            .hide(slots: ["hat-front"])
        ]), in: asset.compiled)
        let restored = try SkinCompositionResolver.resolve(.init(baseSkin: "base", layers: []), in: asset.compiled)
        // Then
        XCTAssertNil(replaced.lookup[.init(slot: 0, name: "spare")])
        XCTAssertNil(hidden.lookup[.init(slot: 0, name: "spare")])
        XCTAssertEqual(restored.lookup[.init(slot: 0, name: "spare")],
                       try XCTUnwrap(asset.compiled.skinAttachments["base"]?[.init(slot: 0, name: "spare")]))
    }

    func testFirstErrorOrderingForNamesAndSlotStructure() throws {
        let asset = try wardrobeAsset()
        compositionError(asset, [.replace(skin: "missing", slots: [])], .missingSkin, "/composition/baseSkin", base: "missing")
        compositionError(asset, [.replace(skin: "missing", slots: [])], .missingSkin, "/composition/layers/0/skin")
        compositionError(asset, [.hide(slots: [])], .invalidSkinComposition, "/composition/layers/0/slots")
        compositionError(asset, [.hide(slots: ["torso", "torso"])], .invalidSkinComposition, "/composition/layers/0/slots/1")
        compositionError(asset, [.hide(slots: ["missing", "missing"])], .missingSlot, "/composition/layers/0/slots/0")
        compositionError(asset, [.overlay(skin: "empty"), .hide(slots: ["unknown"])], .missingSlot, "/composition/layers/1/slots/0")
    }
}
#endif
