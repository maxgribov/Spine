#if os(macOS)
import XCTest
import AppKit
import SpriteKit
import Metal
@testable import Spine

private final class ProjectionScene:SKScene {
    var finishedFrame:((ProjectionScene)->Void)?
    override func didFinishUpdate() {finishedFrame?(self)}
}

final class NativeFrameProjectionTests:XCTestCase {
    private final class Host {
        let window:NSWindow
        let view:SKView
        let scene:ProjectionScene
        let parent=SKNode()
        let camera=SKCameraNode()
        init(size:CGSize,mode:SKSceneScaleMode,anchor:CGPoint) {
            view=SKView(frame:CGRect(origin:.zero,size:size))
            window=NSWindow(contentRect:view.frame,styleMask:[.titled],backing:.buffered,defer:false)
            window.isReleasedWhenClosed=false;window.contentView=view;window.title="Spine frame projection validation"
            scene=ProjectionScene(size:CGSize(width:260,height:220));scene.scaleMode=mode;scene.anchorPoint=anchor;scene.backgroundColor = .clear
            scene.addChild(parent);scene.addChild(camera);scene.camera=camera
            camera.position=CGPoint(x:130,y:110)
        }
        func close() {scene.finishedFrame=nil;view.presentScene(nil);window.orderOut(nil);window.close()}
    }

