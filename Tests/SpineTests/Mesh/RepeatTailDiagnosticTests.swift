#if os(macOS)
import XCTest
import AppKit
import SpriteKit
import Metal
@testable import Spine

private final class RepeatTailScene:SKScene {
    var actionMS=0.0
    private var begin=0.0
    override func update(_ currentTime:TimeInterval) {begin=CACurrentMediaTime()}
    override func didEvaluateActions() {actionMS=(CACurrentMediaTime()-begin)*1000}
}
final class RepeatTailDiagnosticTests:XCTestCase {
    func testTraceSynchronousRepeatFrameTails()throws {
        guard let path=ProcessInfo.processInfo.environment["SPINE_REPEAT_TAIL_OUTPUT"] else {throw XCTSkip("Opt-in Release diagnostic, not acceptance timing")}
        _=NSApplication.shared
        let asset=try goblinAsset(),device=try XCTUnwrap(MTLCreateSystemDefaultDevice()),queue=try XCTUnwrap(device.makeCommandQueue())
        let scene=RepeatTailScene(size:CGSize(width:1920,height:1080));scene.scaleMode = .aspectFit
        let actors=try (0..<50).map {try Skeleton(meshAsset:asset,skin:$0.isMultiple(of:2) ? "goblin":"goblingirl")}
        for (i,actor) in actors.enumerated() {
            actor.setScale(0.65);actor.position=CGPoint(x:120+CGFloat(i%10)*1680/9,y:50+CGFloat(i/10)*730/4);actor.zPosition=CGFloat(i)*200
            scene.addChild(actor);actor.run(.repeatForever(try actor.action(animation:"walk")))
        }
        let renderer=SKRenderer(device:device);renderer.scene=scene;renderer.ignoresSiblingOrder=false;renderer.shouldCullNonVisibleNodes=true
        defer {renderer.scene=nil}
        let descriptor=MTLTextureDescriptor.texture2DDescriptor(pixelFormat:.bgra8Unorm,width:1920,height:1080,mipmapped:false);descriptor.usage = .renderTarget;descriptor.storageMode = .private
        let target=try XCTUnwrap(device.makeTexture(descriptor:descriptor)),pass=MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture=target;pass.colorAttachments[0].loadAction = .clear;pass.colorAttachments[0].storeAction = .store
        var records=[[String:Any]]();records.reserveCapacity(330)
        var previousBegin:UInt64=0,previousEnd:UInt64=0
        for frame in 0..<330 {
            try autoreleasepool {
                let start=CACurrentMediaTime();renderer.update(atTime:100+Double(frame)/30);let updated=CACurrentMediaTime()
                for actor in actors {
                    let o=actor.convert(CGPoint.zero,to:scene),x=actor.convert(CGPoint(x:1024,y:0),to:scene),y=actor.convert(CGPoint(x:0,y:1024),to:scene)
                    try actor.prepareMeshes(for:SpineMeshFrameContext(skeletonToPixels:CGAffineTransform(a:(x.x-o.x)/1024,b:-(x.y-o.y)/1024,c:(y.x-o.x)/1024,d:-(y.y-o.y)/1024,tx:o.x,ty:1080-o.y),pixelSize:scene.size))
                }
                let prepared=CACurrentMediaTime(),command=try XCTUnwrap(queue.makeCommandBuffer())
                renderer.render(withViewport:CGRect(x:0,y:0,width:1920,height:1080),commandBuffer:command,renderPassDescriptor:pass)
                let encoded=CACurrentMediaTime();command.commit();command.waitUntilCompleted()
                XCTAssertEqual(command.status,.completed)
                let begins=actors.reduce(UInt64(0)) {$0+$1.meshRuntime!.snapshot.beginCount},ends=actors.reduce(UInt64(0)) {$0+$1.meshRuntime!.snapshot.endCount}
                records.append(["frame":frame,"time":Double(frame)/30,"clipTime":actors[0].meshRuntime!.snapshot.time,"begins":begins-previousBegin,"ends":ends-previousEnd,"actionMS":scene.actionMS,"updateMS":(updated-start)*1000,"prepareMS":(prepared-updated)*1000,"encodeMS":(encoded-prepared)*1000,"totalCPUms":(encoded-start)*1000,"gpuMS":(command.gpuEndTime-command.gpuStartTime)*1000])
                previousBegin=begins;previousEnd=ends
            }
        }
        try JSONSerialization.data(withJSONObject:["kind":"offscreen30Hz repeat-tail diagnosis; not native FPS acceptance","actors":50,"frames":records],options:[.prettyPrinted,.sortedKeys]).write(to:URL(fileURLWithPath:path))
    }
}
#endif
