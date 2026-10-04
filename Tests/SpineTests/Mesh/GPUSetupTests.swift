#if os(macOS)
import XCTest
import SpriteKit
import AppKit
@testable import Spine

func setupPixels(_ image:CGImage)throws->[UInt8] {
    var bytes=Array(repeating:UInt8(0),count:image.width*image.height*4)
    let success=bytes.withUnsafeMutableBytes {ptr->Bool in
        guard let context=CGContext(data:ptr.baseAddress,width:image.width,height:image.height,bitsPerComponent:8,bytesPerRow:image.width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue|CGBitmapInfo.byteOrder32Big.rawValue) else{return false}
        context.draw(image,in:CGRect(x:0,y:0,width:image.width,height:image.height));return true
    }
    XCTAssertTrue(success);return bytes
}
func captureSetup(_ skeleton:SKNode,size:CGSize=CGSize(width:512,height:512))throws->CGImage {
    _=NSApplication.shared
    let view=SKView(frame:CGRect(origin:.zero,size:size)),scene=SKScene(size:size)
    let window=NSWindow(contentRect:view.frame,styleMask:[],backing:.buffered,defer:false)
    window.isReleasedWhenClosed=false;window.contentView=view
    let scale=window.backingScaleFactor
    scene.scaleMode = .aspectFit;scene.backgroundColor = .clear;scene.addChild(skeleton);view.presentScene(scene)
    defer {view.presentScene(nil);skeleton.removeFromParent();window.close()}
    let origin=skeleton.convert(.zero,to:scene),x=skeleton.convert(CGPoint(x:1024,y:0),to:scene),y=skeleton.convert(CGPoint(x:0,y:1024),to:scene)
    let transform=CGAffineTransform(a:(x.x-origin.x)*scale/1024,b:(x.y-origin.y)*scale/1024,c:(y.x-origin.x)*scale/1024,d:(y.y-origin.y)*scale/1024,tx:origin.x*scale,ty:origin.y*scale)
    if let skeleton=skeleton as? Skeleton {try skeleton.prepareMeshes(for:SpineMeshFrameContext(skeletonToPixels:transform,pixelSize:CGSize(width:size.width*scale,height:size.height*scale)))}
    else if let mesh=skeleton as? MeshTriangleNode {try mesh.prepareForRendering(localToPixels:transform)}
    return try XCTUnwrap(view.texture(from:scene,crop:CGRect(origin:.zero,size:size))).cgImage()
}

final class GPUSetupTests:XCTestCase {
    private static var comparisons:[[String:Any]]=[]
    private var output:URL {URL(fileURLWithPath:ProcessInfo.processInfo.environment["SPINE_MESH_VALIDATION_OUTPUT"] ?? "/tmp/spine-phase3-goblins")}
    private func record(_ name:String,actual:[UInt8],expected:[UInt8])throws {
        let errors=zip(actual,expected).map {abs(Int($0)-Int($1))}
        Self.comparisons.append(["name":name,"maximumChannelDifference":errors.max() ?? 0,"channelsOver2":errors.filter {$0>2}.count,"alphaOver2":errors.enumerated().filter {$0.offset%4==3 && $0.element>2}.count])
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        try JSONSerialization.data(withJSONObject:["scope":"phase 3 setup renderer","channelTolerance":2,"comparisons":Self.comparisons],options:[.prettyPrinted,.sortedKeys]).write(to:output.appendingPathComponent("gpu-validation.json"))
    }
    func testPublicGoblinsSetupRendersBothSkins()throws {
        let asset=try goblinAsset()
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        for skin in ["goblin","goblingirl"] {
            let skeleton=try Skeleton(meshAsset:asset,skin:skin)
            skeleton.position=CGPoint(x:256,y:70);skeleton.setScale(0.8)
            let image=try captureSetup(skeleton),pixels=try setupPixels(image)
            let occupied=stride(from:3,to:pixels.count,by:4).filter {pixels[$0]>0}.count
            XCTAssertGreaterThan(occupied,5000)
            try XCTUnwrap(NSBitmapImageRep(cgImage:image).representation(using:.png,properties:[:])).write(to:output.appendingPathComponent(skin+".png"))
        }
    }
    func testPairPmaTintAndSharedEdgeMatchNativeSprite()throws {
        for tinted in [false,true] {
            let textures=TestMeshTextures(),raw:[Float]=[128,64,32,128]
            var json=simpleMeshJSON()
            var tint=SIMD4<Float>(repeating:1)
            if tinted {
                var slots=json["slots"] as! [[String:Any]];slots[0]["color"]="80ff40c0";json["slots"]=slots
                editMeshAttachment(&json) {$0["color"]="ff808080"}
                tint=SIMD4<Float>(128/255,128/255,64/255,(192/255)*(128/255))
            }
            let skeleton=try Skeleton(meshAsset:SpineMeshAsset(json:jsonData(json),textures:textures))
            skeleton.position=CGPoint(x:32,y:32);skeleton.alpha=0.5
            let actual=try setupPixels(captureSetup(skeleton,size:CGSize(width:128,height:128)))
            let expectedRGBA:[UInt8]=[UInt8((raw[0]*tint.x*tint.w).rounded()),UInt8((raw[1]*tint.y*tint.w).rounded()),UInt8((raw[2]*tint.z*tint.w).rounded()),UInt8((raw[3]*tint.w).rounded())]
            let texture=TestMeshTextures(rgba:expectedRGBA).texture
            let sprite=SKSpriteNode(texture:texture,size:CGSize(width:64,height:64));sprite.anchorPoint = .zero;sprite.position=CGPoint(x:32,y:32);sprite.alpha=0.5
            let expected=try setupPixels(captureSetup(sprite,size:CGSize(width:128,height:128)))
            try record("native-quad-tint-\(tinted)",actual:actual,expected:expected)
            let errors=zip(actual,expected).map {abs(Int($0)-Int($1))}
            XCTAssertLessThanOrEqual(errors.max() ?? 255,2,"tinted=\(tinted)")
            // Includes all diagonal pixels; no separate shared-edge alpha allowance.
            XCTAssertEqual(errors.enumerated().filter {$0.offset%4==3 && $0.element>2}.count,0)
        }
    }