    private func capture(reference:Bool,caseIndex:Int,viewportOffset:CGPoint)throws->([UInt8],Int,Int) {
        _=NSApplication.shared
        let sizes=[CGSize(width:260,height:220),CGSize(width:330,height:190),CGSize(width:240,height:280)]
        let modes:[SKSceneScaleMode]=[.aspectFit,.aspectFill,.resizeFill]
        let host=Host(size:sizes[caseIndex%sizes.count],mode:modes[caseIndex%modes.count],anchor:CGPoint(x:0.3,y:0.7))
        defer {host.close()}
        let provider=TestMeshTextures()
        let skeleton:Skeleton?
        let actor:SKNode
        if reference {
            skeleton=nil;actor=SKNode()
            // Independent full-bounds, single-triangle reference. Its fragment
            // position comes from interpolated UV, never the production pixel matrix.
            let c=Float(cos(0.12)),s=Float(sin(0.12))
            let vertices:[SIMD2<Float>]=[SIMD2(0,0),SIMD2(64,0),SIMD2(64,64),SIMD2(0,64)].map {
                SIMD2(4+c*1.1*$0.x-s*0.8*$0.y,-3+s*1.1*$0.x+c*0.8*$0.y)
            }
            let sprite=try MeshTriangleNode(texture:provider.texture,positions:vertices,uvs:[SIMD2(0,0),SIMD2(1,0),SIMD2(1,1),SIMD2(0,1)],indices:[0,1,2,0,2,3],boundsMode:.mesh,groupSize:.one)
            sprite.alpha=0.42
            actor.addChild(sprite)
        } else {
            let character=try Skeleton(meshAsset:SpineMeshAsset(json:jsonData(simpleMeshJSON()),textures:provider))
            skeleton=character;actor=character
        }
        actor.position=CGPoint(x:110,y:90);actor.xScale=caseIndex.isMultiple(of:2) ? 0.9:-0.9;actor.yScale=0.8;actor.alpha=0.9
        host.parent.position=CGPoint(x:8,y:-5);host.parent.zRotation=0.19;host.parent.yScale=1.1;host.parent.alpha=0.8
        host.parent.addChild(actor)
        let ready=expectation(description:"Native SKView projection is ready")
        var frames=0,error:Error?
        host.scene.finishedFrame={_ in
            frames+=1
            guard frames==2 else {return}
            do {if let skeleton=skeleton {try skeleton.prepareMeshes(in:host.view)}} catch let e {error=e}
            host.scene.finishedFrame=nil;ready.fulfill()
        }
        host.view.presentScene(host.scene);host.window.makeKeyAndOrderFront(nil)
        wait(for:[ready],timeout:3)
        if let error=error {throw error}
        actor.isPaused=true
        // Every category of late mutation requires an explicit repeat preparation.
        if let skeleton=skeleton {
            let before=skeleton.meshRuntime!.setupRenderer!.snapshot.vertices
            let bone=skeleton.boneNode(named:"root")!
            bone.position=CGPoint(x:4,y:-3);bone.zRotation=0.12;bone.xScale=1.1;bone.yScale=0.8;bone.alpha=0.6
            skeleton.slotNode(named:"slot")!.alpha=0.7
            XCTAssertEqual(skeleton.meshRuntime!.setupRenderer!.snapshot.vertices,before)
            try skeleton.prepareMeshes(in:host.view)
            XCTAssertNotEqual(skeleton.meshRuntime!.setupRenderer!.snapshot.vertices,before)
        }
        actor.position.x+=7
        if let skeleton=skeleton {try skeleton.prepareMeshes(in:host.view)}
        host.parent.position.y+=6
        if let skeleton=skeleton {try skeleton.prepareMeshes(in:host.view)}
        host.camera.position.x+=12;host.camera.zRotation=0.07;host.camera.xScale=1.15;host.camera.yScale=0.95
        if let skeleton=skeleton {
            try skeleton.prepareMeshes(in:host.view)
            XCTAssertEqual(skeleton.meshRuntime!.snapshot.time,0)
        }
        let scale=host.window.backingScaleFactor
        let viewport=CGRect(x:viewportOffset.x,y:viewportOffset.y,width:host.view.bounds.width*scale,height:host.view.bounds.height*scale)
        let width=Int(viewport.width),height=Int(viewport.height)
        if let skeleton=skeleton {
            let native=try XCTUnwrap(skeleton.meshRuntime!.preparedContext)
            let matrix=native.skeletonToPixels
            // Compare the complete native transform independently at corners and
            // pixel centers, after late camera/ancestor/root edits.
            for point in [CGPoint.zero,CGPoint(x:64,y:0),CGPoint(x:0,y:64),CGPoint(x:64,y:64),CGPoint(x:0.5,y:0.5)] {
                let inView=host.scene.convertPoint(toView:skeleton.convert(point,to:host.scene))
                let expected=CGPoint(x:inView.x*scale,y:(host.view.isFlipped ? inView.y:host.view.bounds.height-inView.y)*scale)
                let actual=point.applying(matrix)
                XCTAssertEqual(actual.x,expected.x,accuracy:0.0001)
                XCTAssertEqual(actual.y,expected.y,accuracy:0.0001)
            }
            let context=SpineMeshFrameContext(skeletonToPixels:matrix,pixelSize:CGSize(width:width,height:height))
            try skeleton.prepareMeshes(for:context);try skeleton.prepareMeshes(for:context)
        }
        guard let device=MTLCreateSystemDefaultDevice(),let queue=device.makeCommandQueue() else {throw XCTSkip("Metal unavailable")}
        // resizeFill needs an explicit fixed-size readback projection once
        // detached from the already-warmed native SKView.
        if host.scene.scaleMode == .resizeFill {host.scene.scaleMode = .aspectFit}
        let renderer=SKRenderer(device:device);renderer.ignoresSiblingOrder=false;renderer.scene=host.scene;renderer.update(atTime:0)
        let descriptor=MTLTextureDescriptor.texture2DDescriptor(pixelFormat:.bgra8Unorm,width:width,height:height,mipmapped:false)
        descriptor.usage = .renderTarget;descriptor.storageMode = .shared
        let target=try XCTUnwrap(device.makeTexture(descriptor:descriptor)),command=try XCTUnwrap(queue.makeCommandBuffer())
        let pass=MTLRenderPassDescriptor();pass.colorAttachments[0].texture=target;pass.colorAttachments[0].loadAction = .clear;pass.colorAttachments[0].storeAction = .store;pass.colorAttachments[0].clearColor=MTLClearColorMake(0,0,0,0)
        renderer.render(withViewport:viewport,commandBuffer:command,renderPassDescriptor:pass);command.commit();command.waitUntilCompleted()
        XCTAssertEqual(command.status,.completed)
        var pixels=Array(repeating:UInt8(0),count:width*height*4)
        pixels.withUnsafeMutableBytes {target.getBytes($0.baseAddress!,bytesPerRow:width*4,from:MTLRegionMake2D(0,0,width,height),mipmapLevel:0)}
        renderer.scene=nil
        return (pixels,width,height)
    }

