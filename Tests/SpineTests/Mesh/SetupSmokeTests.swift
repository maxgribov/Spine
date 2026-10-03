#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class SetupSmokeTests:XCTestCase {
    func testPublicGoblinsAssetShowsBothSetupSkinsAndSharesResources()throws {
        let asset=try goblinAsset()
        XCTAssertEqual(asset.animationNames,["walk"])
        XCTAssertEqual(Set(asset.skinNames),["default","goblin","goblingirl"])
        for skin in ["goblin","goblingirl"] {
            let skeleton=try Skeleton(meshAsset:asset,skin:skin)
            try skeleton.prepareMeshes(for:validMeshContext)
            let snapshot=try XCTUnwrap(skeleton.meshRuntime?.setupRenderer?.snapshot)
            XCTAssertGreaterThan(snapshot.vertices.flatMap{$0}.count,0)
            XCTAssertTrue(snapshot.vertices.flatMap{$0}.allSatisfy{$0.x.isFinite && $0.y.isFinite})
            XCTAssertFalse(skeleton.meshRuntime!.managedVisuals.isHidden)
        }
    }
    func testSimplePublicMeshSetupCoordinatesAndLookup()throws {
        let asset=try SpineMeshAsset(json:jsonData(simpleMeshJSON()),textures:TestMeshTextures())
        let skeleton=try Skeleton(meshAsset:asset)
        skeleton.position=CGPoint(x:500,y:400)
        try skeleton.prepareMeshes(for:validMeshContext)
        let snapshot=try XCTUnwrap(skeleton.meshRuntime?.setupRenderer?.snapshot)
        XCTAssertEqual(snapshot.vertices[0],[SIMD2(0,0),SIMD2(64,0),SIMD2(64,64),SIMD2(0,64)])
        XCTAssertNotNil(skeleton.meshAttachmentNode(named:"mesh",inSlot:"slot"))
        XCTAssertNil(skeleton.regionAttachmentNode(named:"mesh"))
    }
}
#endif
