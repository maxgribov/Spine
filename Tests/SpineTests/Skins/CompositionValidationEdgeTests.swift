#if os(macOS) || os(iOS)
import XCTest
import Spine

/// Public validation boundaries; fixture strings are deliberate Spine contract keys.
final class CompositionValidationEdgeTests: XCTestCase {
    func test_validate_rejectsReplacementWithoutOwnEntries_evenWhenDefaultAndLaterOverlayCoverIt() throws {
        // Given: empty owns no keys; default and hat/a both cover front and side.
        let (sut, _) = try makeSUT()
        // Trace: resolve base -> select hat-front -> region checks -> own front missing.
        // Neither accumulated default entries nor a later overlay participate in completeness.
        // When / Then
        compositionError(sut, [.replace(skin: "empty", slots: ["hat-front"]), .overlay(skin: "hat/a")],
                         .incompleteSkinComposition, "/composition/layers/0/attachments/hat-front/front", message: "setup")
        compositionError(sut, [.replace(skin: "partial", slots: ["hat-front"]), .overlay(skin: "hat/a")],
                         .incompleteSkinComposition, "/composition/layers/0/attachments/hat-front/side", message: "walk")
    }

    func test_validate_acceptsEmptyReplacement_whenSetupAndAllClipKeysAreNil() throws {
        // Given
        var json = try wardrobeJSON()
        json["animations"] = ["nil-only": ["slots": ["empty": ["attachment": [["time": 0], ["time": 1]]]]]]
        let (sut, _) = try makeSUT(json: json)
        // Trace: requiredStates skips nil setup and timeline names; selected region slot has
        // no own entries and no required names, so replacement succeeds.
        // When / Then
        XCTAssertNoThrow(try sut.validate(skinComposition: .init(baseSkin: "base", layers: [
            .replace(skin: "empty", slots: ["empty"])
        ])))
    }

    func test_validate_ordersIncompleteStatesBySetupSlotThenKey_andPrefersSetupSource() throws {
        // Given: the input lists slots backwards; setup front also occurs in a clip.
        var json = try wardrobeJSON()
        json["animations"] = ["alpha": ["slots": ["hat-front": ["attachment": [["time": 0, "name": "front"]]]]]]
        let (sut, _) = try makeSUT(json: json)
        // Trace: selected indices sort into setup order (hat-front before hat-back),
        // required front retains setup as source because timelines never overwrite it.
        // When / Then
        compositionError(sut, [.replace(skin: "empty", slots: ["hat-back", "hat-front"])],
                         .incompleteSkinComposition, "/composition/layers/0/attachments/hat-front/front", message: "setup")
    }

    func test_validate_reportsLexicallyFirstMissingKey_beforeSetupKey() throws {
        // Given: alpha sorts before setup front even though the clip is visited later.
        var json = try wardrobeJSON()
        json["animations"] = ["rare": ["slots": ["hat-front": ["attachment": [["time": 0, "name": "alpha"]]]]]]
        var skins = try XCTUnwrap(json["skins"] as? [[String: Any]])
        var entries = try XCTUnwrap(skins[0]["attachments"] as? [String: [String: Any]])
        entries["hat-front"]?["alpha"] = ["type": "region", "path": "swatch", "width": 16, "height": 16]
        skins[0]["attachments"] = entries
        json["skins"] = skins
        let (sut, _) = try makeSUT(json: json)
        // Trace: required front from setup + alpha from rare -> sorted keys alpha,front.
        // When / Then
        compositionError(sut, [.replace(skin: "empty", slots: ["hat-front"])],
                         .incompleteSkinComposition, "/composition/layers/0/attachments/hat-front/alpha", message: "rare")
    }

    func test_validate_checksWholeSlotListBeforeProtectedSlots() throws {
        // Given
        let (sut, _) = try makeSUT(json: wardrobeJSON("mixed"))
        // Trace: torso is valid but protected; input shape/existence finishes before
        // protected checks, so the later unknown/duplicate wins over torso protection.
        // When / Then
        compositionError(sut, [.hide(slots: ["torso", "unknown"])], .missingSlot,
                         "/composition/layers/0/slots/1")
        compositionError(sut, [.replace(skin: "empty", slots: ["torso", "torso"])], .invalidSkinComposition,
                         "/composition/layers/0/slots/1")
        compositionError(sut, [.replace(skin: "empty", slots: [])], .invalidSkinComposition,
                         "/composition/layers/0/slots")
    }

    func test_validate_preservesExactNames_andDoesNotNormalizeWhitespaceOrCase() throws {
        // Given
        let (sut, _) = try makeSUT()
        // Trace: requireSkin tests literal membership before examining layer contents.
        // When / Then
        for name in ["base ", " base", "BASE"] {
            compositionError(sut, [], .missingSkin, "/composition/baseSkin", base: name)
        }
        for name in ["HAT/a", "hat/a "] {
            compositionError(sut, [.overlay(skin: name)], .missingSkin, "/composition/layers/0/skin")
        }
    }

    func test_init_copiesLayersAndSlots_andEqualityPreservesSlotOrder() {
        // Given / Trace: value init assigns Swift value arrays; subsequent writes copy
        // storage and synthesized equality compares array elements in order.
        var slots = ["torso", "sleeves"]
        var layers: [SpineSkinLayer] = [.hide(slots: slots)]
        let sut = SpineSkinComposition(baseSkin: "base", layers: layers)
        // When
        slots.reverse()
        layers.append(.overlay(skin: "empty"))
        // Then
        XCTAssertEqual(sut.layers, [.hide(slots: ["torso", "sleeves"])])
        XCTAssertNotEqual(sut, .init(baseSkin: "base", layers: [.hide(slots: slots)]))
        XCTAssertNotEqual(sut, .init(baseSkin: "base", layers: layers))
    }

    private struct Dependencies { let textures: TestMeshTextures }

    private func makeSUT(json: [String: Any]? = nil, file: StaticString = #filePath,
                         line: UInt = #line) throws -> (sut: SpineMeshAsset, deps: Dependencies) {
        let textures = TestMeshTextures()
        let sut = try SpineMeshAsset(json: jsonData(json ?? wardrobeJSON()), textures: textures)
        let initialRequests = textures.requests
        // Compilation is the only operation allowed to request textures. Keep the entire
        // ordered invocation list (including initial calls), never clear it mid-test.
        addTeardownBlock { [weak sut] in
            XCTAssertNil(sut, "Asset should be released", file: file, line: line)
        }
        // Provider is deliberately retained by its invocation assertion until teardown.
        addTeardownBlock { XCTAssertEqual(textures.requests, initialRequests, file: file, line: line) }
        return (sut, Dependencies(textures: textures))
    }
}
#endif
