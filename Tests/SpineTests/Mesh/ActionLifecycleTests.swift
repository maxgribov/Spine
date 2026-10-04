#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class ActionLifecycleTests: XCTestCase {
    func testSetupAndDeformFollowOnlySpriteKitActionTime() throws {
        let h = try MeshActionHarness()
        h.skeleton.position = CGPoint(x: 40,y: 60)
        h.bone.position = CGPoint(x: 900,y: 900)
        h.start(try h.skeleton.action(animation: "move"))
        XCTAssertEqual(h.skeleton.runtimeMode, .meshes)
        XCTAssertEqual(h.bone.position, CGPoint(x: 3,y: 4))
        XCTAssertEqual(h.skeleton.position, CGPoint(x: 40,y: 60))
        h.advance(0.5)
        XCTAssertEqual(h.bone.position.x, 13, accuracy: 1e-4)
        XCTAssertEqual(h.snapshot.deform[0][0], 10, accuracy: 1e-4)
        let time = h.snapshot.time, deform = h.snapshot.deform
        for _ in 0..<10 { try h.skeleton.prepareMeshes(for: validMeshContext) }
        XCTAssertEqual(h.snapshot.time,time)
        XCTAssertEqual(h.snapshot.deform,deform)
        h.advance(0.6)
        XCTAssertNil(h.snapshot.executionID)
        XCTAssertEqual(h.bone.position.x, 23,accuracy: 1e-4)
        XCTAssertNil(h.skeleton.meshPlaybackError)
    }

    func testSequentialReuseCopySequenceAndFiniteRepeatHaveFreshExecutions() throws {
        for wrapper in ["reuse", "copy", "sequence", "repeat"] {
            let h = try MeshActionHarness()
            var events: [Int] = []
            h.skeleton.eventTriggered = { events.append($0.int) }
            let action = try h.skeleton.action(animation: "move")
            if wrapper == "sequence" { h.start(.sequence([action,action])) }
            else if wrapper == "repeat" { h.start(.repeat(action,count: 2)) }
            else { h.start(action) }
            let first = h.snapshot.executionID
            h.advance(1.2)
            if wrapper == "reuse" || wrapper == "copy" {
                XCTAssertNil(h.snapshot.executionID)
                h.start(wrapper == "copy" ? action.copy() as! SKAction : action)
            }
            XCTAssertNotEqual(h.snapshot.executionID,first, wrapper)
            h.advance(1.3)
            XCTAssertEqual(events,[0,1,0,1],wrapper)
            XCTAssertNil(h.snapshot.executionID,wrapper)
            XCTAssertNil(h.skeleton.meshPlaybackError,wrapper)
        }
    }

    func testRepeatForeverGetsFreshCursorsAndEndsAfterExplicitStop() throws {
        let h = try MeshActionHarness()
        var starts = 0
        h.skeleton.eventTriggered = { if $0.int == 0 { starts += 1 } }
        h.start(.repeatForever(try h.skeleton.action(animation: "move")))
        h.advance(3.2)
        XCTAssertEqual(starts,4)
        XCTAssertEqual(h.snapshot.beginCount,4)
        XCTAssertEqual(h.snapshot.endCount,3)
        h.skeleton.stopMeshAnimation()
        h.skeleton.removeAction(forKey: "clip")
        XCTAssertNil(h.snapshot.executionID)
        XCTAssertNil(h.skeleton.meshPlaybackError)
    }

    func testZeroDurationRunsOnceAndReleasesLease() throws {
        let h = try MeshActionHarness(asset: meshTestAsset(clips: [meshClip("zero",duration: 0)]))
        var values: [Int] = []
        h.skeleton.eventTriggered = { values.append($0.int) }
        let action = try h.skeleton.action(animation: "zero")
        XCTAssertEqual(action.duration,0)
        h.start(action); h.advance(0.1)
        XCTAssertEqual(values,[0])
        XCTAssertEqual(h.snapshot.deform[0][0],20)
        XCTAssertNil(h.snapshot.executionID)
    }

    func testSharedImmutableAssetDoesNotSharePoseOrExecution() throws {
        let asset = try meshTestAsset(), h = try MeshActionHarness(asset: asset)
        let second = try Skeleton(meshAsset: asset); second.speed = 0.5; h.scene.addChild(second)
        h.start(try h.skeleton.action(animation: "move"))
        second.run(try second.action(animation: "move"))
        h.advance(0.5)
        XCTAssertNotEqual(h.snapshot.deform,second.meshRuntime!.snapshot.deform)
        h.skeleton.stopMeshAnimation(resetToSetupPose: true)
        XCTAssertEqual(h.snapshot.deform[0][0],0)
        XCTAssertGreaterThan(second.meshRuntime!.snapshot.deform[0][0],0)
    }

    func testActionDoesNotRetainItsOwner() throws {
        weak var weakOwner: Skeleton?
        var action: SKAction!
        autoreleasepool {
            let owner = try! Skeleton(meshAsset: meshTestAsset())
            weakOwner = owner; action = try! owner.action(animation: "move")
        }
        XCTAssertNil(weakOwner)
        let h = try MeshActionHarness(), receiver = SKNode()
        h.scene.addChild(receiver); h.start(action,on: receiver); h.advance(1.2)
        XCTAssertNil(h.skeleton.meshPlaybackError)
        XCTAssertEqual(receiver.position,.zero)
    }
}
#endif
