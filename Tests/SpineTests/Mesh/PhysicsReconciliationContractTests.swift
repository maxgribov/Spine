#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class PhysicsReconciliationContractTests:XCTestCase {
    private func harness()throws->MeshActionHarness {
        var json=simpleMeshJSON()
        var slots=json["slots"] as! [[String:Any]]
        slots += [["name":"bad","bone":"root","attachment":"box"],["name":"good","bone":"root","attachment":"box"]]
        json["slots"]=slots
        var skins=json["skins"] as! [[String:Any]],attachments=skins[0]["attachments"] as! [String:Any]
        let box:[String:Any]=["type":"boundingbox","vertexCount":4,"vertices":[-5,-5,5,-5,5,5,-5,5]]
        for name in ["bad","good"] {attachments[name]=["box":box]}
        skins[0]["attachments"]=attachments
        skins.append(["name":"without","attachments":["good":["box":["type":"point"]]]]);json["skins"]=skins
        let h=try MeshActionHarness(asset:SpineMeshAsset(json:jsonData(json),textures:TestMeshTextures()))
        h.skeleton.position=CGPoint(x:80,y:80);h.skeleton.setScale(2)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        return h
    }
    private let residue=CGPoint(x:3.814697265625e-6,y:3.814697265625e-6)
    func testInvalidSiblingDoesNotBlockCleanupOrKeepAnOldSuccessfulFrame()throws {
        let h=try harness(),bad=h.skeleton.slotNode(named:"bad")!,good=h.skeleton.slotNode(named:"good")!
        h.skeleton.position=CGPoint(x:10000,y:10000);h.skeleton.setScale(1)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        let old=h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices
        h.skeleton.position = .zero
        bad.position=CGPoint(x:0.02,y:0);good.position=CGPoint(x:0.001,y:0)
        h.bone.position.x=1
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract,path:"/runtime/nodes/bad")
        XCTAssertEqual(good.position,.zero);XCTAssertEqual(bad.position.x,CGFloat(Float(0.02)))
        XCTAssertEqual(h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices,old)
        good.position=CGPoint(x:0.001,y:0)
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract)
        XCTAssertNotEqual(good.position,.zero) // old large-coordinate frame expired despite error
    }
    func testInvalidContextWrongViewAndStickyFaultStillCleanValidOwnedSlots()throws {
        let h=try MeshActionHarness(asset:authoredAsset("slot-transitions"))
        h.skeleton.position=CGPoint(x:80,y:80);h.skeleton.setScale(2)
        let slot=h.skeleton.slotNode(named:"box")!
        let before=h.snapshot
        slot.position=residue
        assertMeshError(try h.skeleton.prepareMeshes(in:SKView()),.invalidRenderContext)
        XCTAssertEqual(slot.position,.zero);XCTAssertEqual(h.snapshot.time,before.time)
        let invalid=SpineMeshFrameContext(skeletonToPixels:.identity,pixelSize:.zero)
        slot.position=residue
        assertMeshError(try h.skeleton.prepareMeshes(for:invalid),.invalidRenderContext)
        XCTAssertEqual(slot.position,.zero)
        let action=try h.skeleton.action(animation:"switches")
        h.start(.group([action,action.copy() as! SKAction]))
        XCTAssertEqual(h.skeleton.meshPlaybackError?.code,.concurrentClip)
        let fault=h.snapshot
        slot.position=residue
        assertMeshError(try h.skeleton.prepareMeshes(for:invalid),.concurrentClip)
        XCTAssertEqual(slot.position,.zero);XCTAssertEqual(h.snapshot.time,fault.time);XCTAssertEqual(h.snapshot.epoch,fault.epoch)
    }
    func testCanonicalSingularAllowedButNewOffsetsNeedUnexpiredAuthorization()throws {
        let h=try harness(),slot=h.skeleton.slotNode(named:"good")!
        h.skeleton.setScale(0);slot.position=residue
        try h.skeleton.prepareMeshes(for:validMeshContext) // immediately previous safe frame
        XCTAssertEqual(slot.position,.zero)
        slot.position=CGPoint(x:1e-8,y:0)
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract)
        XCTAssertNotEqual(slot.position,.zero)
        slot.position = .zero
        try h.skeleton.prepareMeshes(for:validMeshContext)
        h.skeleton.setScale(1e-8);slot.position=CGPoint(x:1e-8,y:0)
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract)
    }
    func testPreviousFramesDoNotCrossSceneOrDetachedSpaces()throws {
        let h=try harness(),slot=h.skeleton.slotNode(named:"good")!
        h.skeleton.position=CGPoint(x:10000,y:10000);try h.skeleton.prepareMeshes(for:validMeshContext)
        let scene=SKScene(size:CGSize(width:256,height:256))
        h.skeleton.removeFromParent();scene.addChild(h.skeleton);h.skeleton.position = .zero
        slot.position=CGPoint(x:0.001,y:0)
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract)
        slot.position = .zero;h.skeleton.position=CGPoint(x:10000,y:10000)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        h.skeleton.removeFromParent();h.skeleton.position = .zero;slot.position=CGPoint(x:0.001,y:0)
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract)
    }
    func testRemovalTokenIsExactOneShotAndDoesNotAuthorizeLaterManualEdits()throws {
        let h=try harness(),slot=h.skeleton.slotNode(named:"good")!
        let parent=slot.parent
        slot.position=residue
        try h.skeleton.apply(skin:"without")
        XCTAssertNil(slot.physicsBody);XCTAssertTrue(slot.parent === parent)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertEqual(slot.position,.zero)
        slot.position=residue
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract)
    }
    func testPausedRepeatedPreparationDoesNotChangeTimeBoneBodyPropertiesOrDeliverContacts()throws {
        let h=try harness(),slot=h.skeleton.slotNode(named:"good")!
        let owned=slot.physicsBody!
        owned.categoryBitMask=4;owned.contactTestBitMask=8;owned.collisionBitMask=16;owned.friction=0.7
        let spy=ContactSpy();h.scene.physicsWorld.contactDelegate=spy
        h.skeleton.isPaused=true;h.bone.position=CGPoint(x:5,y:6)
        let other=SKNode();other.position=h.bone.convert(CGPoint.zero,to:h.scene)
        other.physicsBody=SKPhysicsBody(circleOfRadius:2);other.physicsBody!.categoryBitMask=8;other.physicsBody!.contactTestBitMask=4;other.physicsBody!.collisionBitMask=0;other.physicsBody!.affectedByGravity=false
        h.scene.addChild(other);h.advance(0.05)
        XCTAssertGreaterThan(spy.calls,0)
        let contacts=spy.calls,before=h.snapshot
        slot.position=residue;slot.zRotation=CGFloat(Float(4*Double.pi))
        for _ in 0..<10 {try h.skeleton.prepareMeshes(for:validMeshContext)}
        XCTAssertEqual(slot.position,.zero);XCTAssertEqual(slot.zRotation,0)
        XCTAssertEqual(h.bone.position,CGPoint(x:5,y:6));XCTAssertEqual(h.snapshot.time,before.time);XCTAssertEqual(h.snapshot.epoch,before.epoch)
        XCTAssertTrue(slot.physicsBody === owned);XCTAssertTrue(owned.node === slot)
        XCTAssertEqual(owned.categoryBitMask,4);XCTAssertEqual(owned.contactTestBitMask,8);XCTAssertEqual(owned.collisionBitMask,16);XCTAssertEqual(owned.friction,0.7,accuracy:1e-6)
        XCTAssertEqual(spy.calls,contacts)
    }
    func testDynamicBodyAndNonfiniteAncestorCannotReuseAuthorization()throws {
        let h=try harness(),slot=h.skeleton.slotNode(named:"good")!
        slot.physicsBody!.isDynamic=true;slot.position=residue
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract,path:"/runtime/nodes/good")
        XCTAssertEqual(slot.position,residue)
        slot.physicsBody!.isDynamic=false;slot.position = .zero
        try h.skeleton.prepareMeshes(for:validMeshContext)
        h.skeleton.position.x = .infinity;slot.position=residue
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.invalidRenderContext,path:"/runtime/frame")
        XCTAssertEqual(slot.position,residue)
        h.skeleton.position=CGPoint(x:80,y:80)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertEqual(slot.position,.zero)
    }

    private final class ContactSpy:NSObject,SKPhysicsContactDelegate {
        var calls=0
        func didBegin(_ contact:SKPhysicsContact) {calls+=1}
        func didEnd(_ contact:SKPhysicsContact) {calls+=1}
    }
}
#endif

