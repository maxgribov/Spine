#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class TimelineTests: XCTestCase {
    func testLinearSteppedDefaultsAndLastKeyHold() throws {
        let linear = try MeshScalarTimeline(keys:[.init(0.2,4),.init(1.2,14)])
        var cursor=0
        XCTAssertEqual(linear.sample(0,default:99,cursor:&cursor),99)
        XCTAssertEqual(linear.sample(0.7,default:99,cursor:&cursor),9,accuracy:1e-5)
        XCTAssertEqual(linear.sample(5,default:99,cursor:&cursor),14)
        let stepped = try MeshScalarTimeline(keys:[.init(0,3,curve:.stepped),.init(1,8)])
        cursor=0
        XCTAssertEqual(stepped.sample(0.9,default:0,cursor:&cursor),3)
        XCTAssertEqual(stepped.sample(1,default:0,cursor:&cursor),8)
        let empty = try MeshScalarTimeline(keys:[])
        XCTAssertEqual(empty.sample(100,default:42,cursor:&cursor),42)
    }

    func testAbsoluteBezierControlsArePerChannelAndUseTenSegments() throws {
        // Linear x control positions put t=.5 at x=.7; unequal y controls expose
        // incorrect normalized-easing or shared-channel treatment.
        let first = try MeshScalarTimeline(keys:[.init(0.2,3,curve:.bezier(SIMD2(0.2+1/3,20),SIMD2(0.2+2/3,-2))),.init(1.2,9)])
        let second = try MeshScalarTimeline(keys:[.init(0.2,-5,curve:.bezier(SIMD2(0.2+1/3,2),SIMD2(0.2+2/3,4))),.init(1.2,3)])
        var a=0,b=0
        XCTAssertEqual(first.sample(0.7,default:0,cursor:&a),8.25,accuracy:1e-5)
        XCTAssertEqual(second.sample(0.7,default:0,cursor:&b),2,accuracy:1e-5)
        // Halfway between segments 5 and 6, not the exact cubic at t=.55.
        XCTAssertEqual(first.sample(0.75,default:0,cursor:&a),(8.25+7.032)/2,accuracy:1e-5)
    }

    func testIndependentBezierChannelsApplyToBoneSetupInSpriteKitPhase() throws {
        let x = try MeshScalarTimeline(keys:[.init(0.2,3,curve:.bezier(SIMD2(0.2+1/3,20),SIMD2(0.2+2/3,-2))),.init(1.2,9)])
        let y = try MeshScalarTimeline(keys:[.init(0.2,-5,curve:.bezier(SIMD2(0.2+1/3,2),SIMD2(0.2+2/3,4))),.init(1.2,3)])
        let clip = try MeshClip(name:"curves",channels:[.init(target:.boneX(0),timeline:x),.init(target:.boneY(0),timeline:y)])
        let h = try MeshActionHarness(asset:meshTestAsset(clips:[clip]))
        h.start(try h.skeleton.action(animation:"curves"));h.update(0.1)
        XCTAssertEqual(h.bone.position,CGPoint(x:3,y:4))
        h.update(0.7)
        XCTAssertEqual(h.bone.position.x,11.25,accuracy:1e-4)
        XCTAssertEqual(h.bone.position.y,6,accuracy:1e-4)
    }

    func testDurationIncludesDeformOnlyAndEventsOnlyWithoutExtraTail() throws {
        let deform = try MeshClip(name:"deform",channels:[.init(target:.deform(slot:0,component:1),timeline:MeshScalarTimeline(keys:[.init(0,0),.init(2,7)]))])
        let events = try MeshClip(name:"events",channels:[],events:[meshEvent(0,0),meshEvent(0.3,1),meshEvent(0.7,2)])
        let h = try MeshActionHarness(asset:meshTestAsset(clips:[deform,events]))
        XCTAssertEqual(try h.skeleton.action(animation:"deform").duration,2,accuracy:1e-6)
        XCTAssertEqual(try h.skeleton.action(animation:"events").duration,0.7,accuracy:1e-6)
        var delivered:[Int]=[]
        h.skeleton.eventTriggered={delivered.append($0.int)}
        h.start(try h.skeleton.action(animation:"events"))
        h.update(0.7);h.advance(0.2)
        XCTAssertEqual(delivered,[0,1,2])
        XCTAssertNil(h.snapshot.executionID)
    }

    func testInvalidCompiledTimesAndCurvesAreRejected() {
        for keys:[MeshScalarTimeline.Key] in [[.init(-1,0)],[.init(0,0),.init(0,1)],[.init(.nan,0)],[.init(0,.infinity)],[.init(0,1,curve:.bezier(SIMD2(.nan,0),SIMD2(1,1)))]] {
            assertMeshError(try { _ = try MeshScalarTimeline(keys:keys) }(),.invalidTimeline)
        }
    }
}
#endif
