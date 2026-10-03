#if os(macOS) || os(iOS)
import XCTest
@testable import Spine

final class LinkedMeshTests:XCTestCase {
    func testChainSharesGeometryButKeepsDirectParentTimelineIdentityAndOwnTexture()throws {
        var json=simpleMeshJSON()
        editMeshAttachment(&json,name:"link1") {$0=["type":"linkedmesh","parent":"mesh","path":"one"]}
        editMeshAttachment(&json,name:"link2") {$0=["type":"linkedmesh","parent":"link1","path":"two"]}
        editMeshAttachment(&json,name:"independent") {$0=["type":"linkedmesh","parent":"link2","timelines":false,"path":"independent"]}
        let textures=TestMeshTextures(),asset=try SpineMeshAsset(json:jsonData(json),textures:textures)
        func mesh(_ name:String)throws->(Int,CompiledMesh) {
            let attachment=try XCTUnwrap(asset.compiled.attachments.first {$0.name==name})
            guard case .mesh(let value)=attachment.content else {throw NSError(domain:"test",code:1)}
            return (attachment.id,value)
        }
        let base=try mesh("mesh"),one=try mesh("link1"),two=try mesh("link2"),independent=try mesh("independent")
        XCTAssertTrue(base.1.geometry === one.1.geometry);XCTAssertTrue(base.1.geometry === two.1.geometry)
        XCTAssertEqual(one.1.deformSourceID,base.0)
        XCTAssertEqual(two.1.deformSourceID,one.0)
        XCTAssertEqual(independent.1.deformSourceID,independent.0)
        XCTAssertTrue(textures.requests.contains("one"));XCTAssertTrue(textures.requests.contains("two"))
    }
    func testMissingParentAndCyclesFailWithoutResolvingTextures()throws {
        var missing=simpleMeshJSON();editMeshAttachment(&missing,name:"link") {$0=["type":"linkedmesh","parent":"missing"]}
        try expectMeshLoadError(missing,.missingAttachment,path:"/skins/0/attachments/slot/link/parent")
        var cycle=simpleMeshJSON()
        editMeshAttachment(&cycle,name:"a") {$0=["type":"linkedmesh","parent":"b"]}
        editMeshAttachment(&cycle,name:"b") {$0=["type":"linkedmesh","parent":"a"]}
        try expectMeshLoadError(cycle,.linkedMeshCycle,path:"/skins/0/attachments/slot/a/parent")
    }
}
#endif
