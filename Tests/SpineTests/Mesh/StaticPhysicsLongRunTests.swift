// v6: the same previously failing 3x3000 physics paths, preparing each frame.
#if os(macOS)
import XCTest
import SpriteKit
@testable import Spine
final class StaticPhysicsLongRunTests:XCTestCase {
    func testCorrectionBreaksFeedbackOnAllThreeLongPaths()throws {
        var reports=[[String:Any]]()
        for (name,origin,scale,offset) in [("moving-80",CGFloat(80),CGFloat(2),CGFloat(0)),("origin-offcenter",CGFloat(0),CGFloat(2),CGFloat(40)),("large-parent",CGFloat(10000),CGFloat(0.65),CGFloat(20))] {
            var json=try JSONSerialization.jsonObject(with:meshResource("slot-transitions.json")) as! [String:Any]
            var skins=json["skins"] as! [[String:Any]],attachments=skins[0]["attachments"] as! [String:Any],boxes=attachments["box"] as! [String:Any]
            for key in boxes.keys {
                var box=boxes[key] as! [String:Any],vertices=box["vertices"] as! [Double]
                for i in vertices.indices {vertices[i]+=Double(offset)}
                box["vertices"]=vertices;boxes[key]=box
            }
            attachments["box"]=boxes;skins[0]["attachments"]=attachments;json["skins"]=skins
            let h=try MeshActionHarness(asset:SpineMeshAsset(json:jsonData(json),textures:authoredTextures()))
            h.skeleton.setScale(scale)
            let slot=try XCTUnwrap(h.skeleton.slotNode(named:"box")),root=try XCTUnwrap(h.skeleton.boneNode(named:"root"))
            h.start(try h.skeleton.action(animation:"switches"))
            var checkpoints=[[String:Any]](),maximum:CGFloat=0,maximumStep:CGFloat=0,maximumRotation:CGFloat=0,maximumScaleError:CGFloat=0
            for frame in 1...3000 {
                h.skeleton.position=CGPoint(x:origin+CGFloat(frame)/7,y:origin-CGFloat(frame)/11)
                h.skeleton.zRotation=CGFloat(frame)*0.005
                let before=slot.position
                h.update(Double(frame)/60)
                let after=slot.position
                maximum=max(maximum,abs(after.x),abs(after.y));maximumStep=max(maximumStep,abs(after.x-before.x),abs(after.y-before.y));maximumRotation=max(maximumRotation,abs(slot.zRotation));maximumScaleError=max(maximumScaleError,abs(slot.xScale-1),abs(slot.yScale-1))
                let time=h.snapshot.time,bonePosition=root.position,boneRotation=root.zRotation
                try h.skeleton.prepareMeshes(for:validMeshContext)
                XCTAssertEqual(slot.position,.zero);XCTAssertEqual(slot.zRotation,0)
                XCTAssertEqual(h.snapshot.time,time);XCTAssertEqual(root.position,bonePosition);XCTAssertEqual(root.zRotation,boneRotation)
                XCTAssertTrue(slot.parent === root);XCTAssertEqual(slot.zPosition,0)
                if frame.isMultiple(of:100) {checkpoints.append(["frame":frame,"position":[after.x,after.y],"rotation":slot.zRotation])}
            }
            reports.append(["case":name,"frames":3000,"origin":origin,"scale":scale,"bboxVertexOffset":offset,"maximumAbsoluteLocalResidue":maximum,"maximumPerFrameLocalChange":maximumStep,"maximumRotation":maximumRotation,"maximumScaleError":maximumScaleError,"checkpoints":checkpoints,"directSlotWritesByHarness":0,"prepareCalls":3000])
        }
        try JSONSerialization.data(withJSONObject:reports,options:[.prettyPrinted,.sortedKeys]).write(to:URL(fileURLWithPath:"/tmp/spine-v6-physics-corrected.json"))
    }
}
#endif
