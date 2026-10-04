#if os(macOS)
import XCTest
import AppKit
import SpriteKit
import Metal
@testable import Spine

/// Same immutable pose input, independent one-triangle shader, before timed runs.
/// The external 4.1.56 oracle separately validates the compiler/skinning input.
final class BenchmarkReferenceExportTests:XCTestCase {
    func testExportSingleTriangleBenchmarkReferences()throws {
        guard let destination=ProcessInfo.processInfo.environment["SPINE_BENCHMARK_REFERENCE_OUTPUT"] else {return}
        _=NSApplication.shared
        let output=URL(fileURLWithPath:destination)
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        let source=try goblinAsset(),asset=SpineMeshAsset(compiled:source.compiled,diagnosticGroupSize:.one)
        let device=try XCTUnwrap(MTLCreateSystemDefaultDevice()),queue=try XCTUnwrap(device.makeCommandQueue())
        for count in [1,10,50] {
            let scene=SKScene(size:CGSize(width:1920,height:1080));scene.scaleMode = .aspectFit;scene.backgroundColor=NSColor(calibratedWhite:0.1,alpha:1)
            let actors=try (0..<count).map {try Skeleton(meshAsset:asset,skin:$0.isMultiple(of:2) ? "goblin":"goblingirl")}
            let columns=min(count,count<=10 ? 5:10),rows=(count+columns-1)/columns
            for (index,actor) in actors.enumerated() {
                actor.setScale(0.65);actor.position=CGPoint(x:120+CGFloat(index%columns)*1680/CGFloat(max(columns-1,1)),y:50+CGFloat(index/columns)*730/CGFloat(max(rows-1,1)));actor.zPosition=CGFloat(index)*200;scene.addChild(actor)
                actor.run(.repeatForever(try actor.action(animation:"walk")))
            }
            let renderer=SKRenderer(device:device);renderer.scene=scene;renderer.ignoresSiblingOrder=false;renderer.shouldCullNonVisibleNodes=true
            for frame in 0..<90 {renderer.update(atTime:100+Double(frame)/60)}
            for actor in actors {
                let o=actor.convert(.zero,to:scene),x=actor.convert(CGPoint(x:1024,y:0),to:scene),y=actor.convert(CGPoint(x:0,y:1024),to:scene)
                try actor.prepareMeshes(for:SpineMeshFrameContext(skeletonToPixels:CGAffineTransform(a:(x.x-o.x)/1024,b:-(x.y-o.y)/1024,c:(y.x-o.x)/1024,d:-(y.y-o.y)/1024,tx:o.x,ty:1080-o.y),pixelSize:scene.size))
            }
            let descriptor=MTLTextureDescriptor.texture2DDescriptor(pixelFormat:.bgra8Unorm,width:1920,height:1080,mipmapped:false);descriptor.usage = .renderTarget;descriptor.storageMode = .shared
            let target=try XCTUnwrap(device.makeTexture(descriptor:descriptor)),command=try XCTUnwrap(queue.makeCommandBuffer()),pass=MTLRenderPassDescriptor()
            pass.colorAttachments[0].texture=target;pass.colorAttachments[0].loadAction = .clear;pass.colorAttachments[0].storeAction = .store
            renderer.render(withViewport:CGRect(x:0,y:0,width:1920,height:1080),commandBuffer:command,renderPassDescriptor:pass);command.commit();command.waitUntilCompleted();XCTAssertEqual(command.status,.completed)
            var data=Data(count:1920*1080*4);data.withUnsafeMutableBytes {target.getBytes($0.baseAddress!,bytesPerRow:1920*4,from:MTLRegionMake2D(0,0,1920,1080),mipmapLevel:0)}
            let provider=try XCTUnwrap(CGDataProvider(data:data as CFData)),image=try XCTUnwrap(CGImage(width:1920,height:1080,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:1920*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue),provider:provider,decode:nil,shouldInterpolate:false,intent:.defaultIntent))
            let bytes=try setupPixels(image),foreground=stride(from:0,to:bytes.count,by:4).filter {i in (0..<3).contains {abs(Int(bytes[i+$0])-Int(bytes[$0]))>8}}.count
            XCTAssertGreaterThan(foreground,1000)
            try XCTUnwrap(NSBitmapImageRep(cgImage:image).representation(using:.png,properties:[:])).write(to:output.appendingPathComponent("single-\(count).png"))
            renderer.scene=nil
        }
    }
}
#endif
