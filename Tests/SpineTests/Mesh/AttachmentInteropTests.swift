#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class AttachmentInteropTests:XCTestCase {
    func testPointAndPhysicsFollowActiveAttachmentAndSkinReplacementHasNoStaleNodes()throws {
        let h=try MeshActionHarness(asset:authoredAsset("slot-transitions"))
        XCTAssertEqual(h.skeleton.points?.count,2)
        XCTAssertEqual(h.skeleton.activePoints?.first?.position.x,10)
        let firstBody=try XCTUnwrap(h.skeleton.slotNode(named:"box")?.physicsBody)
        h.start(try h.skeleton.action(animation:"switches"));h.advance(0.35)
        XCTAssertEqual(h.skeleton.activePoints?.first?.position.x,20)
        XCTAssertFalse(h.skeleton.slotNode(named:"box")?.physicsBody === firstBody)
        h.advance(0.4)
        XCTAssertEqual(h.skeleton.activePoints?.count,0)
        XCTAssertNil(h.skeleton.slotNode(named:"box")?.physicsBody)
        let oldPoints=h.skeleton.points ?? []
        try h.skeleton.apply(skin:"compatible")
        XCTAssertEqual(h.skeleton.points?.count,2)
        XCTAssertTrue(oldPoints.allSatisfy {$0.parent==nil})
        XCTAssertFalse((h.skeleton.points ?? []).contains {new in oldPoints.contains {$0 === new}})
        XCTAssertNotNil(h.skeleton.slotNode(named:"box")?.physicsBody)
    }
}
#endif
