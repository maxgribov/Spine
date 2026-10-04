#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class RendererProxyLifetimeTests:XCTestCase {
    func testOnlyPossibleRegionAncestorChainsHaveProxiesButAllLogicalBonesAreValidated()throws {
        var json=simpleMeshJSON()
        json["bones"]=[["name":"root"],["name":"meshBone","parent":"root"],["name":"regionBone","parent":"root","x":20]]
        json["slots"]=[["name":"slot","bone":"meshBone","attachment":"mesh"],["name":"regionSlot","bone":"regionBone"]]
        var skins=json["skins"] as! [[String:Any]],attachments=skins[0]["attachments"] as! [String:Any]
        attachments["regionSlot"]=["region":["type":"region","width":16,"height":16]]
        skins[0]["attachments"]=attachments;json["skins"]=skins
        json["animations"]=["activate":["slots":["regionSlot":["attachment":[["time":0.1,"name":"region"]]]]]]
        let h=try MeshActionHarness(asset:SpineMeshAsset(json:jsonData(json),textures:TestMeshTextures()))
        func names(_ node:SKNode)->[String] {([node.name].compactMap {$0})+node.children.flatMap(names)}
        let proxies=names(h.skeleton.meshRuntime!.managedVisuals).filter {$0.hasPrefix("_spine_render_bone_")}
        XCTAssertEqual(Set(proxies),["_spine_render_bone_0","_spine_render_bone_2"])
        let region=try XCTUnwrap(h.skeleton.regionAttachmentNode(named:"region"))
        XCTAssertTrue(region.isHidden)
        h.start(try h.skeleton.action(animation:"activate"));h.advance(0.15)
        try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertFalse(region.isHidden)
        XCTAssertEqual(region.convert(CGPoint.zero,to:h.skeleton).x,20,accuracy:1e-6)
        let meshBone=try XCTUnwrap(h.skeleton.boneNode(named:"meshBone"));meshBone.zPosition=1
        assertMeshError(try h.skeleton.prepareMeshes(for:validMeshContext),.mutatedNodeContract,path:"/runtime/nodes/meshBone")
        meshBone.zPosition=0;try h.skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertEqual(Set(names(h.skeleton.meshRuntime!.managedVisuals).filter {$0.hasPrefix("_spine_render_bone_")}),Set(proxies))
    }
}
#endif
