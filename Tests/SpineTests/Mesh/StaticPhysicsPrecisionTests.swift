#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class StaticPhysicsPrecisionTests:XCTestCase {
    func testOwnedStaticBodyRoundoffSurvivesMovingParentWithBoundedCorrectionAndStillRejectsMutation()throws {
        let h=try MeshActionHarness(asset:authoredAsset("slot-transitions"))
        h.skeleton.position=CGPoint(x:80,y:80);h.skeleton.setScale(2)
        let box=try XCTUnwrap(h.skeleton.slotNode(named:"box"))
        let body=try XCTUnwrap(box.physicsBody)
        h.start(try h.skeleton.action(animation:"switches"))
        var largestResidue:CGFloat=0
        for frame in 1...36 {
            h.skeleton.position=CGPoint(x:80+CGFloat(frame)/7,y:80-CGFloat(frame)/11)
            h.skeleton.zRotation=CGFloat(frame)*0.005
            h.update(Double(frame)/60)
            let before=box.position
            largestResidue=max(largestResidue,abs(before.x),abs(before.y))
            try h.skeleton.prepareMeshes(for:validMeshContext)
            XCTAssertEqual(box.position,.zero)
            XCTAssertFalse(box.physicsBody?.isDynamic ?? true)
        }
        XCTAssertLessThan(largestResidue,0.001)
        // Pin the exact observed iOS residue even if this macOS solver version
        // happens to produce zero in a particular frame.
        h.skeleton.position=CGPoint(x:80,y:80);h.skeleton.zRotation=0
        box.position=CGPoint(x:3.814697265625e-6,y:3.814697265625e-6)
        let exact=box.position
        try h.skeleton.prepareMeshes(for:validMeshContext);XCTAssertEqual(box.position,.zero)
        h.update(0.9) // nil bounding-box attachment retains prior-owned residue
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertNil(box.physicsBody)
        h.skeleton.position = .zero
        try h.skeleton.prepareMeshes(for:validMeshContext);XCTAssertEqual(box.position,.zero)
        box.position=CGPoint(x:0.001,y:0)
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract,path:"/runtime/nodes/box")
        box.position = .zero;try h.skeleton.prepareMeshes(for:validMeshContext)
        let plain=try XCTUnwrap(h.skeleton.slotNode(named:"visual"))
        plain.position=exact
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract,path:"/runtime/nodes/visual")
        plain.position = .zero
        // A replacement body is not covered by the library-owned history.
        box.physicsBody=SKPhysicsBody(circleOfRadius:1);box.physicsBody!.isDynamic=false;box.position=exact
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract,path:"/runtime/nodes/box")
        XCTAssertFalse(box.physicsBody === body)
    }
}
#endif
