#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class ResourceLifetimeTests:XCTestCase {
    func testCreatePrepareDestroyOneHundredTimesReleasesOwnerAssetAndMaterials()throws {
        let data=try jsonData(simpleMeshJSON())
        for _ in 0..<100 {
            weak var owner:Skeleton?,assetRef:SpineMeshAsset?,resources:MeshRendererResources?
            try autoreleasepool {
                let asset=try SpineMeshAsset(json:data,textures:TestMeshTextures())
                let skeleton=try Skeleton(meshAsset:asset)
                owner=skeleton;assetRef=asset;resources=asset.rendererResources
                try skeleton.prepareMeshes(for:validMeshContext)
            }
            XCTAssertNil(owner);XCTAssertNil(assetRef);XCTAssertNil(resources)
        }
    }
    func testRepeatedPrepareKeepsNodeAndMaterialIdentityWithoutProviderCalls()throws {
        let textures=TestMeshTextures(),asset=try SpineMeshAsset(json:jsonData(simpleMeshJSON()),textures:textures)
        let skeleton=try Skeleton(meshAsset:asset),other=try Skeleton(meshAsset:asset)
        func nodes(_ node:SKNode)->[SKNode] {[node]+node.children.flatMap(nodes)}
        let before=nodes(skeleton).map(ObjectIdentifier.init)
        let shaders=nodes(skeleton).compactMap {($0 as? SKSpriteNode)?.shader}
        let otherShaders=nodes(other).compactMap {($0 as? SKSpriteNode)?.shader}
        XCTAssertFalse(shaders.isEmpty);XCTAssertTrue(shaders[0] === otherShaders[0])
        let calls=textures.requests
        for index in 0..<100 {
            skeleton.boneNode(named:"root")!.position.x=CGFloat(index)
            try skeleton.prepareMeshes(for:validMeshContext)
        }
        XCTAssertEqual(nodes(skeleton).map(ObjectIdentifier.init),before)
        XCTAssertTrue(nodes(skeleton).compactMap {($0 as? SKSpriteNode)?.shader}[0] === shaders[0])
        XCTAssertEqual(textures.requests,calls)
        XCTAssertEqual(other.boneNode(named:"root")!.position,.zero)
    }
    func testOneHundredSkinReplacementsReleaseOldVisualTreesAndKeepAssetMaterials()throws {
        let asset=try authoredAsset("slot-transitions"),skeleton=try Skeleton(meshAsset:asset)
        let resources=asset.rendererResources
        for index in 0..<100 {
            weak var previous:SKNode?
            try autoreleasepool {
                previous=skeleton.meshRuntime!.managedVisuals
                try skeleton.apply(skin:index.isMultiple(of:2) ? "compatible":"incompatible")
                try skeleton.prepareMeshes(for:validMeshContext)
            }
            XCTAssertNil(previous)
            XCTAssertTrue(skeleton.meshRuntime!.asset.rendererResources === resources)
            XCTAssertEqual(skeleton.points?.count,2)
        }
    }

}
#endif
