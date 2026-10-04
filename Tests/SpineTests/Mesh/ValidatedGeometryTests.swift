#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine
final class ValidatedGeometryTests:XCTestCase {
    func testTokenOwnsValidatedSnapshotAndRejectsWrongNodeReuseAndGeometryMutation()throws {
        let texture=TestMeshTextures().texture
        var positions:[SIMD2<Float>]=[SIMD2(0,0),SIMD2(64,0),SIMD2(0,64)]
        func node()throws->MeshTriangleNode {try MeshTriangleNode(texture:texture,positions:positions,uvs:[SIMD2(0,0),SIMD2(1,0),SIMD2(0,1)],indices:[0,1,2])}
        let first=try node(),second=try node()
        let token=try first.validateForRendering(localToPixels:.identity,positions:positions)
        positions[0].x = .infinity // token's immutable snapshot must not change
        XCTAssertTrue(first.canCommit(token));XCTAssertFalse(second.canCommit(token))
        first.commit(token);XCTAssertEqual(first.positions[0],.zero)
        XCTAssertFalse(first.canCommit(token))
        let next=try first.validateForRendering(localToPixels:.identity,positions:first.positions)
        try first.updatePositions([SIMD2(1,0),SIMD2(64,0),SIMD2(0,64)])
        XCTAssertFalse(first.canCommit(next))
    }
    func testLaterAttachmentGeometryFailureDoesNotCommitEarlierMesh()throws {
        var json=simpleMeshJSON()
        json["bones"]=[["name":"root"],["name":"large","parent":"root"]]
        var slots=json["slots"] as! [[String:Any]];slots.append(["name":"large","bone":"large","attachment":"mesh"]);json["slots"]=slots
        var skins=json["skins"] as! [[String:Any]],attachments=skins[0]["attachments"] as! [String:Any]
        let original=attachments["slot"] as! [String:Any]
        var large=original["mesh"] as! [String:Any]
        let extent=Double(Float.greatestFiniteMagnitude/4)
        large["vertices"]=[0,0,extent,0,extent,extent,0,extent]
        attachments["large"]=["mesh":large];skins[0]["attachments"]=attachments;json["skins"]=skins
        let h=try MeshActionHarness(asset:SpineMeshAsset(json:jsonData(json),textures:TestMeshTextures()))
        try h.skeleton.prepareMeshes(for:validMeshContext)
        let first=try XCTUnwrap(h.skeleton.meshAttachmentNode(named:"mesh",inSlot:"slot") as? MeshTriangleNode)
        let before=first.positions,snapshot=h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices
        h.bone.position.x=5;h.skeleton.boneNode(named:"large")!.xScale=10
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.invalidGeometry)
        XCTAssertEqual(first.positions,before)
        XCTAssertEqual(h.skeleton.meshRuntime!.setupRenderer!.snapshot.vertices,snapshot)
    }

}
#endif
