#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class FrameContextTests: XCTestCase {
    func testPrepareIsIdempotentDoesNotAdvancePausedPoseOrDeliverEvents() throws {
        let h = try MeshActionHarness()
        var events = 0
        h.skeleton.eventTriggered = {_ in events += 1}
        h.start(try h.skeleton.action(animation:"move"));h.advance(0.3)
        h.skeleton.isPaused = true
        let before=h.snapshot,count=events
        h.bone.position = CGPoint(x:77,y:88)
        for _ in 0..<10 {try h.skeleton.prepareMeshes(for:validMeshContext)}
        XCTAssertEqual(h.snapshot.time,before.time)
        XCTAssertEqual(h.snapshot.deform,before.deform)
        XCTAssertEqual(h.snapshot.executionID,before.executionID)
        XCTAssertEqual(events,count)
        XCTAssertEqual(h.bone.position,CGPoint(x:77,y:88))
        h.advance(0.5)
        XCTAssertEqual(h.snapshot.deform,before.deform)
        XCTAssertEqual(events,count)
    }

    func testInvalidContextHidesOncePerIncidentAndRecoversWithoutPlaybackFault() throws {
        let h = try MeshActionHarness()
        h.start(try h.skeleton.action(animation:"move"));h.advance(0.2)
        let before=h.snapshot
        var errors:[SpineRuntimeError]=[]
        h.skeleton.meshDiagnosticHandler={errors.append($0)}
        let contexts = [
            SpineMeshFrameContext(skeletonToPixels:.init(a:.nan,b:0,c:0,d:1,tx:0,ty:0),pixelSize:CGSize(width:1,height:1)),
            SpineMeshFrameContext(skeletonToPixels:.identity,pixelSize:CGSize(width:0,height:10)),
            SpineMeshFrameContext(skeletonToPixels:.identity,pixelSize:CGSize(width:1.5,height:10)),
            SpineMeshFrameContext(skeletonToPixels:.identity,pixelSize:CGSize(width:10,height:CGFloat.infinity))
        ]
        for context in contexts {
            assertMeshError(try h.skeleton.prepareMeshes(for:context),.invalidRenderContext,path:"/runtime/frame")
            XCTAssertTrue(h.skeleton.meshRuntime!.managedVisuals.isHidden)
            XCTAssertNil(h.skeleton.meshPlaybackError)
        }
        XCTAssertEqual(errors.count,1)
        XCTAssertEqual(h.snapshot.time,before.time)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertFalse(h.skeleton.meshRuntime!.managedVisuals.isHidden)
        assertMeshError(try h.skeleton.prepareMeshes(for:contexts[0]),.invalidRenderContext)
        XCTAssertEqual(errors.count,2)
    }

    func testSingularProjectionIsRecoverableWithoutChangingClock() throws {
        let h = try MeshActionHarness()
        h.start(try h.skeleton.action(animation:"move"));h.advance(0.4)
        let before=h.snapshot
        let singular=SpineMeshFrameContext(skeletonToPixels:.init(a:0,b:0,c:0,d:1,tx:20,ty:30),pixelSize:CGSize(width:200,height:100))
        try h.skeleton.prepareMeshes(for:singular)
        XCTAssertTrue(h.skeleton.meshRuntime!.managedVisuals.isHidden)
        XCTAssertNil(h.skeleton.meshPlaybackError)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertFalse(h.skeleton.meshRuntime!.managedVisuals.isHidden)
        XCTAssertEqual(h.snapshot.time,before.time)
        XCTAssertEqual(h.snapshot.deform,before.deform)
    }

    func testLegacyPrepareAndStopAreNoOpsEvenWithInvalidContext() throws {
        let model=try JSONDecoder().decode(SpineModel.self,from:Data(contentsOf:XCTUnwrap(Bundle.module.url(forResource:"legacy-4.1",withExtension:"json"))))
        let skeleton=Skeleton(model,[:])
        skeleton.position=CGPoint(x:30,y:40)
        skeleton.run(.wait(forDuration:1),withKey:"ordinary")
        let invalid=SpineMeshFrameContext(skeletonToPixels:.init(a:.nan,b:0,c:0,d:1,tx:0,ty:0),pixelSize:.zero)
        try skeleton.prepareMeshes(for:invalid)
        try skeleton.prepareMeshes(in:SKView())
        skeleton.stopMeshAnimation(resetToSetupPose:true)
        XCTAssertEqual(skeleton.runtimeMode,.legacy)
        XCTAssertEqual(skeleton.position,CGPoint(x:30,y:40))
        XCTAssertNotNil(skeleton.action(forKey:"ordinary"))
        XCTAssertNil(skeleton.meshPlaybackError)
        XCTAssertNil(skeleton.meshAttachmentNode(named:"mesh",inSlot:"slot"))
    }

    func testNativeWrongViewRemainsHiddenThroughStopAndResetUntilValidPrepare() throws {
        let h=try MeshActionHarness()
        h.start(try h.skeleton.action(animation:"move"));h.advance(0.2)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        let before=h.snapshot
        let wrongView=SKView()
        var diagnostics:[SpineRuntimeError]=[]
        h.skeleton.meshDiagnosticHandler={diagnostics.append($0)}
        for _ in 0..<2 {
            assertMeshError(try h.skeleton.prepareMeshes(in:wrongView),.invalidRenderContext,path:"/runtime/frame")
        }
        XCTAssertEqual(diagnostics.count,1)
        XCTAssertEqual(diagnostics.first?.code,.invalidRenderContext)
        XCTAssertEqual(diagnostics.first?.path,"/runtime/frame")
        XCTAssertTrue(h.skeleton.meshRuntime!.managedVisuals.isHidden)
        XCTAssertEqual(h.snapshot.deform,before.deform)
        XCTAssertNil(h.skeleton.meshPlaybackError)
        h.skeleton.stopMeshAnimation()
        XCTAssertTrue(h.skeleton.meshRuntime!.managedVisuals.isHidden)
        XCTAssertEqual(h.snapshot.deform,before.deform)
        h.skeleton.stopMeshAnimation(resetToSetupPose:true)
        XCTAssertTrue(h.skeleton.meshRuntime!.managedVisuals.isHidden)
        assertMeshError(try h.skeleton.prepareMeshes(in:wrongView),.invalidRenderContext)
        XCTAssertEqual(diagnostics.count,1)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertFalse(h.skeleton.meshRuntime!.managedVisuals.isHidden)
        assertMeshError(try h.skeleton.prepareMeshes(in:wrongView),.invalidRenderContext)
        XCTAssertEqual(diagnostics.count,2)
        XCTAssertTrue(h.skeleton.meshRuntime!.managedVisuals.isHidden)
    }
}
#endif

