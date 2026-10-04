#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class SlotStateTests:XCTestCase {
    func testSlotRGBAndRGBACompileIndependentAbsoluteBezierChannels()throws {
        for (name,count) in [("rgb",3),("rgba",4)] {
            var json=simpleMeshJSON()
            let controls=(0..<count).flatMap {component -> [Double] in
                [1.0/3.0,Double(component+1)*0.1,2.0/3.0,Double(component+1)*0.2]
            }
            json["animations"]=["color":["slots":["slot":[name:[
                ["time":0,"color":count==3 ? "000000":"00000000","curve":controls],
                ["time":1,"color":count==3 ? "ffffff":"ffffffff"]
            ]]]]]
            let h=try MeshActionHarness(asset:SpineMeshAsset(json:jsonData(json),textures:TestMeshTextures()))
            h.start(try h.skeleton.action(animation:"color"));h.advance(0.5)
            let color=h.skeleton.meshRuntime!.slotStates[0].color
            for component in 0..<count {
                let expected=Float(0.125+0.375*Double(component+1)*0.3)
                XCTAssertEqual(color[component],expected,accuracy:0.0001,"\(name) channel \(component)")
            }
            if count==3 {XCTAssertEqual(color.w,1)}
        }
    }

    func testSkinChangePreservesOnlyMatchingDeformSourceAndFailsAtomically()throws {
        let h=try MeshActionHarness(asset:authoredAsset("slot-transitions"))
        h.start(try h.skeleton.action(animation:"switches"));h.advance(0.1)
        let before=h.snapshot.deform[0]
        XCTAssertTrue(before.contains {$0 != 0})
        try h.skeleton.apply(skin:"compatible")
        XCTAssertEqual(h.snapshot.activeAttachments[0],"base")
        XCTAssertEqual(h.snapshot.deform[0],before)
        let identity=ObjectIdentifier(h.skeleton.meshRuntime!.managedVisuals)
        assertMeshError(try h.skeleton.apply(skin:"missing/a"),.missingSkin,path:"/skins/missing~1a")
        XCTAssertEqual(ObjectIdentifier(h.skeleton.meshRuntime!.managedVisuals),identity)
        XCTAssertEqual(h.snapshot.deform[0],before)
        try h.skeleton.apply(skin:"incompatible")
        XCTAssertTrue(h.snapshot.deform[0].allSatisfy {$0==0})
        XCTAssertEqual(h.snapshot.activeAttachments[1],"region") // inherited from default skin
    }
    func testAttachmentNilAndRegionMeshTransitionsUseOneSlotState()throws {
        let h=try MeshActionHarness(asset:authoredAsset("slot-transitions"))
        h.start(try h.skeleton.action(animation:"switches"));h.advance(0.3)
        XCTAssertEqual(h.snapshot.activeAttachments[0],"inherited")
        XCTAssertTrue(h.snapshot.deform[0].contains {$0 != 0})
        h.advance(0.2)
        XCTAssertEqual(h.snapshot.activeAttachments[0],"region")
        XCTAssertTrue(h.snapshot.deform[0].allSatisfy {$0==0})
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertFalse(try XCTUnwrap(h.skeleton.regionAttachmentNode(named:"region")).isHidden)
        h.advance(0.15)
        XCTAssertEqual(h.snapshot.activeAttachments[0],"independent")
        XCTAssertTrue(h.snapshot.deform[0].allSatisfy {$0==0})
        h.advance(0.2)
        XCTAssertNil(h.snapshot.activeAttachments[0])
        h.advance(0.2)
        XCTAssertEqual(h.snapshot.activeAttachments[0],"base")
    }
    func testOwnedStaticPhysicsRoundoffDoesNotMaskDeliberateSlotMutation()throws {
        let h=try MeshActionHarness(asset:authoredAsset("slot-transitions"))
        h.start(try h.skeleton.action(animation:"switches"));h.advance(0.35)
        let slot=try XCTUnwrap(h.skeleton.slotNode(named:"box")),before=slot.zRotation
        XCTAssertFalse(slot.physicsBody!.isDynamic)
        XCTAssertLessThanOrEqual(abs(before),CGFloat(Float.ulpOfOne)*8)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertEqual(slot.zRotation,0) // v6 canonicalizes only bounded owned-static residue
        slot.zRotation=0.001
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract,path:"/runtime/nodes/box")
        XCTAssertEqual(slot.zRotation,CGFloat(Float(0.001)))
    }

    func testColorAndDrawOrderChannelsPreserveBoundedInternalDepth()throws {
        let h=try MeshActionHarness(asset:authoredAsset("slot-transitions"))
        h.start(try h.skeleton.action(animation:"switches"));h.advance(0.3)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertEqual(h.snapshot.drawOrder,[1,0,2,3])
        XCTAssertEqual(h.skeleton.meshRuntime!.slotStates[1].color.x,1,accuracy:1e-6) // stepped RGB
        XCTAssertLessThan(h.skeleton.meshRuntime!.slotStates[1].color.w,1)
        func check(_ node:SKNode,_ parent:CGFloat) {
            let depth=parent+node.zPosition
            XCTAssertGreaterThanOrEqual(depth,0);XCTAssertLessThan(depth,1)
            for child in node.children {check(child,depth)}
        }
        for child in h.skeleton.children {check(child,0)}
        h.advance(0.5);try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertEqual(h.snapshot.drawOrder,[0,1,2,3])
        XCTAssertNil(h.skeleton.meshPlaybackError)
    }
}
#endif