#if os(macOS) || os(iOS)
extension PhysicsReconciliationContractTests {
    func testLocalPositionCapRejectsNextRepresentableValueEvenWithLargeWorldBudget()throws {
        // Given: large world coordinates permit more residue than the local cap.
        let h=try harness(),slot=try XCTUnwrap(h.skeleton.slotNode(named:"good"))
        h.skeleton.position=CGPoint(x:10000,y:10000);h.skeleton.setScale(1)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        let within=Float(0.01),outside=within.nextUp

        // Trace: the owned slot first passes local caps and the wider world bound;
        // the next Float fails intrinsic caps before any correction/GPU commit.
        slot.position=CGPoint(x:CGFloat(within),y:0)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertEqual(slot.position,.zero)
        let before=h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices

        // When: an independently finite value is just outside the fixed local cap.
        slot.position=CGPoint(x:CGFloat(outside),y:0)
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract,path:"/runtime/nodes/good")

        // Then: a large world budget cannot authorize a clamp; recovery is explicit.
        XCTAssertEqual(slot.position.x,CGFloat(outside))
        XCTAssertEqual(h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices,before)
        slot.position = .zero
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertFalse(h.skeleton.meshRuntime!.managedVisuals.isHidden)
    }

    func testIntrinsicSlotViolationPrecedesNonfiniteWorldAndStickyErrorStillWins()throws {
        for position in [CGPoint(x:0.02,y:0),CGPoint(x:CGFloat.nan,y:0)] {
            let h=try harness(),slot=h.skeleton.slotNode(named:"good")!
            let old=h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices
            h.skeleton.position.x = .infinity;slot.position=position
            assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract,path:"/runtime/nodes/good")
            if position.x.isNaN {XCTAssertTrue(slot.position.x.isNaN)} else {XCTAssertEqual(slot.position.x,CGFloat(Float(position.x)))}
            XCTAssertEqual(h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices,old)
        }
        let h=try MeshActionHarness(asset:authoredAsset("slot-transitions"))
        let action=try h.skeleton.action(animation:"switches")
        h.start(.group([action,action.copy() as! SKAction]))
        h.skeleton.position.x = .infinity
        let slot=h.skeleton.slotNode(named:"box")!;slot.zRotation=0.001
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.concurrentClip)
        XCTAssertEqual(slot.zRotation,CGFloat(Float(0.001)))
        h.skeleton.stopMeshAnimation()
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract,path:"/runtime/nodes/box")
    }
    func testUnauthorizedResiduePrecedesInvalidWorldForForeignDynamicAndLostTokens()throws {
        for mode in ["foreign","dynamic","token-mismatch","token-expired"] {
            let h=try harness(),slot=h.skeleton.slotNode(named:"good")!
            let before=h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices
            switch mode {
            case "foreign":slot.physicsBody=SKPhysicsBody(circleOfRadius:1);slot.physicsBody!.isDynamic=false
            case "dynamic":slot.physicsBody!.isDynamic=true
            case "token-mismatch":slot.position=residue;try h.skeleton.apply(skin:"without")
            default:try h.skeleton.apply(skin:"without");try h.skeleton.prepareMeshes(for:validMeshContext)
            }
            let stable=h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices
            slot.position=CGPoint(x:1e-4,y:0);h.skeleton.position.x = .infinity
            assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract,path:"/runtime/nodes/good")
            XCTAssertEqual(slot.position.x,CGFloat(Float(1e-4)),mode)
            XCTAssertEqual(h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices,stable,mode)
            if mode=="foreign" || mode=="dynamic" {XCTAssertEqual(stable,before)}
        }
        let h=try MeshActionHarness(asset:authoredAsset("slot-transitions"))
        let action=try h.skeleton.action(animation:"switches")
        h.start(.group([action,action.copy() as! SKAction]))
        let slot=h.skeleton.slotNode(named:"box")!
        slot.physicsBody!.isDynamic=true;slot.position=CGPoint(x:1e-4,y:0);h.skeleton.position.x = .infinity
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.concurrentClip)
        XCTAssertEqual(slot.position.x,CGFloat(Float(1e-4)))
        h.skeleton.stopMeshAnimation()
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract,path:"/runtime/nodes/box")
    }

}
#endif
