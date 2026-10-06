#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class CompositionMixedBaseTests: XCTestCase {
    func testRegionTransactionPreservesMixedRecordsDeformPointBodyAndPhysicsState() throws {
        var json = try wardrobeJSON("mixed")
        var slots = try XCTUnwrap(json["slots"] as? [[String: Any]])
        slots[2]["attachment"] = "mesh"
        slots += [["name": "fx", "bone": "root", "attachment": "point"], ["name": "hit", "bone": "root", "attachment": "box"]]
        json["slots"] = slots
        var skins = try XCTUnwrap(json["skins"] as? [[String: Any]])
        var entries = try XCTUnwrap(skins[0]["attachments"] as? [String: [String: Any]])
        entries["fx"] = ["point": ["type": "point", "x": 4, "y": 6]]
        entries["hit"] = ["box": ["type": "boundingbox", "vertexCount": 4, "vertices": [0, 0, 16, 0, 16, 16, 0, 16]]]
        skins[0]["attachments"] = entries; json["skins"] = skins
        let h = try compositionHarness(json), owner = h.skeleton
        h.start(try owner.action(animation: "walk")); h.advance(0.4)
        try owner.prepareMeshes(for: validMeshContext)
        let runtime = try XCTUnwrap(owner.meshRuntime), renderer = try XCTUnwrap(runtime.setupRenderer)
        let torso = runtime.slotStates[2], fx = runtime.slotStates[9], hit = runtime.slotStates[10]
        let physics = hit.physics, body = try XCTUnwrap(runtime.slots[10].physicsBody)
        let points = try XCTUnwrap(owner.points)
        let mesh = try XCTUnwrap(renderer.meshNode(named: "mesh", slot: "torso"))
        let linked = try XCTUnwrap(renderer.meshNode(named: "linked", slot: "torso"))
        let region = try XCTUnwrap(renderer.regionNode(named: "front", slot: 2))
        let proxy = region.parent, deformation = torso.deform
        XCTAssertTrue(deformation.contains { $0 != 0 })
        body.categoryBitMask = 123; body.collisionBitMask = 456
        for look in [hatA, hiddenHat, SpineSkinComposition(baseSkin: "base", layers: [])] {
            try owner.apply(skinComposition: look)
            XCTAssertTrue(runtime.setupRenderer === renderer)
            XCTAssertTrue(runtime.slotStates[2] === torso); XCTAssertTrue(runtime.slotStates[9] === fx); XCTAssertTrue(runtime.slotStates[10] === hit)
            XCTAssertTrue(hit.physics === physics)
            XCTAssertTrue(runtime.slots[10].physicsBody === body); XCTAssertTrue(body.node === runtime.slots[10])
            XCTAssertEqual(body.categoryBitMask, 123); XCTAssertEqual(body.collisionBitMask, 456)
            XCTAssertEqual(owner.points?.map(ObjectIdentifier.init), points.map(ObjectIdentifier.init))
            XCTAssertTrue(renderer.meshNode(named: "mesh", slot: "torso") === mesh)
            XCTAssertTrue(renderer.meshNode(named: "linked", slot: "torso") === linked)
            XCTAssertTrue(renderer.regionNode(named: "front", slot: 2) === region); XCTAssertTrue(region.parent === proxy)
            XCTAssertEqual(torso.deform, deformation)
            try owner.prepareMeshes(for: validMeshContext)
        }
    }

    func testProxyChainsAreExtendedAndPrunedWithoutReparentingUntouchedNodes() throws {
        var json = try wardrobeJSON()
        json["bones"] = [["name": "root"], ["name": "hat", "parent": "root"]]
        var slots = try XCTUnwrap(json["slots"] as? [[String: Any]])
        slots[0]["bone"] = "hat"; slots[1]["bone"] = "hat"; json["slots"] = slots
        let owner = try Skeleton(meshAsset: wardrobeAsset(json), skin: "base")
        let runtime = try XCTUnwrap(owner.meshRuntime), renderer = try XCTUnwrap(runtime.setupRenderer)
        let untouched = try XCTUnwrap(renderer.regionNode(named: "front", slot: 2)), parent = untouched.parent
        let baseline = managedNodes(runtime.managedVisuals).count
        for _ in 0..<3 {
            try owner.apply(skinComposition: hiddenHat)
            XCTAssertFalse(managedNodes(runtime.managedVisuals).contains { $0.name == "_spine_render_bone_1" })
            try owner.apply(skinComposition: hatA)
            XCTAssertEqual(managedNodes(runtime.managedVisuals).count, baseline)
            XCTAssertTrue(untouched.parent === parent)
            try owner.prepareMeshes(for: validMeshContext)
        }
    }
}
#endif
