#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class CompositionPlaybackTests: XCTestCase {
    func testRepeatBeginEndAndBothStopsKeepCompositionAndResetOnlyAnimationState() throws {
        let h = try compositionHarness(compositionEventJSON()), owner = h.skeleton
        defer { owner.eventTriggered = nil }
        try owner.apply(skinComposition: hiddenHat)
        var events: [Int] = []
        owner.eventTriggered = { event in
            events.append(event.int)
            XCTAssertEqual(owner.skinComposition, hiddenHat)
            XCTAssertNil(owner.meshRuntime?.slotStates[0].activeName)
        }
        h.start(.repeat(try owner.action(animation: "walk"), count: 2)); h.advance(2.3)
        XCTAssertEqual(events, [0, 1, 2, 3, 4, 0, 1, 2, 3, 4])
        XCTAssertEqual(h.snapshot.beginCount, 2); XCTAssertEqual(h.snapshot.endCount, 2)
        XCTAssertEqual(owner.skinComposition, hiddenHat)
        h.start(try owner.action(animation: "walk")); h.advance(0.6)
        let frozen = h.snapshot, color = owner.meshRuntime?.slotStates.map(\.color)
        owner.stopMeshAnimation(resetToSetupPose: false); owner.removeAction(forKey: "clip")
        XCTAssertEqual(h.snapshot.requestedAttachments, frozen.requestedAttachments)
        XCTAssertEqual(h.snapshot.activeAttachments, frozen.activeAttachments)
        XCTAssertEqual(h.snapshot.time, frozen.time); XCTAssertEqual(owner.meshRuntime?.slotStates.map(\.color), color)
        XCTAssertEqual(owner.skinComposition, hiddenHat)
        owner.stopMeshAnimation(resetToSetupPose: true)
        XCTAssertEqual(owner.skinComposition, hiddenHat)
        XCTAssertEqual(h.snapshot.requestedAttachments[0], "front"); XCTAssertNil(h.snapshot.activeAttachments[0])
        XCTAssertEqual(h.snapshot.drawOrder, Array(0..<9)); XCTAssertEqual(h.snapshot.time, 0)
        try owner.apply(skinComposition: hatA)
        XCTAssertEqual(h.snapshot.activeAttachments[0], "front")
    }

    func testSingleSkinActionAndDefaultExitEvenWhenBaseNameMatches() throws {
        let h = try compositionHarness(), owner = h.skeleton
        try owner.apply(skinComposition: hiddenHat)
        h.start(try owner.action(applySkin: "base")); h.advance(0.1)
        XCTAssertNil(owner.skinComposition); XCTAssertEqual(h.snapshot.activeAttachments[0], "front")
        try owner.applyDefaultSkin()
        try owner.apply(skinComposition: .init(baseSkin: "default", layers: [.hide(slots: ["earring"])]))
        try owner.applyDefaultSkin()
        XCTAssertNil(owner.skinComposition); XCTAssertEqual(h.snapshot.requestedAttachments[5], "front")
    }
}
#endif
