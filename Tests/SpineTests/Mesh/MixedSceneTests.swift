#if os(macOS)
import XCTest
import SpriteKit
@testable import Spine

final class MixedSceneTests:XCTestCase {
    func testLegacyAndMeshActionsShareSceneWithoutMutatingForeignNodesOrOrdering()throws {
        let h=try MeshActionHarness(asset:authoredAsset("slot-transitions"))
        h.renderer.ignoresSiblingOrder=true
        let texture=TestMeshTextures().texture
        let image=NSImage(cgImage:texture.cgImage(),size:texture.size())
        let atlas=SKTextureAtlas(dictionary:["body":image,"open":image,"closed":image])
        let model=try JSONDecoder().decode(SpineModel.self,from:Data(contentsOf:XCTUnwrap(Bundle.module.url(forResource:"legacy-4.1",withExtension:"json"))))
        let legacy=Skeleton(model,["default":atlas]);try legacy.applyDefaultSkin()
        legacy.position=CGPoint(x:150,y:60);legacy.zPosition=10
        let fence=SKSpriteNode(color:.brown,size:CGSize(width:100,height:20));fence.name="foreign-fence";fence.zPosition=5
        h.scene.addChild(legacy);h.scene.addChild(fence);h.skeleton.zPosition=3
        legacy.run(try legacy.action(animation:"motion"),withKey:"legacy")
        h.start(try h.skeleton.action(animation:"switches"))
        let arm=try XCTUnwrap(legacy.boneNode(named:"arm")),initial=arm.position
        for _ in 0..<8 {
            h.advance(0.1)
            let position=arm.position,rotation=arm.zRotation,children=legacy.children.map(ObjectIdentifier.init)
            let foreignChildren=h.scene.children.map(ObjectIdentifier.init)
            try h.skeleton.prepareMeshes(for:validMeshContext)
            XCTAssertEqual(arm.position,position);XCTAssertEqual(arm.zRotation,rotation)
            XCTAssertEqual(legacy.children.map(ObjectIdentifier.init),children)
            XCTAssertEqual(h.scene.children.map(ObjectIdentifier.init),foreignChildren)
            XCTAssertEqual(legacy.zPosition,10);XCTAssertEqual(fence.zPosition,5)
            XCTAssertEqual(fence.position,.zero);XCTAssertNil(fence.shader)
            XCTAssertTrue(h.renderer.ignoresSiblingOrder)
            XCTAssertNotNil(legacy.action(forKey:"legacy"))
            XCTAssertNil(legacy.meshRuntime)
        }
        XCTAssertNotEqual(arm.position,initial)
        XCTAssertEqual(h.snapshot.drawOrder,[0,1,2,3])
        h.skeleton.stopMeshAnimation(resetToSetupPose:true)
        XCTAssertNotNil(legacy.action(forKey:"legacy"));XCTAssertNil(legacy.meshPlaybackError)
    }
}
#endif
