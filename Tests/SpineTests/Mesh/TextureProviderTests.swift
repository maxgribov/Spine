#if os(macOS)
import XCTest
import SpriteKit
@testable import Spine

final class TextureProviderTests:XCTestCase {
    func testTrimAndRotationCornersMapToKnownPagePixels()throws {
        let provider=try authoredTextures(),plain=try provider.region(named:"plain"),rotated=try provider.region(named:"rotated")
        XCTAssertEqual(plain.originalSize,CGSize(width:12,height:14));XCTAssertEqual(plain.trimRect,CGRect(x:2,y:3,width:8,height:6))
        func pixel(_ region:SpineMeshTextureRegion,_ x:CGFloat,_ y:CGFloat)->CGPoint {
            let p=CGPoint(x:x/12,y:y/14).applying(region.uvTransform)
            return CGPoint(x:p.x*32,y:p.y*32)
        }
        XCTAssertEqual(pixel(plain,2,3).x,2,accuracy:1e-6);XCTAssertEqual(pixel(plain,2,3).y,23,accuracy:1e-6)
        XCTAssertEqual(pixel(plain,10,9).x,10,accuracy:1e-6);XCTAssertEqual(pixel(plain,10,9).y,29,accuracy:1e-6)
        XCTAssertEqual(pixel(rotated,2,3).x,22,accuracy:1e-6);XCTAssertEqual(pixel(rotated,2,3).y,21,accuracy:1e-6)
        XCTAssertEqual(pixel(rotated,10,9).x,16,accuracy:1e-6);XCTAssertEqual(pixel(rotated,10,9).y,29,accuracy:1e-6)
        XCTAssertTrue(plain.texture === rotated.texture)
        XCTAssertFalse(plain.texture === (try provider.region(named:"pma-plain")).texture)
    }
    func testStraightAndAlreadyPmaPagesNormalizeExactlyOnce()throws {
        let provider=try authoredTextures()
        let a=try setupPixels(provider.region(named:"plain").texture.cgImage()),b=try setupPixels(provider.region(named:"pma-plain").texture.cgImage())
        XCTAssertEqual(a,b)
        XCTAssertTrue(a.enumerated().contains {$0.offset%4==3 && $0.element>0 && $0.element<255})
    }
    func testMissingCorruptPageAndInvalidMetadataAreTypedAndEscaped()throws {
        assertMeshError(try {_ = try SpineAtlasTextureProvider(atlasText:"a/b.png\nsize: 32,32\n",pageData:[:])}(),.missingTexture,path:"/textures/a~1b.png")
        assertMeshError(try {_ = try SpineAtlasTextureProvider(atlasText:"a.png\nsize: 32,32\n",pageData:["a.png":Data([0,1])])}(),.invalidTextureRegion,path:"/textures/a.png")
        let text=String(decoding:try meshResource("authored.atlas"),as:UTF8.self).replacingOccurrences(of:"rotate: 90",with:"rotate: 45")
        assertMeshError(try {_ = try SpineAtlasTextureProvider(atlasText:text,pageData:["authored-straight.png":meshResource("authored-straight.png"),"authored-pma.png":meshResource("authored-pma.png")])}(),.invalidTextureRegion,path:"/textures/rotated")
        let provider=try authoredTextures()
        assertMeshError(try {_ = try provider.region(named:"missing/a~b")}(),.missingTexture,path:"/textures/missing~1a~0b")
    }
    func testAtlasNumericListsRejectExtraInvalidAndEmptyComponents()throws {
        for bounds in ["0,0,8,6,garbage","0,,0,8,6","0,0,bad,6","0,0,8,6,"] {
            let atlas="authored-straight.png\nsize: 32,32\nmesh\nbounds: \(bounds)\n"
            assertMeshError(try {_ = try SpineAtlasTextureProvider(atlasText:atlas,pageData:["authored-straight.png":meshResource("authored-straight.png")])}(),.invalidTextureRegion,path:"/textures/mesh")
        }
    }

    func testOpaqueSubtextureAndInvalidExplicitMetadataAreRejected()throws {
        let texture=TestMeshTextures().texture
        let opaque=SKTexture(rect:CGRect(x:0,y:0,width:0.5,height:1),in:texture)
        assertMeshError(try {_ = try SpineMeshTextureRegion(texture:opaque,pixelSize:opaque.size(),originalSize:CGSize(width:2,height:4),trimRect:CGRect(x:0,y:0,width:2,height:4),uvTransform:.identity)}(),.invalidTextureRegion)
        assertMeshError(try {_ = try SpineMeshTextureRegion(texture:texture,pixelSize:texture.size(),originalSize:CGSize(width:4,height:4),trimRect:CGRect(x:3,y:0,width:2,height:4),uvTransform:.identity)}(),.invalidTextureRegion)
    }
}
#endif
