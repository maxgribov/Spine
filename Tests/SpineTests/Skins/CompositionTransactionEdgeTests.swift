#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class CompositionTransactionEdgeTests: XCTestCase {
    private enum Failure: Error { case staged }

    func test_apply_rollsBackAfterSeveralStagedNodes_preservingSharedPhysicsAndRequests() throws {
        // Given: torso owns a live static body, while hats are replaceable regions.
        var json = try wardrobeJSON("mixed")
        var slots = try XCTUnwrap(json["slots"] as? [[String: Any]])
        slots[2]["attachment"] = "box"; json["slots"] = slots
        let h = try compositionHarness(json), owner = h.skeleton
        h.start(try owner.action(animation: "walk")); h.advance(0.6)
        try owner.prepareMeshes(for: validMeshContext)
        let runtime = try XCTUnwrap(owner.meshRuntime)
        let states = runtime.slotStates, physics = states.map(\.physics)
        let body = try XCTUnwrap(runtime.slots[2].physicsBody)
        let snapshot = runtime.snapshot, nodes = managedNodes(runtime.managedVisuals)
        let ids = states.map(\.attachmentID), sources = states.map(\.deformSourceID)
        let provenance = physics.map(\.hasProvenance)
        weak var firstStaged: SKNode?
        var stagedNames: [String?] = []
        runtime.compositionStageCheck = { node in
            stagedNames.append(node.name)
            if firstStaged == nil { firstStaged = node }
            else { throw Failure.staged }
        }
        // Trace: resolve -> copy changed states sharing physics -> stage two nodes ->
        // throw before commit. No live state/physics write occurs, staged tree releases.
        // When
        XCTAssertThrowsError(try autoreleasepool { try owner.apply(skinComposition: hatA) }) {
            guard case Failure.staged = $0 else { return XCTFail("Wrong error: \($0)") }
        }
        runtime.compositionStageCheck = nil
        // Then
        XCTAssertEqual(stagedNames, ["attachment:front", "attachment:side"])
        XCTAssertNil(firstStaged)
        XCTAssertNil(owner.skinComposition)
        XCTAssertEqual(runtime.snapshot, snapshot)
        XCTAssertEqual(runtime.slotStates.map(ObjectIdentifier.init), states.map(ObjectIdentifier.init))
        XCTAssertEqual(runtime.slotStates.map(\.attachmentID), ids)
        XCTAssertEqual(runtime.slotStates.map(\.deformSourceID), sources)
        XCTAssertEqual(runtime.slotStates.map { ObjectIdentifier($0.physics) }, physics.map(ObjectIdentifier.init))
        XCTAssertEqual(physics.map(\.hasProvenance), provenance)
        XCTAssertTrue(physics[2].expectedBody === body)
        XCTAssertTrue(body.node === runtime.slots[2])
        XCTAssertEqual(managedNodes(runtime.managedVisuals).map(ObjectIdentifier.init), nodes.map(ObjectIdentifier.init))
        // A subsequent valid transaction confirms staging did not poison the live renderer.
        try owner.apply(skinComposition: hatA)
        try owner.prepareMeshes(for: validMeshContext)
        XCTAssertTrue(runtime.slots[2].physicsBody === body)
    }

    func test_applyAfterPrepare_refreshesCurrentAttachmentAndReorderedDepth_onRepeatedPrepare() throws {
        // Given: walk selected side and swapped hat-front/hat-back at t=0.5.
        let h = try compositionHarness(), owner = h.skeleton
        h.start(try owner.action(animation: "walk")); h.advance(0.6)
        try owner.prepareMeshes(for: validMeshContext)
        let runtime = try XCTUnwrap(owner.meshRuntime), snapshot = runtime.snapshot
        // Trace: composition commits new regions without sampling; a second prepare
        // consumes preserved active requests and current draw ranks for the new nodes.
        // When
        try owner.apply(skinComposition: hatA)
        try owner.prepareMeshes(for: validMeshContext)
        // Then
        let front = try XCTUnwrap(runtime.setupRenderer?.regionNode(named: "front", slot: 0))
        let side = try XCTUnwrap(runtime.setupRenderer?.regionNode(named: "side", slot: 0))
        let back = try XCTUnwrap(runtime.setupRenderer?.regionNode(named: "front", slot: 1))
        XCTAssertTrue(front.isHidden); XCTAssertFalse(side.isHidden)
        XCTAssertGreaterThan(side.zPosition, back.zPosition)
        XCTAssertEqual(side.zPosition, CGFloat(Float(1.0 / Double(runtime.slots.count))))
        XCTAssertEqual(runtime.snapshot, snapshot)
    }

    func test_apply_preservesUntouchedRegionIdentity_whenAnotherSlotRequestChanges() throws {
        // Given
        let h = try compositionHarness(), owner = h.skeleton
        h.start(try owner.action(animation: "walk")); h.advance(0.6)
        let runtime = try XCTUnwrap(owner.meshRuntime)
        let untouchedState = runtime.slotStates[0]
        let untouchedNode = try XCTUnwrap(runtime.setupRenderer?.regionNode(named: "side", slot: 0))
        let parent = untouchedNode.parent
        // Trace: torso/sleeves are the only touched slots; hat's already-sampled side
        // request, slot state and region record bypass copying and replacement.
        // When
        try owner.apply(skinComposition: .init(baseSkin: "base", layers: [.overlay(skin: "clothes/a")]))
        try owner.prepareMeshes(for: validMeshContext)
        // Then
        XCTAssertTrue(runtime.slotStates[0] === untouchedState)
        XCTAssertEqual(untouchedState.requestedName, "side")
        XCTAssertEqual(untouchedState.activeName, "side")
        XCTAssertTrue(runtime.setupRenderer?.regionNode(named: "side", slot: 0) === untouchedNode)
        XCTAssertTrue(untouchedNode.parent === parent)
        XCTAssertFalse(untouchedNode.isHidden)
    }

    func test_firstEntry_preservesProtectedSingleSkinFallback_forEmptyAndOtherSlotLayers() throws {
        // Given: base has torso side; default does not, so switching to default must
        // fall back to setup box and synchronize the logical request to that box.
        var json = try wardrobeJSON("mixed")
        var slots = try XCTUnwrap(json["slots"] as? [[String: Any]])
        slots[2]["attachment"] = "box"; json["slots"] = slots
        var skins = try XCTUnwrap(json["skins"] as? [[String: Any]])
        var entries = try XCTUnwrap(skins[0]["attachments"] as? [String: [String: Any]])
        entries["torso"]?.removeValue(forKey: "side")
        skins[0]["attachments"] = entries; json["skins"] = skins
        json["animations"] = ["pose": ["slots": ["torso": ["attachment": [
            ["time": 0, "name": "side"], ["time": 1, "name": "side"]
        ]]]]]
        for layers: [SpineSkinLayer] in [[], [.replace(skin: "hat/a", slots: ["hat-front", "hat-back"])]] {
            let h = try compositionHarness(json), owner = h.skeleton
            h.start(try owner.action(animation: "pose")); h.advance(0.3)
            XCTAssertEqual(h.snapshot.activeAttachments[2], "side")
            XCTAssertEqual(h.snapshot.requestedAttachments[2], "side")
            try owner.apply(skin: "default")
            let runtime = try XCTUnwrap(owner.meshRuntime)
            let state = runtime.slotStates[2], physics = state.physics
            let body = try XCTUnwrap(runtime.slots[2].physicsBody)
            let snapshot = runtime.snapshot
            let region = try XCTUnwrap(runtime.setupRenderer?.regionNode(named: "front", slot: 2))
            let mesh = try XCTUnwrap(runtime.setupRenderer?.meshNode(named: "mesh", slot: "torso"))
            let parent = region.parent
            XCTAssertEqual(state.activeName, "box")
            XCTAssertEqual(state.requestedName, "box")
            // Trace: applySkin cannot resolve side -> selects setup box -> seeds request;
            // first composition resolves content but changed slots exclude protected torso.
            // No sample occurs and its renderer/state/body must retain exact identity.
            // When
            try owner.apply(skinComposition: .init(baseSkin: "default", layers: layers))
            // Then
            XCTAssertEqual(runtime.snapshot, snapshot)
            XCTAssertTrue(runtime.slotStates[2] === state)
            XCTAssertEqual(state.activeName, "box")
            XCTAssertEqual(state.requestedName, "box")
            XCTAssertTrue(state.physics === physics)
            XCTAssertTrue(physics.expectedBody === body)
            XCTAssertTrue(runtime.slots[2].physicsBody === body)
            XCTAssertTrue(body.node === runtime.slots[2])
            XCTAssertTrue(runtime.setupRenderer?.regionNode(named: "front", slot: 2) === region)
            XCTAssertTrue(runtime.setupRenderer?.meshNode(named: "mesh", slot: "torso") === mesh)
            XCTAssertTrue(region.parent === parent)
        }
    }

    func test_apply_isolatesOwnersSharingAsset_andDoesNotRequestTextures() throws {
        // Given
        let textures = TestMeshTextures()
        let asset = try SpineMeshAsset(json: jsonData(wardrobeJSON()), textures: textures)
        let requests = textures.requests
        let first = try Skeleton(meshAsset: asset, skin: "base")
        let second = try Skeleton(meshAsset: asset, skin: "base")
        let other = try XCTUnwrap(second.meshRuntime), before = other.snapshot
        let otherNodes = managedNodes(other.managedVisuals).map(ObjectIdentifier.init)
        // Trace: apply modifies only first owner's records, states and descriptor;
        // resource handles are reused from the immutable asset.
        // When
        try first.apply(skinComposition: hiddenHat)
        try first.prepareMeshes(for: validMeshContext)
        // Then
        XCTAssertNil(second.skinComposition)
        XCTAssertEqual(other.snapshot, before)
        XCTAssertEqual(managedNodes(other.managedVisuals).map(ObjectIdentifier.init), otherNodes)
        XCTAssertEqual(textures.requests, requests)
        XCTAssertEqual(first.skinComposition, hiddenHat)
    }
}
#endif
