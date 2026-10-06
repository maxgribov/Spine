#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

func compositionEventJSON() throws -> [String: Any] {
    var json = try wardrobeJSON()
    var animations = try XCTUnwrap(json["animations"] as? [String: [String: Any]])
    animations["walk"]?["events"] = [
        ["time": 0, "name": "change", "int": 0],
        ["time": 0.5, "name": "change", "int": 1],
        ["time": 0.5, "name": "change", "int": 2],
        ["time": 1, "name": "change", "int": 3],
        ["time": 1, "name": "change", "int": 4]
    ]
    animations["next"] = ["events": [["time": 0, "name": "change", "int": 9], ["time": 0.2, "name": "change", "int": 10]]]
    json["animations"] = animations
    return json
}

final class CompositionEventTests: XCTestCase {
    func testSameTimeAndFinalCallbacksObserveLatestSuccessfulCompositionOnce() throws {
        let h = try compositionHarness(compositionEventJSON()), owner = h.skeleton
        defer { owner.eventTriggered = nil }
        var events: [Int] = [], completions = 0
        owner.eventTriggered = { event in
            events.append(event.int)
            do {
                let before = h.snapshot
                if event.int == 1 || event.int == 3 {
                    try owner.apply(skinComposition: hiddenHat)
                    assertMeshError(try owner.apply(skinComposition: .init(baseSkin: "base", layers: [.hide(slots: [])])), .invalidSkinComposition)
                    XCTAssertEqual(owner.skinComposition, hiddenHat)
                    try owner.apply(skinComposition: hatA)
                } else if event.int == 2 || event.int == 4 {
                    XCTAssertEqual(owner.skinComposition, hatA)
                    XCTAssertEqual(owner.meshRuntime?.slotStates[0].activeName, event.int == 2 ? "side" : "front")
                }
                XCTAssertEqual(h.snapshot.epoch, before.epoch)
                XCTAssertEqual(h.snapshot.executionID, before.executionID)
                XCTAssertEqual(h.snapshot.time, before.time)
                XCTAssertEqual(h.snapshot.nextEvent, before.nextEvent)
                XCTAssertEqual(h.snapshot.attachmentCursors, before.attachmentCursors)
            } catch { XCTFail("Callback apply failed: \(error)") }
        }
        h.start(.sequence([try owner.action(animation: "walk"), .run { completions += 1 }]))
        h.advance(1.2); h.advance(0.2)
        XCTAssertEqual(events, [0, 1, 2, 3, 4])
        XCTAssertEqual(completions, 1); XCTAssertEqual(h.snapshot.endCount, 1)
        XCTAssertNil(h.snapshot.executionID); XCTAssertNil(owner.meshPlaybackError)
    }

    func testStopAndRestartFromSameTimeOrFinalEventInvalidatesOnlyOldExecution() throws {
        for trigger in [1, 3] {
            let h = try compositionHarness(compositionEventJSON()), owner = h.skeleton
            defer { owner.eventTriggered = nil }
            var events: [Int] = []
            owner.eventTriggered = { event in
                events.append(event.int)
                if event.int == trigger {
                    do {
                        try owner.apply(skinComposition: hiddenHat)
                        owner.stopMeshAnimation(resetToSetupPose: true)
                        owner.removeAction(forKey: "clip")
                        try owner.apply(skinComposition: hatA)
                        owner.run(try owner.action(animation: "next"), withKey: "replacement")
                    } catch { XCTFail("Restart failed: \(error)") }
                }
            }
            h.start(try owner.action(animation: "walk")); h.advance(1.5)
            XCTAssertEqual(events, trigger == 1 ? [0, 1, 9, 10] : [0, 1, 2, 3, 9, 10])
            XCTAssertEqual(h.snapshot.beginCount, 2); XCTAssertEqual(h.snapshot.endCount, 1)
            XCTAssertEqual(owner.skinComposition, hatA); XCTAssertNil(owner.meshPlaybackError)
            XCTAssertNil(h.snapshot.executionID)
        }
    }

