#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class NodeBridgeTests:XCTestCase {
    func testPrepareRefreshesRegionFilteringAndReplacementTexturePixelSize()throws {
        let skeleton=try Skeleton(meshAsset:authoredAsset("deform-resources"))
        let region=try XCTUnwrap(skeleton.regionAttachmentNode(named:"region"))
        let shader=try XCTUnwrap(region.shader)
        let replacement=SKTexture(data:Data(repeating:255,count:8*16*4),size:CGSize(width:8,height:16))
        region.texture=replacement

        // prepare must read the current primary texture, not immutable atlas metadata.
        for filtering in [SKTextureFilteringMode.linear,.nearest,.linear] {
            replacement.filteringMode=filtering
            try skeleton.prepareMeshes(for:validMeshContext)
            XCTAssertEqual(region.value(forAttributeNamed:"a_pixelSize")?.vectorFloat2Value,SIMD2<Float>(8,16))
            XCTAssertEqual(region.value(forAttributeNamed:"a_nearest")?.floatValue,filtering == .nearest ? 1:0)
            XCTAssertTrue(region.texture === replacement)
            XCTAssertTrue(region.shader === shader)
        }
    }

    func testManualBoneUpdateAndSkeletonTransformAreAppliedOnce()throws {
        let skeleton=try Skeleton(meshAsset:authoredAsset("weighted-link"))
        skeleton.position=CGPoint(x:1000,y:2000);skeleton.setScale(3)
        try skeleton.prepareMeshes(for:validMeshContext)
        let before=skeleton.meshRuntime!.setupRenderer!.snapshot.vertices[0]
        skeleton.boneNode(named:"root")!.position.x += 10
        try skeleton.prepareMeshes(for:validMeshContext)
        let after=skeleton.meshRuntime!.setupRenderer!.snapshot.vertices[0]
        // Weights sum to 1.1, deliberately not normalized; Skeleton TRS is excluded.
        for (a,b) in zip(before,after) {XCTAssertEqual(b.x-a.x,11,accuracy:1e-4);XCTAssertEqual(b.y,a.y,accuracy:1e-4)}
    }
    func testMeshAndRegionUseSameInheritedAlphaAndVisibility()throws {
        let skeleton=try Skeleton(meshAsset:authoredAsset("deform-resources"))
        skeleton.alpha=0.7;skeleton.boneNode(named:"root")!.alpha=0.5;skeleton.boneNode(named:"child")!.alpha=0.4
        skeleton.slotNode(named:"mesh")!.alpha=0.3;skeleton.slotNode(named:"region")!.alpha=0.3
        try skeleton.prepareMeshes(for:validMeshContext)
        let mesh=try XCTUnwrap(skeleton.meshAttachmentNode(named:"mesh",inSlot:"mesh")),region=try XCTUnwrap(skeleton.regionAttachmentNode(named:"region"))
        XCTAssertEqual(mesh.alpha,0.06,accuracy:1e-6)
        XCTAssertEqual(region.alpha,0.3,accuracy:1e-6)
        XCTAssertEqual(region.parent?.alpha ?? 0,0.4,accuracy:1e-6)
        XCTAssertEqual(region.parent?.parent?.alpha ?? 0,0.5,accuracy:1e-6)
        skeleton.boneNode(named:"root")!.isHidden=true
        try skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertTrue(mesh.isHidden);XCTAssertTrue(region.isHidden)
    }
    func testSlotHierarchyDepthAndNonfinitePoseFailuresHideAndRecover()throws {
        let skeleton=try Skeleton(meshAsset:authoredAsset("deform-resources"))
        try skeleton.prepareMeshes(for:validMeshContext)
        let slot=skeleton.slotNode(named:"mesh")!,bone=skeleton.boneNode(named:"root")!,renderer=skeleton.meshRuntime!.managedVisuals
        slot.position.x=1
        assertMeshError(try skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract)
        XCTAssertTrue(renderer.isHidden);slot.position = .zero
        slot.zPosition=2
        assertMeshError(try skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract)
        slot.zPosition=0
        bone.removeFromParent();renderer.addChild(bone)
        assertMeshError(try skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract)
        bone.removeFromParent();skeleton.addChild(bone)
        let before=skeleton.meshRuntime!.setupRenderer!.snapshot.vertices
        bone.xScale = .nan
        assertMeshError(try skeleton.prepareMeshes(for:validMeshContext),.invalidGeometry,path:"/runtime/nodes/root")
        XCTAssertEqual(skeleton.meshRuntime!.setupRenderer!.snapshot.vertices,before)
        bone.xScale=1
        try skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertFalse(renderer.isHidden)
    }
    func testLoadedMultislotResetPreservesMeshDepthAndRemovesDescendantActions()throws {
        let h=try MeshActionHarness(asset:authoredAsset("deform-resources"))
        let child=try XCTUnwrap(h.skeleton.boneNode(named:"child"))
        child.run(.moveBy(x:50,y:30,duration:2),withKey:"bone-action")
        h.skeleton.run(.wait(forDuration:5),withKey:"ordinary")
        h.advance(0.2)
        let epoch=h.snapshot.epoch
        h.start(h.skeleton.dropToDefaultsAction(),key:"reset");h.advance(0.1)
        XCTAssertEqual(h.snapshot.epoch,epoch+1)
        XCTAssertFalse(child.hasActions());XCTAssertFalse(h.skeleton.hasActions())
        XCTAssertEqual(child.position,CGPoint(x:20,y:10))
        XCTAssertGreaterThan(h.skeleton.meshRuntime!.slots.count,1)
        XCTAssertTrue(h.skeleton.meshRuntime!.slots.allSatisfy {$0.zPosition==0})
        XCTAssertNoThrow(try h.skeleton.prepareMeshes(for:validMeshContext))
        XCTAssertFalse(h.skeleton.meshRuntime!.managedVisuals.isHidden)
    }

    func testRegionPointAndPhysicsAreRealNodesInTheirLogicalSlots()throws {
        let skeleton=try Skeleton(meshAsset:authoredAsset("deform-resources"))
        XCTAssertNotNil(skeleton.regionAttachmentNode(named:"region"))
        XCTAssertNil(skeleton.regionAttachmentNode(named:"mesh"))
        XCTAssertEqual(skeleton.points?.count,1);XCTAssertEqual(skeleton.activePoints?.count,1)
        XCTAssertTrue(skeleton.points?.first?.parent === skeleton.slotNode(named:"marker"))
        XCTAssertNotNil(skeleton.slotNode(named:"box")?.physicsBody)
        skeleton.setBitMasks(category:4,collision:8)
        XCTAssertEqual(skeleton.slotNode(named:"box")?.physicsBody?.categoryBitMask,4)
        XCTAssertEqual(skeleton.slotNode(named:"box")?.physicsBody?.collisionBitMask,8)
    }
}
#endif
