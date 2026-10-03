#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class RendererNumericBoundaryTests:XCTestCase {
    private let positions:[SIMD2<Float>]=[SIMD2(0,0),SIMD2(8,0),SIMD2(8,6),SIMD2(0,6)]
    private func makeNode()throws->MeshTriangleNode {
        try MeshTriangleNode(texture:TestMeshTextures().texture,positions:positions,uvs:[SIMD2(0,0),SIMD2(1,0),SIMD2(1,1),SIMD2(0,1)],indices:[0,1,2,0,2,3])
    }
    private func sprites(_ node:SKNode)->[SKSpriteNode] {
        (node as? SKSpriteNode).map {[$0]} ?? node.children.flatMap(sprites)
    }
    private func uploadedValues(_ node:SKNode)->[Float] {
        sprites(node).flatMap { sprite->[Float] in
            var numbers=[Float(sprite.position.x),Float(sprite.position.y),Float(sprite.size.width),Float(sprite.size.height)]
            for attribute in sprite.shader?.attributes ?? [] {
                guard let value=sprite.value(forAttributeNamed:attribute.name) else {continue}
                switch attribute.type {
                case .float:numbers.append(value.floatValue)
                case .vectorFloat2:let v=value.vectorFloat2Value;numbers += [v.x,v.y]
                case .vectorFloat3:let v=value.vectorFloat3Value;numbers += [v.x,v.y,v.z]
                case .vectorFloat4:let v=value.vectorFloat4Value;numbers += [v.x,v.y,v.z,v.w]
                default:break
                }
            }
            return numbers
        }
    }
    func testFiniteButUnrepresentableInverseDoesNotUploadAndRecovers()throws {
        let node=try makeNode();try node.prepareForRendering(localToPixels:.identity)
        let before=uploadedValues(node)
        for scale:CGFloat in [1e-100,5e-39] {
            // First overflows inverse Floats; second has finite inverse/padding but overflows the padded bound.
            let tiny=CGAffineTransform(a:scale,b:0,c:0,d:scale,tx:0,ty:0)
            assertMeshError(try node.prepareForRendering(localToPixels:tiny),.invalidRenderContext,path:"/runtime/frame")
        }
        XCTAssertEqual(uploadedValues(node),before)
        XCTAssertTrue(uploadedValues(node).allSatisfy(\.isFinite))
        XCTAssertTrue(sprites(node).allSatisfy(\.isHidden))
        try node.prepareForRendering(localToPixels:.identity)
        XCTAssertTrue(sprites(node).contains {!$0.isHidden})
    }
    func testTinyExtentAndOverflowingBoundsDoNotReplaceGoodBuffers()throws {
        let node=try makeNode();try node.prepareForRendering(localToPixels:.identity)
        let before=uploadedValues(node)
        let tiny=positions.map {$0*Float(1e-40)}
        assertMeshError(try node.updatePositions(tiny),.invalidGeometry,path:"/runtime/geometry")
        XCTAssertEqual(node.positions,positions);XCTAssertEqual(uploadedValues(node),before)
        let huge:Float=Float.greatestFiniteMagnitude
        assertMeshError(try node.updatePositions([SIMD2(-huge,0),SIMD2(huge,0),SIMD2(huge,1),SIMD2(-huge,1)]),.invalidGeometry)
        XCTAssertEqual(node.positions,positions);XCTAssertEqual(uploadedValues(node),before)
        try node.prepareForRendering(localToPixels:.identity,positions:positions)
        XCTAssertTrue(sprites(node).contains {!$0.isHidden})
    }
    func testInitialBadProjectionHidesLoadedAssetWithoutAnyNonfiniteWrites()throws {
        let skeleton=try Skeleton(meshAsset:SpineMeshAsset(json:jsonData(simpleMeshJSON()),textures:TestMeshTextures()))
        let node=try XCTUnwrap(skeleton.meshAttachmentNode(named:"mesh",inSlot:"slot"))
        let before=uploadedValues(node)
        let bad=SpineMeshFrameContext(skeletonToPixels:CGAffineTransform(a:1e-100,b:0,c:0,d:1e-100,tx:0,ty:0),pixelSize:CGSize(width:256,height:256))
        assertMeshError(try skeleton.prepareMeshes(for:bad),.invalidRenderContext,path:"/runtime/frame")
        XCTAssertEqual(uploadedValues(node),before)
        XCTAssertTrue(uploadedValues(node).allSatisfy(\.isFinite))
        XCTAssertTrue(skeleton.meshRuntime!.managedVisuals.isHidden)
        try skeleton.prepareMeshes(for:validMeshContext)
        XCTAssertFalse(skeleton.meshRuntime!.managedVisuals.isHidden)
        XCTAssertTrue(sprites(node).contains {!$0.isHidden})
    }
    func testFiniteSingularAndReflectedProjectionRemainSupported()throws {
        let node=try makeNode();try node.prepareForRendering(localToPixels:.identity)
        XCTAssertNoThrow(try node.prepareForRendering(localToPixels:CGAffineTransform(a:0,b:0,c:0,d:1,tx:0,ty:0)))
        XCTAssertTrue(sprites(node).allSatisfy(\.isHidden))
        try node.prepareForRendering(localToPixels:CGAffineTransform(a:-2,b:0,c:0,d:2,tx:128,ty:0))
        XCTAssertTrue(uploadedValues(node).allSatisfy(\.isFinite))
        XCTAssertTrue(sprites(node).contains {!$0.isHidden})
    }
}
#endif
