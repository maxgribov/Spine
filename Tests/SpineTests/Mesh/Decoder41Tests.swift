#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class Decoder41Tests:XCTestCase {
    func testRawNumericTimelineTimesRejectNegativeDuplicateAndDescendingKeysWithEscapedPath()throws {
        // These values exercise the JSON boundary, rather than the test-only compiled clip.
        for (times,invalidIndex):([Double],Int) in [([-0.1],0),([0,0],1),([1,0.5],1)] {
            var json=simpleMeshJSON()
            json["animations"]=["a/~b":["bones":["root":["translatex":times.map {["time":$0,"value":3]}]]]]
            XCTAssertNoThrow(try JSONDecoder().decode(SpineModel.self,from:jsonData(json)))
            try expectMeshLoadError(json,.invalidTimeline,path:"/animations/a~1~0b/bones/root/translatex/\(invalidIndex)/time")
        }
    }

    func testOneDecoderReads41EmptySparseDeformAndLinkedTimelines()throws {
        var json=simpleMeshJSON()
        editMeshAttachment(&json,name:"linked") {$0=["type":"linkedmesh","parent":"mesh","timelines":false]}
        json["animations"]=["deform":["attachments":["default":["slot":["mesh":["deform":[[:],["time":1,"offset":1,"vertices":[3,4]]]]]]]]]
        let data=try jsonData(json),model=try JSONDecoder().decode(SpineModel.self,from:data)
        let frames=try XCTUnwrap(model.animations.first?.attachmentTimelines.first?.deform)
        XCTAssertEqual(frames[0].vertices,[]);XCTAssertEqual(frames[0].offset,0)
        XCTAssertEqual(frames[1].offset,1)
        let linked=model.skins[0].slots[0].attachments.first {$0.name=="linked"} as! LinkedMeshAttachmentModel
        XCTAssertFalse(linked.timelines)
        XCTAssertNoThrow(try SpineMeshAsset(model:model,textures:TestMeshTextures()))
        XCTAssertNoThrow(try SpineMeshAsset(json:data,textures:TestMeshTextures()))
        XCTAssertEqual(Skeleton(model,[:]).runtimeMode,.legacy)
    }

    func testVersionAndCapabilitiesAreOnlyCheckedAtOptInBoundary()throws {
        for version in ["4.0.99","4.2.1","4.1","4.1.17-beta","metadata"] {
            var json=simpleMeshJSON(),metadata=json["skeleton"] as! [String:Any];metadata["spine"]=version;json["skeleton"]=metadata
            let model=try JSONDecoder().decode(SpineModel.self,from:jsonData(json))
            XCTAssertEqual(Skeleton(model,[:]).runtimeMode,.legacy)
            try expectMeshLoadError(json,.unsupportedVersion,path:"/skeleton/spine")
        }
        for value:Any in [NSNull(),41] {
            var json=simpleMeshJSON(),metadata=json["skeleton"] as! [String:Any];metadata["spine"]=value;json["skeleton"]=metadata
            try expectMeshLoadError(json,.unsupportedVersion,path:"/skeleton/spine")
        }
        var json=simpleMeshJSON(),metadata=json["skeleton"] as! [String:Any];metadata.removeValue(forKey:"spine");json["skeleton"]=metadata
        try expectMeshLoadError(json,.unsupportedVersion,path:"/skeleton/spine")
    }

    func testOldMeshLayoutsAndUnsupportedUnselectedSkinAreNotSilentlyAccepted()throws {
        var old=simpleMeshJSON();old["animations"]=["old":["deform":[:]]]
        XCTAssertNoThrow(try JSONDecoder().decode(SpineModel.self,from:jsonData(old)))
        try expectMeshLoadError(old,.invalidData,path:"/animations/old/deform")
        var linked=simpleMeshJSON();editMeshAttachment(&linked,name:"link") {$0=["type":"linkedmesh","parent":"mesh","deform":true]}
        try expectMeshLoadError(linked,.invalidData,path:"/skins/0/attachments/slot/link/deform")
        var json=simpleMeshJSON(),skins=json["skins"] as! [[String:Any]]
        skins.append(["name":"unselected","attachments":["slot":["extra":["width":20,"height":20,"sequence":["count":2]]]]]);json["skins"]=skins
        XCTAssertNoThrow(try JSONDecoder().decode(SpineModel.self,from:jsonData(json)))
        try expectMeshLoadError(json,.unsupportedFeature,path:"/skins/1/attachments/slot/extra/sequence")
    }

    func testKnownUnsupportedTimelinesAreRecordedWithoutLegacyExecution()throws {
        for (group,payload,path):(String,[String:Any],String) in [
            ("bones",["root":["shearx":[["value":1]]]],"/animations/a/bones/root/shearx"),
            ("slots",["slot":["rgb2":[["light":"ffffff","dark":"000000"]]]],"/animations/a/slots/slot/rgb2"),
            ("path",["constraint":["position":[["value":1]]]],"/animations/a/path")
        ] {
            var json=simpleMeshJSON();json["animations"]=["a":[group:payload]]
            XCTAssertNoThrow(try JSONDecoder().decode(SpineModel.self,from:jsonData(json)))
            try expectMeshLoadError(json,.unsupportedFeature,path:path)
        }
    }

    func testRGBAndAlphaChannelsKeepTheir41ValuesWithoutLegacyExecution()throws {
        var json=simpleMeshJSON()
        json["animations"]=["color":["slots":["slot":["rgb":[["color":"ff8040"]],"alpha":[["value":0.25]]]]]]
        let model=try JSONDecoder().decode(SpineModel.self,from:jsonData(json))
        guard case .slots(let slots)=model.animations[0].groups[0] else {return XCTFail("Missing slot group")}
        XCTAssertTrue(slots[0].timelines.isEmpty)
        let rgb=try XCTUnwrap(slots[0].numericTimelines.first {$0.name=="rgb"}).keys[0].values
        XCTAssertEqual(rgb,[1,Float(128)/255,Float(64)/255])
        XCTAssertEqual(slots[0].numericTimelines.first {$0.name=="alpha"}?.keys[0].values,[0.25])
        XCTAssertNoThrow(try SpineMeshAsset(model:model,textures:TestMeshTextures()))
    }

    func testMalformedCurveErrorsAreMappedOnlyAtMeshAssetBoundary()throws {
        var deform=simpleMeshJSON()
        deform["animations"]=["a":["attachments":["default":["slot":["mesh":["deform":[["curve":[]]]]]]]]]
        XCTAssertNoThrow(try JSONDecoder().decode(SpineModel.self,from:jsonData(deform)))
        try expectMeshLoadError(deform,.invalidTimeline,path:"/animations/a/attachments/default/slot/mesh/deform/0/curve")
        var numeric=simpleMeshJSON()
        numeric["animations"]=["a":["bones":["root":["translatex":[["curve":[1,2,3]]]]]]]
        XCTAssertNoThrow(try JSONDecoder().decode(SpineModel.self,from:jsonData(numeric)))
        try expectMeshLoadError(numeric,.invalidTimeline,path:"/animations/a/bones/root/translatex/0/curve")
        numeric["animations"]=["a":["bones":["root":["rotate":[["curve":[]]]]]]]
        XCTAssertThrowsError(try JSONDecoder().decode(SpineModel.self,from:jsonData(numeric))) {error in
            guard case DecodingError.dataCorrupted = error else {return XCTFail("Legacy decoder error type changed")}
        }
        try expectMeshLoadError(numeric,.invalidTimeline,path:"/animations/a/bones/root/rotate/0/curve")
    }

    func testMalformedNewFieldIsDeferredForLegacyButRejectedByMeshAsset()throws {
        var json=simpleMeshJSON();json["animations"]=["a":["attachments":"invalid"]]
        let model=try JSONDecoder().decode(SpineModel.self,from:jsonData(json))
        XCTAssertEqual(Skeleton(model,[:]).runtimeMode,.legacy)
        try expectMeshLoadError(json,.invalidData,path:"/animations/a/attachments")
        editMeshAttachment(&json) {$0["type"]="unknown"}
        XCTAssertThrowsError(try JSONDecoder().decode(SpineModel.self,from:jsonData(json)))
    }
}
#endif