    func testCustomCroppedViewportUsesExplicitOffsetAndBottomLeftPixelCenters()throws {
        let size=CGSize(width:180,height:170),crop=CGRect(x:11,y:17,width:128,height:128)
        let provider=TestMeshTextures()
        func render(_ mesh:Bool)throws->[UInt8] {
            let host=Host(size:size,mode:.aspectFit,anchor:.zero)
            defer {host.close()}
            host.scene.size=size;host.scene.camera=nil
            let node:SKNode
            if mesh {node=try Skeleton(meshAsset:SpineMeshAsset(json:jsonData(simpleMeshJSON()),textures:provider))}
            else {let sprite=SKSpriteNode(texture:provider.texture,size:CGSize(width:64,height:64));sprite.anchorPoint = .zero;node=sprite}
            node.position=CGPoint(x:32,y:36);host.parent.addChild(node);host.view.presentScene(host.scene)
            let scale=host.window.backingScaleFactor
            if let skeleton=node as? Skeleton {
                // texture(from:crop:) fragments use a bottom-left Y convention,
                // unlike the top-left Metal-native projection above.
                let context=SpineMeshFrameContext(skeletonToPixels:CGAffineTransform(a:scale,b:0,c:0,d:scale,tx:(node.position.x-crop.minX)*scale,ty:(node.position.y-crop.minY)*scale),pixelSize:CGSize(width:crop.width*scale,height:crop.height*scale))
                try skeleton.prepareMeshes(for:context)
            }
            let image=try XCTUnwrap(host.view.texture(from:host.parent,crop:crop)).cgImage()
            return try setupPixels(image)
        }
        let actual=try render(true),expected=try render(false)
        XCTAssertEqual(actual.count,expected.count)
        XCTAssertGreaterThan(actual.enumerated().filter {$0.offset%4==3 && $0.element>0}.count,100)
        let differences=zip(actual,expected).map {abs(Int($0)-Int($1))}
        XCTAssertLessThanOrEqual(differences.max() ?? 255,2)
    }

    func testNativeCameraResizeScaleModesAndLatePreparationMapCornersAndPixelCenters()throws {
        var report:[[String:Any]]=[]
        for index in 0..<3 {
            let offset=CGPoint.zero
            let actual=try capture(reference:false,caseIndex:index,viewportOffset:offset)
            let expected=try capture(reference:true,caseIndex:index,viewportOffset:offset)
            XCTAssertEqual(actual.1,expected.1);XCTAssertEqual(actual.2,expected.2)
            let differences=zip(actual.0,expected.0).map {abs(Int($0)-Int($1))}
            let maximum=differences.max() ?? 255
            // Supplementary hard-edged silhouette diagnostic, not the image
            // acceptance gate. The strict camera gate compares eight textured
            // production worlds with the retained prototype reference.

            XCTAssertGreaterThan(actual.0.enumerated().filter {$0.offset%4==3 && $0.element>0}.count,100)
            let output=URL(fileURLWithPath:"/tmp/spine-phase4-projection")
            try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
            for (kind,result) in [("actual",actual),("reference",expected)] {
                let provider=CGDataProvider(data:Data(result.0) as CFData)!
                let image=CGImage(width:result.1,height:result.2,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:result.1*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue),provider:provider,decode:nil,shouldInterpolate:false,intent:.defaultIntent)!
                try NSBitmapImageRep(cgImage:image).representation(using:.png,properties:[:])!.write(to:output.appendingPathComponent("case-\(index)-\(kind).png"))
            }
            report.append(["scope":"supplementary opaque silhouette diagnostic; not an image acceptance pass","case":index,"width":actual.1,"height":actual.2,"maximumChannelDifference":maximum,"channelsOver2":differences.filter {$0>2}.count,"channelsOver3":differences.filter {$0>3}.count])
        }
        let output=URL(fileURLWithPath:ProcessInfo.processInfo.environment["SPINE_MESH_VALIDATION_OUTPUT"] ?? "/tmp/spine-phase4-projection")
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        try JSONSerialization.data(withJSONObject:report,options:[.prettyPrinted,.sortedKeys]).write(to:output.appendingPathComponent("frame-projection.json"))
    }
}
#endif
