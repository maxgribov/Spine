#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class AnimationPlaybackTests:XCTestCase {
    func testLoadedEventResetAndSkinChangePreventOldTimelineWrites()throws {
        // Given: a real JSON clip changes attachments, colors, deform and draw order.
        let h=try MeshActionHarness(asset:authoredAsset("slot-transitions"))
        var delivered:[Int]=[]
        h.skeleton.eventTriggered={ [weak skeleton=h.skeleton] event in
            delivered.append(event.int)
            guard event.int==2,let skeleton=skeleton else {return}
            skeleton.stopMeshAnimation(resetToSetupPose:true)
            do {try skeleton.apply(skin:"compatible")}
            catch {XCTFail("Reentrant skin selection failed: \(error)")}
        }
        // Trace: begin sends 7; sampling .6 updates all channels then sends 2;
        // stop changes epoch and restores setup; skin replacement keeps setup;
        // the post-event epoch guard prevents the old final event/sample/end.
        h.start(try h.skeleton.action(animation:"switches"))

        // When: reset and replace resources from the event callback, then keep ticking.
        h.update(0.6)
        h.advance(1.2)
        try h.skeleton.prepareMeshes(for:validMeshContext)

        // Then: no old animation state or event survives the reentrant reset.
        XCTAssertEqual(delivered,[7,2])
        XCTAssertEqual(h.snapshot.activeAttachments,["base","region","pointA","boxA"])
        XCTAssertEqual(h.snapshot.drawOrder,[0,1,2,3])
        XCTAssertTrue(h.snapshot.deform.flatMap {$0}.allSatisfy {$0==0})
        XCTAssertEqual(h.skeleton.meshRuntime!.slotStates.map(\.color),h.skeleton.meshRuntime!.slotStates.map(\.setupColor))
        XCTAssertEqual(h.skeleton.activePoints?.first?.position.x,10)
        XCTAssertNotNil(h.skeleton.slotNode(named:"box")?.physicsBody)
        XCTAssertNil(h.snapshot.executionID)
        XCTAssertNil(h.skeleton.meshPlaybackError)

        h.start(try h.skeleton.action(animation:"switches"))
        h.advance(0.1)
        XCTAssertEqual(delivered,[7,2,7])
        XCTAssertNotNil(h.snapshot.executionID)
        XCTAssertNil(h.skeleton.meshPlaybackError)
    }

    func testPublicGoblinsWalkUsesRealActionsAndDeformWithoutReplacingNodes()throws {
        let h=try MeshActionHarness(asset:goblinAsset())
        try h.skeleton.apply(skin:"goblin")
        func nodes(_ node:SKNode)->[ObjectIdentifier] {[ObjectIdentifier(node)]+node.children.flatMap(nodes)}
        let before=nodes(h.skeleton)
        let action=try h.skeleton.action(animation:"walk")
        XCTAssertEqual(action.duration,1,accuracy:1e-6)
        h.start(action)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        let setup=h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices
        h.advance(0.45)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertNotEqual(h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices,setup)
        XCTAssertTrue(h.snapshot.deform.flatMap{$0}.contains {$0 != 0})
        XCTAssertEqual(nodes(h.skeleton),before)
        XCTAssertNil(h.skeleton.meshPlaybackError)
    }
    func testLoadedEventDefaultsAndSkippedIntervalsDeliverEachEventOnce()throws {
        let h=try MeshActionHarness(asset:authoredAsset("slot-transitions"))
        var events:[EventModel]=[]
        h.skeleton.eventTriggered={events.append($0)}
        h.start(try h.skeleton.action(animation:"switches"));h.update(1);h.advance(0.2)
        XCTAssertEqual(events.map(\.int),[7,2,7])
        XCTAssertEqual(events.map(\.float),[1.5,1.5,1.5])
        XCTAssertEqual(events.map(\.string),["setup","setup","setup"])
        XCTAssertNil(h.snapshot.executionID)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertEqual(events.count,3)
    }

}
#endif
