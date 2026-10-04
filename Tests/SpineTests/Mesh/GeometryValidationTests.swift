#if os(macOS) || os(iOS)
import XCTest
@testable import Spine

final class GeometryValidationTests:XCTestCase {
    func testFractionalInfluenceCountAndBoneIndexAreRejectedWithoutTruncation()throws {
        let valid:[Double]=[1,0,0,0,1, 1,0,64,0,1, 1,0,64,64,1, 1,0,0,64,1]
        for index in [0,1] {
            var json=simpleMeshJSON(),vertices=valid
            vertices[index] += 0.5
            editMeshAttachment(&json) {$0["vertices"]=vertices}
            try expectMeshLoadError(json,.invalidGeometry,path:"/skins/0/attachments/slot/mesh/vertices/\(index)")
        }
    }

    func testOptionalNonessentialGeometryAndZeroWeightAreAccepted()throws {
        var json=simpleMeshJSON()
        let weighted:[Double]=[1,0,0,0,0, 1,0,64,0,1, 1,0,64,64,1, 1,0,0,64,1]
        editMeshAttachment(&json) {$0["vertices"]=weighted}
        XCTAssertNoThrow(try SpineMeshAsset(json:jsonData(json),textures:TestMeshTextures()))
    }
    func testInvalidIndicesCountsUVsAndWeightsFailBeforeResources()throws {
        let cases:[(String,Any,String)]=[
            ("triangles",[-1,1,2],"/triangles/0"),("triangles",[0,1,9],"/triangles/2"),
            ("triangles",[0,1],"/triangles"),("uvs",[0,0,1],"/uvs"),
            ("vertices",[2,0,0,0,1],"/vertices/0"),
            ("vertices",[1,0,0,0,-1, 1,0,64,0,1, 1,0,64,64,1, 1,0,0,64,1],"/vertices/4"),
            ("vertices",[1,7,0,0,1, 1,0,64,0,1, 1,0,64,64,1, 1,0,0,64,1],"/vertices/1")
        ]
        for (key,value,path) in cases {
            var json=simpleMeshJSON();editMeshAttachment(&json) {$0[key]=value}
            try expectMeshLoadError(json,.invalidGeometry,path:"/skins/0/attachments/slot/mesh"+path)
        }
    }
    func testNonfiniteModelGeometryIsRejected()throws {
        let base=try JSONDecoder().decode(SpineModel.self,from:jsonData(simpleMeshJSON()))
        for value in [CGFloat.nan,CGFloat.infinity] {
            let mesh=MeshAttachmentModel(name:"mesh",fileName:nil,path:nil,uvs:[0,1,1,1,1,0,0,0],triangles:[0,1,2],vertices:[value,0,64,0,64,64,0,64],hull:0,edges:nil,color:.init(value:"ffffffff"),width:nil,height:nil)
            let skin=SkinModel(name:"default",slots:[.init(name:"slot",attachments:[mesh])])
            let model=SpineModel(skeleton:base.skeleton,bones:base.bones,slots:base.slots,skins:[skin],ik:[],transform:[],path:[],events:[],animations:[],featureIssues:[])
            let provider=TestMeshTextures()
            assertMeshError(try {_ = try SpineMeshAsset(model:model,textures:provider)}(),.invalidGeometry,path:"/skins/0/attachments/slot/mesh/vertices")
            XCTAssertTrue(provider.requests.isEmpty)
        }
    }
    func testInvalidDeformRangeAndTimelineOrderFailBeforeResources()throws {
        for frames:[[String:Any]] in [[[:],["time":1,"offset":-1,"vertices":[1]]],[[:],["time":1,"offset":8,"vertices":[1]]],[["time":1],["time":1]]] {
            var json=simpleMeshJSON();json["animations"]=["a":["attachments":["default":["slot":["mesh":["deform":frames]]]]]]
            try expectMeshLoadError(json,.invalidTimeline)
        }
    }
}
#endif