#if os(macOS) || os(iOS)
extension FrameContextTests {
    func testEffectAndCropAncestorsAreRejectedAndRecoverWithoutAdvancingTime()throws {
        for parent in [SKEffectNode() as SKNode,SKCropNode()] {
            let h=try MeshActionHarness(asset:authoredAsset("deform-resources"))
            h.start(try h.skeleton.action(animation:"proof"));h.advance(0.2)
            let time=h.snapshot.time
            h.skeleton.removeFromParent();h.scene.addChild(parent);parent.addChild(h.skeleton)
            assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.unsupportedFeature)
            XCTAssertTrue(h.skeleton.meshRuntime!.managedVisuals.isHidden)
            h.skeleton.removeFromParent();h.scene.addChild(h.skeleton)
            try h.skeleton.prepareMeshes(for:validMeshContext)
            XCTAssertFalse(h.skeleton.meshRuntime!.managedVisuals.isHidden)
            XCTAssertEqual(h.snapshot.time,time)
        }
    }
    func testBoneChangesAfterPrepareOnlyUpdateMeshBuffersOnNextPrepare()throws {
        let h=try MeshActionHarness(asset:authoredAsset("deform-resources"))
        h.start(try h.skeleton.action(animation:"proof"));h.advance(0.2)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        let before=h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices
        h.bone.position.x += 30
        XCTAssertEqual(h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices,before)
        let time=h.snapshot.time
        try h.skeleton.prepareMeshes(for:validMeshContext)
        let after=h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices
        for (a,b) in zip(before[0],after[0]) {XCTAssertEqual(b.x-a.x,30,accuracy:1e-4)}
        XCTAssertEqual(h.snapshot.time,time)
    }
}
#endif
