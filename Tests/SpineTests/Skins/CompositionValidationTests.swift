#if os(macOS) || os(iOS)
import XCTest
@testable import Spine

final class CompositionValidationTests: XCTestCase {
    func testEachIntroducedTypeIsCheckedBeforeCompleteness() throws {
        for (name, kind) in [("mesh", "mesh"), ("linked", "linkedMesh"), ("point", "point"), ("box", "boundingBox")] {
            var json = try wardrobeJSON("mixed")
            var skins = try XCTUnwrap(json["skins"] as? [[String: Any]])
            let defaults = try XCTUnwrap(skins[0]["attachments"] as? [String: [String: Any]])
            let value = try XCTUnwrap(defaults["torso"]?[name])
            // A separate unprotected region slot introduces the tested type.
            // Linked meshes resolve their parent within the same slot.
            var attachments: [String: Any] = [name: value]
            if name == "linked" { attachments["mesh"] = defaults["torso"]?["mesh"] }
            skins.append(["name": "invalid", "attachments": ["empty": attachments]])
            if name == "linked" {
                var link = try XCTUnwrap(attachments[name] as? [String: Any])
                link["skin"] = "invalid"; attachments[name] = link
                skins[skins.count - 1]["attachments"] = ["empty": attachments]
            }
            json["skins"] = skins
            let asset = try wardrobeAsset(json)
            compositionError(asset, [.replace(skin: "invalid", slots: ["empty", "hat-front"])], .unsupportedFeature,
                             "/composition/layers/0/attachments/empty/\(name)", message: kind)
            compositionError(asset, [.overlay(skin: "invalid"), .hide(slots: ["empty"])], .unsupportedFeature,
                             "/composition/layers/0/attachments/empty/\(name)", message: kind)
            compositionError(asset, [.replace(skin: "invalid", slots: ["empty", "torso"])], .unsupportedFeature,
                             "/composition/layers/0/slots/torso")
        }
    }

    func testEveryReplaceMustCoverEveryClipEvenWhenHiddenLater() throws {
        let asset = try wardrobeAsset()
        compositionError(asset, [.replace(skin: "partial", slots: ["hat-front"]), .hide(slots: ["hat-front"])],
                         .incompleteSkinComposition, "/composition/layers/0/attachments/hat-front/side", message: "walk")
        compositionError(asset, [.replace(skin: "empty", slots: ["hat-front"])],
                         .incompleteSkinComposition, "/composition/layers/0/attachments/hat-front/front", message: "setup")
        XCTAssertNoThrow(try asset.validate(skinComposition: .init(baseSkin: "base", layers: [.replace(skin: "empty", slots: ["empty"])])))
        var json = try wardrobeJSON()
        var animations = try XCTUnwrap(json["animations"] as? [String: Any])
        animations["rare"] = ["slots": ["s/~": ["attachment": [["time": 0, "name": "a/~"]]]]]
        animations["alpha"] = animations["rare"]
        json["animations"] = animations
        let changed = try wardrobeAsset(json)
        compositionError(changed, [.replace(skin: "empty", slots: ["s/~"])], .incompleteSkinComposition,
                         "/composition/layers/0/attachments/s~1~0/a~1~0", message: "alpha")
        XCTAssertNoThrow(try asset.validate(skinComposition: .init(baseSkin: "base", layers: [.replace(skin: "empty", slots: ["s/~"])])))
    }

    func testProtectedInactiveStatesAndNoOpOverlaysAreRejected() throws {
        let asset = try wardrobeAsset(wardrobeJSON("mixed"))
        compositionError(asset, [.hide(slots: ["torso"])], .unsupportedFeature, "/composition/layers/0/slots/torso")
        compositionError(asset, [.overlay(skin: "base")], .unsupportedFeature, "/composition/layers/0/slots/torso")
    }

    func testUnselectedTypesIgnoredAndOverrideCanUnprotectBase() throws {
        var json = try wardrobeJSON("mixed")
        let asset = try wardrobeAsset(json)
        XCTAssertNoThrow(try asset.validate(skinComposition: .init(baseSkin: "base", layers: [.replace(skin: "default", slots: ["hat-front"])])))
        var skins = try XCTUnwrap(json["skins"] as? [[String: Any]])
        var base = try XCTUnwrap(skins[1]["attachments"] as? [String: [String: Any]])
        var torso = try XCTUnwrap(base["torso"])
        for name in ["mesh", "linked", "chain", "point", "box"] { torso[name] = ["type": "region", "path": "swatch", "width": 16, "height": 16] }
        base["torso"] = torso; skins[1]["attachments"] = base; json["skins"] = skins
        let unprotected = try wardrobeAsset(json)
        XCTAssertNoThrow(try unprotected.validate(skinComposition: .init(baseSkin: "base", layers: [.hide(slots: ["torso"])])))
        compositionError(unprotected, [.overlay(skin: "default"), .hide(slots: ["torso"])], .unsupportedFeature,
                         "/composition/layers/0/attachments/torso/box", message: "boundingBox")
    }
}
#endif