    func testPairedAndFourTriangleGroupsMatchSingleThroughFoldReflectionAndDegenerateRecovery()throws {
        let texture=TestMeshTextures().texture,uv:[SIMD2<Float>]=[SIMD2(0,0),SIMD2(1,0),SIMD2(1,1),SIMD2(0,1)]
        let normal:[SIMD2<Float>]=[SIMD2(0,0),SIMD2(64,0),SIMD2(64,64),SIMD2(0,64)]
        let indices=[0,1,2,0,2,3,2,1,0]
        for group in [MeshTriangleNode.GroupSize.two,.four] {
            for reflected in [false,true] {
                func render(_ size:MeshTriangleNode.GroupSize)throws->[UInt8] {
                    let material=MeshTriangleNode.Material(texture:texture,pixelSize:texture.size(),groupSize:size)
                    let node=try MeshTriangleNode(material:material,positions:normal,uvs:uv,indices:indices)
                    node.position=CGPoint(x:80,y:32);node.xScale=reflected ? -1:1;node.alpha=0.6;node.setTint(SIMD4(0.7,0.3,1,0.8))
                    try node.updatePositions(Array(repeating:.zero,count:4))
                    try node.updatePositions(normal)
                    return try setupPixels(captureSetup(node,size:CGSize(width:160,height:128)))
                }
                let expected=try render(.one),actual=try render(group)
                try record("group-\(group.rawValue)-reflection-\(reflected)",actual:actual,expected:expected)
                XCTAssertLessThanOrEqual(zip(expected,actual).map {abs(Int($0)-Int($1))}.max() ?? 255,2)
            }
        }
    }

    func testTrimRotationAndPmaMeshMatchesNativeRegionWithNearestFiltering()throws {
        let provider=try authoredTextures()
        var expectedJSON=simpleMeshJSON()
        editMeshAttachment(&expectedJSON) {$0=["path":"plain","width":96,"height":112]}
        let expected=try Skeleton(meshAsset:SpineMeshAsset(json:jsonData(expectedJSON),textures:provider));expected.position=CGPoint(x:64,y:64)
        let reference=try setupPixels(captureSetup(expected,size:CGSize(width:128,height:128)))
        XCTAssertTrue(reference.enumerated().contains {$0.offset%4==3 && $0.element>0})
        let trimUV:[Double]=[2.0/12,1-3.0/14,10.0/12,1-3.0/14,10.0/12,1-9.0/14,2.0/12,1-9.0/14]
        for path in ["rotated","pma-plain","pma-rotated"] {
            var json=simpleMeshJSON()
            editMeshAttachment(&json) {
                $0["path"]=path;$0["vertices"]=[-32,-32,32,-32,32,16,-32,16]
                $0["uvs"]=trimUV
            }
            let actual=try Skeleton(meshAsset:SpineMeshAsset(json:jsonData(json),textures:provider));actual.position=CGPoint(x:64,y:64)
            let pixels=try setupPixels(captureSetup(actual,size:CGSize(width:128,height:128)))
            try record("trim-"+path,actual:pixels,expected:reference)
            XCTAssertLessThanOrEqual(zip(pixels,reference).map {abs(Int($0)-Int($1))}.max() ?? 255,2,path)
        }
    }

}
#endif