    func testCallbacksAtNilKeyPreserveHiddenRequestAcrossSuccessAndFailure() throws {
        // Given: both callbacks happen after attachment sampling has selected nil.
        var json = try wardrobeJSON()
        var animations = try XCTUnwrap(json["animations"] as? [String: [String: Any]])
        animations["walk"]?["events"] = [["time": 0.75, "name": "change", "int": 1],
                                          ["time": 0.75, "name": "change", "int": 2]]
        json["animations"] = animations
        let h = try compositionHarness(json), owner = h.skeleton
        defer { owner.eventTriggered = nil }
        var events: [Int] = []
        owner.eventTriggered = { event in
            events.append(event.int)
            // Trace: attachment timeline samples nil -> event cursor advances -> apply
            // resolves nil with no fallback. A failed last apply keeps the prior outfit.
            do {
                if event.int == 1 {
                    try owner.apply(skinComposition: hiddenHat)
                    try owner.apply(skinComposition: hatA)
                    assertMeshError(try owner.apply(skinComposition: .init(baseSkin: "base", layers: [.hide(slots: [])])), .invalidSkinComposition)
                }
                XCTAssertEqual(owner.skinComposition, hatA)
                XCTAssertNil(owner.meshRuntime?.slotStates[0].requestedName)
                XCTAssertNil(owner.meshRuntime?.slotStates[0].activeName)
            } catch { XCTFail("Callback apply failed: \(error)") }
        }
        // When
        h.start(try owner.action(animation: "walk")); h.advance(0.8)
        // Then
        XCTAssertEqual(events, [1, 2])
        XCTAssertNil(owner.meshPlaybackError)
        try owner.prepareMeshes(for: validMeshContext)
        XCTAssertTrue(try XCTUnwrap(owner.meshRuntime?.setupRenderer?.regionNode(named: "front", slot: 0)).isHidden)
        XCTAssertTrue(try XCTUnwrap(owner.meshRuntime?.setupRenderer?.regionNode(named: "side", slot: 0)).isHidden)
    }

    func testZeroDurationEqualEventsApplyCompositionAndCompleteOnce() throws {
        // Given: all events are both begin and final events of a zero-length clip.
        var json = try wardrobeJSON()
        json["animations"] = ["instant": ["events": [["time": 0, "name": "change", "int": 1],
                                                     ["time": 0, "name": "change", "int": 2]]]]
        let h = try compositionHarness(json), owner = h.skeleton
        defer { owner.eventTriggered = nil }
        var events: [Int] = [], completions = 0
        owner.eventTriggered = { event in
            events.append(event.int)
            do { try owner.apply(skinComposition: event.int == 1 ? hiddenHat : hatA) }
            catch { XCTFail("Instant callback failed: \(error)") }
        }
        // Trace: begin samples both time-zero events, advancing cursor before each
        // callback; end samples zero again but the consumed cursor prevents replay.
        // When
        h.start(.sequence([try owner.action(animation: "instant"), .run { completions += 1 }]))
        h.advance(0.2)
        // Then
        XCTAssertEqual(events, [1, 2])
        XCTAssertEqual(completions, 1)
        XCTAssertEqual(h.snapshot.beginCount, 1)
        XCTAssertEqual(h.snapshot.endCount, 1)
        XCTAssertNil(h.snapshot.executionID)
        XCTAssertEqual(owner.skinComposition, hatA)
    }

    func testEventTimestampsRemainValidatedAndNonEventDuplicatesRemainInvalid() throws {
        var json = try compositionEventJSON()
        var animations = try XCTUnwrap(json["animations"] as? [String: [String: Any]])
        animations["walk"]?["events"] = [["time": 0.5, "name": "change"], ["time": 0.4, "name": "change"]]
        json["animations"] = animations
        try expectMeshLoadError(json, .invalidTimeline, path: "/animations/walk/events/1/time")
        XCTAssertThrowsError(try MeshClip(name: "events", channels: [], events: [meshEvent(0.5, 1), meshEvent(0.4, 2)]))
        XCTAssertNoThrow(try MeshClip(name: "events", channels: [], events: [meshEvent(0, 1), meshEvent(0, 2)]))
        for time in [-1.0, Double.infinity, Double.nan] {
            XCTAssertThrowsError(try MeshClip(name: "events", channels: [], events: [meshEvent(time, 1)]))
        }
        animations["walk"]?["events"] = [["time": -1, "name": "change"]]
        json["animations"] = animations
        try expectMeshLoadError(json, .invalidTimeline, path: "/animations/walk/events/0/time")
        let validSource = String(decoding: try jsonData(json), as: UTF8.self)
        let overflowSource = validSource.replacingOccurrences(of: "\"time\":-1", with: "\"time\":1e100")
        let textures = TestMeshTextures()
        assertMeshError(try SpineMeshAsset(json: Data(overflowSource.utf8), textures: textures).validate(skinComposition: hatA),
                        .invalidTimeline, path: "/animations/walk/events/0/time")
        XCTAssertTrue(textures.requests.isEmpty)
        animations["walk"]?["events"] = []
        animations["walk"]?["slots"] = ["hat-front": ["attachment": [["time": 0, "name": "front"], ["time": 0, "name": "side"]]]]
        json["animations"] = animations
        try expectMeshLoadError(json, .invalidTimeline, path: "/animations/walk/slots/hat-front/attachment/1/time")
    }
}
#endif
