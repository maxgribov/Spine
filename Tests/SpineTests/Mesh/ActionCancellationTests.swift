#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class ActionCancellationTests: XCTestCase {
    func testInitialEventResetInvalidatesRemainingCallbacksAndAllowsFreshExecution() throws {
        // Given: begin samples a nonzero t=0 pose before delivering its initial event.
        let initial = try MeshScalarTimeline(keys: [.init(0, 9), .init(1, 20)])
        let first = try MeshClip(name: "initial", channels: [
            .init(target: .boneX(0), timeline: initial),
            .init(target: .deform(slot: 0, component: 0), timeline: initial)
        ], events: [meshEvent(0, 7), meshEvent(1, 8)])
        let h = try MeshActionHarness(asset: meshTestAsset(clips: [first, meshClip("fresh")]))
        var delivered: [Int] = []
        h.skeleton.eventTriggered = { [weak skeleton = h.skeleton] event in
            delivered.append(event.int)
            if event.int == 7 { skeleton?.stopMeshAnimation(resetToSetupPose: true) }
        }

        // When: stop from begin's event invalidates sample/end and an unused copy.
        let action = try h.skeleton.action(animation: "initial")
        let stale = action.copy() as! SKAction
        h.start(action)
        h.advance(1.2)
        h.start(stale)
        h.advance(1.2)

        // Then: old callbacks cannot restore their t=0 pose or reacquire a lease.
        XCTAssertEqual(delivered, [7])
        XCTAssertEqual(h.snapshot.epoch, 1)
        XCTAssertEqual(h.snapshot.beginCount, 1)
        XCTAssertNil(h.snapshot.executionID)
        XCTAssertEqual(h.snapshot.deform, [[0, 0]])
        XCTAssertEqual(h.bone.position, CGPoint(x: 3, y: 4))
        h.start(try h.skeleton.action(animation: "fresh"))
        h.advance(1.2)
        XCTAssertEqual(delivered, [7, 0, 1])
        XCTAssertEqual(h.snapshot.beginCount, 2)
        XCTAssertEqual(h.snapshot.endCount, 1)
        XCTAssertNil(h.snapshot.executionID)
        XCTAssertNil(h.skeleton.meshPlaybackError)
    }

    func testStopInvalidatesRunningUnusedAndCopiedActionsWithoutRemovingContainers() throws {
        let h = try MeshActionHarness()
        let unused = try h.skeleton.action(animation: "other")
        let copy = unused.copy() as! SKAction
        h.start(.repeatForever(try h.skeleton.action(animation: "move")))
        h.skeleton.run(.moveBy(x: 30,y: 0,duration: 2),withKey: "ordinary")
        h.advance(0.3)
        let before = h.snapshot, pose = h.bone.position
        h.skeleton.stopMeshAnimation()
        XCTAssertEqual(h.snapshot.epoch,before.epoch+1)
        XCTAssertEqual(h.snapshot.deform,before.deform)
        XCTAssertEqual(h.bone.position,pose)
        XCTAssertNil(h.snapshot.executionID)
        XCTAssertNotNil(h.skeleton.action(forKey:"clip"))
        XCTAssertNotNil(h.skeleton.action(forKey:"ordinary"))
        let x = h.skeleton.position.x
        h.start(.group([unused,copy]),key:"stale")
        h.advance(0.4)
        XCTAssertEqual(h.snapshot.deform,before.deform)
        XCTAssertEqual(h.bone.position,pose)
        XCTAssertGreaterThan(h.skeleton.position.x,x)
        XCTAssertNil(h.skeleton.meshPlaybackError)
        h.start(try h.skeleton.action(animation:"move"),key:"fresh")
        h.advance(0.2)
        XCTAssertNotNil(h.snapshot.executionID)
        XCTAssertNil(h.skeleton.meshPlaybackError)
    }

    func testRemovalFreezesPoseButNeedsStopToReleaseLease() throws {
        let h = try MeshActionHarness()
        h.start(try h.skeleton.action(animation:"move")); h.advance(0.3)
        let before = h.snapshot
        h.skeleton.removeAction(forKey:"clip"); h.advance(0.5)
        XCTAssertEqual(h.snapshot.deform,before.deform)
        XCTAssertEqual(h.snapshot.executionID,before.executionID)
        h.start(try h.skeleton.action(animation:"other"))
        XCTAssertEqual(h.skeleton.meshPlaybackError?.code,.concurrentClip)
        h.skeleton.stopMeshAnimation()
        h.skeleton.removeAction(forKey:"clip")
        h.start(try h.skeleton.action(animation:"other"))
        h.advance(0.2)
        XCTAssertNil(h.skeleton.meshPlaybackError)
        XCTAssertNotNil(h.snapshot.executionID)
    }

    func testResetRestoresSetupButNotSkeletonTransformOrOrdinaryActions() throws {
        let h = try MeshActionHarness()
        h.skeleton.position = CGPoint(x: 40,y: 50)
        h.start(try h.skeleton.action(animation:"move")); h.advance(0.4)
        h.skeleton.run(.wait(forDuration: 4),withKey:"ordinary")
        h.bone.yScale = -5
        h.skeleton.stopMeshAnimation(resetToSetupPose: true)
        XCTAssertEqual(h.bone.position,CGPoint(x:3,y:4))
        XCTAssertEqual(h.bone.xScale,2)
        XCTAssertEqual(h.bone.yScale,0.5)
        XCTAssertEqual(h.snapshot.deform,[[0,0]])
        XCTAssertEqual(h.snapshot.activeAttachments,["mesh"])
        XCTAssertEqual(h.skeleton.position,CGPoint(x:40,y:50))
        XCTAssertNotNil(h.skeleton.action(forKey:"ordinary"))
    }

    func testDropToDefaultsResetsEpochAndRemovesExistingActions() throws {
        let h = try MeshActionHarness()
        let stale = try h.skeleton.action(animation:"other")
        h.start(try h.skeleton.action(animation:"move"));h.advance(0.3)
        h.bone.run(.moveBy(x:20,y:0,duration:2),withKey:"manual")
        let epoch = h.snapshot.epoch
        h.start(h.skeleton.dropToDefaultsAction(),key:"reset");h.advance(0.1)
        XCTAssertEqual(h.snapshot.epoch,epoch+1)
        XCTAssertNil(h.snapshot.executionID)
        XCTAssertEqual(h.snapshot.deform,[[0,0]])
        XCTAssertFalse(h.bone.hasActions())
        h.start(stale);h.advance(0.3)
        XCTAssertNil(h.snapshot.executionID)
        XCTAssertEqual(h.bone.position,CGPoint(x:3,y:4))
    }

    func testReentrantEventStopAndResetPreventFurtherEventsOrOldWrites() throws {
        let events = [meshEvent(0,0),meshEvent(0.1,1),meshEvent(0.2,2),meshEvent(0.4,3)]
        let h = try MeshActionHarness(asset: meshTestAsset(clips:[meshClip(events:events)]))
        var delivered:[Int]=[]
        h.skeleton.eventTriggered = { [weak skeleton=h.skeleton] event in
            delivered.append(event.int)
            if event.int==1 { skeleton?.stopMeshAnimation(resetToSetupPose:true) }
        }
        h.start(try h.skeleton.action(animation:"move"))
        // A single SpriteKit callback crosses multiple event keys.
        h.update(0.5)
        XCTAssertEqual(delivered,[0,1])
        XCTAssertEqual(h.snapshot.deform,[[0,0]])
        XCTAssertEqual(h.bone.position,CGPoint(x:3,y:4))
        XCTAssertNil(h.snapshot.executionID)
        h.advance(1)
        XCTAssertEqual(delivered,[0,1])
    }

    func testReentrantFinalEventRestartDoesNotReleaseNewExecution() throws {
        let first = try meshClip("first",duration:0.2,events:[meshEvent(0.2,7)])
        let second = try meshClip("second",duration:2,events:[])
        let h = try MeshActionHarness(asset: meshTestAsset(clips:[first,second]))
        h.skeleton.eventTriggered = { [weak skeleton=h.skeleton] _ in
            guard let skeleton=skeleton else{return}
            skeleton.stopMeshAnimation()
            skeleton.run(try! skeleton.action(animation:"second"),withKey:"replacement")
        }
        h.start(try h.skeleton.action(animation:"first"));h.advance(0.5)
        XCTAssertEqual(h.snapshot.epoch,1)
        XCTAssertNotNil(h.snapshot.executionID)
        XCTAssertEqual(h.snapshot.beginCount,2)
        XCTAssertNil(h.skeleton.meshPlaybackError)
        let deform = h.snapshot.deform[0][0]
        h.advance(0.2)
        XCTAssertGreaterThan(h.snapshot.deform[0][0],deform)
    }
}
#endif
