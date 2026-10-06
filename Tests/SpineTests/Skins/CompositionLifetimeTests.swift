#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class CompositionLifetimeTests: XCTestCase {
    func testThousandAlternationsAndExactRepeatsReleaseRegionsAndKeepResourceCounts() throws {
        let textures = TestMeshTextures()
        var json = try wardrobeJSON("mixed")
        // A dedicated hat chain must disappear entirely on hide, not merely keep
        // a constant root proxy that would conceal accumulation of unused branches.
        json["bones"] = [["name": "root"], ["name": "hat", "parent": "root"]]
        var slots = try XCTUnwrap(json["slots"] as? [[String: Any]])
        slots[0]["bone"] = "hat"; slots[1]["bone"] = "hat"
        slots.append(["name": "static", "bone": "root", "attachment": "box"]); json["slots"] = slots
        var skins = try XCTUnwrap(json["skins"] as? [[String: Any]])
        var entries = try XCTUnwrap(skins[0]["attachments"] as? [String: [String: Any]])
        entries["static"] = ["box": ["type": "boundingbox", "vertexCount": 4, "vertices": [0, 0, 16, 0, 16, 16, 0, 16]]]
        skins[0]["attachments"] = entries; json["skins"] = skins
        let asset = try SpineMeshAsset(json: jsonData(json), textures: textures)
        let owner = try Skeleton(meshAsset: asset, skin: "base"), other = try Skeleton(meshAsset: asset, skin: "base")
        let runtime = try XCTUnwrap(owner.meshRuntime)
        let resources = asset.rendererResources, compileCount = MeshAssetCompiler.compilationCount, requests = textures.requests
        let body = try XCTUnwrap(owner.slotNode(named: "static")?.physicsBody)
        let otherNodes = managedNodes(other).map(ObjectIdentifier.init), otherSnapshot = other.meshRuntime?.snapshot
        let a = hatA, b = hiddenHat
        func apply(_ look: SpineSkinComposition) throws {
            try owner.apply(skinComposition: look); try owner.prepareMeshes(for: validMeshContext)
        }
        for i in 0..<100 { try autoreleasepool { try apply(i.isMultiple(of: 2) ? a : b) } }
        var expected: [Int] = [], hiddenNodes = 0
        try autoreleasepool {
            try apply(a)
            let nodes = managedNodes(owner)
            expected = [nodes.count, nodes.filter { $0.name?.hasPrefix("_spine_render_bone_") == true }.count, nodes.filter { $0.physicsBody != nil }.count]
            try apply(b)
            hiddenNodes = managedNodes(owner).count
        }
        for _ in 0..<500 {
            weak var old: SKNode?, oldSide: SKNode?, oldProxy: SKNode?
            try autoreleasepool {
                try apply(a)
                let nodes = managedNodes(owner)
                XCTAssertEqual([nodes.count, nodes.filter { $0.name?.hasPrefix("_spine_render_bone_") == true }.count, nodes.filter { $0.physicsBody != nil }.count], expected)
                old = runtime.setupRenderer?.regionNode(named: "front", slot: 0)
                oldSide = runtime.setupRenderer?.regionNode(named: "side", slot: 0)
                oldProxy = old?.parent
                // Trace: hide commits removal of every hat record, computes needed
                // proxies from remaining records and prunes the dedicated hat branch.
                try apply(b)
                XCTAssertEqual(managedNodes(owner).count, hiddenNodes)
            }
            XCTAssertNil(old); XCTAssertNil(oldSide); XCTAssertNil(oldProxy)
        }
        try autoreleasepool { try apply(a) }
        let sameNodes = managedNodes(owner).map(ObjectIdentifier.init), snapshot = runtime.snapshot
        runtime.compositionStageCheck = { _ in XCTFail("Repeated descriptor staged a node") }
        defer { runtime.compositionStageCheck = nil }
        for _ in 0..<1000 { try autoreleasepool { try apply(a) } }
        XCTAssertEqual(managedNodes(owner).map(ObjectIdentifier.init), sameNodes)
        XCTAssertEqual(runtime.snapshot, snapshot)
        XCTAssertEqual(MeshAssetCompiler.compilationCount, compileCount); XCTAssertEqual(textures.requests, requests)
        XCTAssertTrue(asset.rendererResources === resources)
        XCTAssertTrue(owner.slotNode(named: "static")?.physicsBody === body)
        XCTAssertEqual(managedNodes(other).map(ObjectIdentifier.init), otherNodes)
        XCTAssertEqual(other.meshRuntime?.snapshot, otherSnapshot); XCTAssertNil(other.skinComposition)
    }

    func testDifferentSlotOrderIsStructuralChangeAndSharedAssetOutlivesOneOwner() throws {
        weak var released: Skeleton?
        let asset = try wardrobeAsset(), other = try Skeleton(meshAsset: asset, skin: "base")
        try autoreleasepool {
            let owner = try Skeleton(meshAsset: asset, skin: "base"); released = owner
            try owner.apply(skinComposition: hatA)
            let old = owner.meshRuntime?.setupRenderer?.regionNode(named: "front", slot: 0)
            let reordered = SpineSkinComposition(baseSkin: "base", layers: [.replace(skin: "hat/a", slots: ["hat-back", "hat-front"])])
            XCTAssertNotEqual(hatA, reordered)
            try owner.apply(skinComposition: reordered)
            XCTAssertEqual(owner.skinComposition, reordered)
            XCTAssertNil(old?.parent)
        }
        XCTAssertNil(released)
        try other.apply(skinComposition: hatA); try other.prepareMeshes(for: validMeshContext)
    }
}
#endif
