#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

func compositionHarness(_ json: [String: Any]? = nil) throws -> MeshActionHarness {
    let h = try MeshActionHarness(asset: wardrobeAsset(json))
    try h.skeleton.apply(skin: "base")
    return h
}
let hatA = SpineSkinComposition(baseSkin: "base", layers: [.replace(skin: "hat/a", slots: ["hat-front", "hat-back"])])
let hiddenHat = SpineSkinComposition(baseSkin: "base", layers: [.hide(slots: ["hat-front", "hat-back"])])

final class CompositionTransitionTests: XCTestCase {
    func testUnknownRequestAndSingleSkinFallbackRemainDistinctOnFirstEntry() throws {
        var json = try wardrobeJSON()
        var skins = try XCTUnwrap(json["skins"] as? [[String: Any]])
        for i in [0, 1] {
            var entries = try XCTUnwrap(skins[i]["attachments"] as? [String: [String: Any]])
            entries["hat-front"]?.removeValue(forKey: "side")
            skins[i]["attachments"] = entries
        }
        json["skins"] = skins
        let h = try compositionHarness(json), owner = h.skeleton
        h.start(try owner.action(animation: "walk")); h.advance(0.6)
        XCTAssertNil(h.snapshot.activeAttachments[0])
        XCTAssertEqual(h.snapshot.requestedAttachments[0], "side")
        let before = h.snapshot
        try owner.apply(skinComposition: .init(baseSkin: "base", layers: []))
        XCTAssertEqual(h.snapshot, before)
        try owner.apply(skinComposition: hatA)
        XCTAssertEqual(h.snapshot.activeAttachments[0], "side")
        try owner.apply(skin: "base")
        XCTAssertEqual(h.snapshot.activeAttachments[0], "front")
        XCTAssertEqual(h.snapshot.requestedAttachments[0], "front")
        try owner.apply(skinComposition: hatA)
        XCTAssertEqual(h.snapshot.activeAttachments[0], "front")
    }

    func testSameBaseExitUsesEffectiveSetupFallbackAndSeedsNextRequest() throws {
        let h = try compositionHarness(), owner = h.skeleton
        XCTAssertNil(owner.skinComposition)
        h.start(try owner.action(animation: "walk")); h.advance(0.6)
        XCTAssertEqual(owner.meshRuntime?.slotStates[0].requestedName, "side")
        try owner.apply(skinComposition: hiddenHat)
        XCTAssertEqual(owner.skinComposition, hiddenHat)
        XCTAssertNil(h.snapshot.activeAttachments[0])
        try owner.apply(skin: "base")
        XCTAssertNil(owner.skinComposition)
        XCTAssertEqual(h.snapshot.activeAttachments[0], "front")
        XCTAssertEqual(h.snapshot.requestedAttachments[0], "front")
        let state = owner.meshRuntime?.slotStates[0]
        try owner.apply(skinComposition: .init(baseSkin: "base", layers: []))
        XCTAssertTrue(owner.meshRuntime?.slotStates[0] === state)
        XCTAssertEqual(h.snapshot.activeAttachments[0], "front")
        try owner.apply(skinComposition: hatA)
        XCTAssertEqual(h.snapshot.activeAttachments[0], "front")
        assertMeshError(try owner.apply(skin: "absent"), .missingSkin)
        XCTAssertEqual(owner.skinComposition, hatA)
    }

    func testHideUsesCurrentRequestAndNilSurvivesUnhideWhilePaused() throws {
        let h = try compositionHarness(), owner = h.skeleton
        h.start(try owner.action(animation: "walk"))
        try owner.apply(skinComposition: hiddenHat)
        h.advance(0.6)
        XCTAssertEqual(h.snapshot.requestedAttachments[0], "side")
        XCTAssertNil(h.snapshot.activeAttachments[0])
        owner.isPaused = true
        let time = h.snapshot.time
        try owner.apply(skinComposition: hatA)
        try owner.prepareMeshes(for: validMeshContext)
        XCTAssertEqual(h.snapshot.activeAttachments[0], "side")
        XCTAssertEqual(h.snapshot.time, time)
        owner.isPaused = false; h.advance(0.2)
        XCTAssertNil(h.snapshot.requestedAttachments[0])
        try owner.apply(skinComposition: hiddenHat)
        try owner.apply(skinComposition: hatA)
        XCTAssertNil(h.snapshot.activeAttachments[0])
    }

    func testWrongBaseFollowsContentValidationAndLegacyRejects() throws {
        let owner = try Skeleton(meshAsset: wardrobeAsset(), skin: "base")
        assertMeshError(try owner.apply(skinComposition: .init(baseSkin: "default", layers: [.hide(slots: [])])), .invalidSkinComposition)
        assertMeshError(try owner.apply(skinComposition: .init(baseSkin: "default", layers: [])), .skinCompositionBaseMismatch, path: "/composition/baseSkin")
        XCTAssertNil(owner.skinComposition)
        let legacy = Skeleton(skins: [], animations: [])
        XCTAssertNil(legacy.skinComposition)
        assertMeshError(try legacy.apply(skinComposition: hatA), .unsupportedFeature, path: "/runtime/skinComposition")
    }
}
#endif
