// Validation host only. The build script compiles the repository's production Spine sources unchanged.
import UIKit
import SpriteKit
import Metal

private struct ProbeFailure:Error {let message:String}
private final class ProbeTextures:SpineMeshTextureProvider {
    let texture:SKTexture
    init(_ rgba:[UInt8]) {texture=SKTexture(data:Data(Array(repeating:rgba,count:16).flatMap{$0}),size:CGSize(width:4,height:4));texture.filteringMode = .nearest}
    func region(named:String)throws->SpineMeshTextureRegion {
        try SpineMeshTextureRegion(texture:texture,pixelSize:CGSize(width:4,height:4),originalSize:CGSize(width:4,height:4),trimRect:CGRect(x:0,y:0,width:4,height:4),uvTransform:.identity)
    }
}
private func meshJSON(path:String="mesh",uv:[Double]=[0,1,1,1,1,0,0,0],vertices:[Double]=[0,0,64,0,64,64,0,64],tint:Bool=false,region:Bool=false)throws->Data {
    let attachment:[String:Any]=region ? ["path":path,"width":96,"height":112] : ["type":"mesh","path":path,"uvs":uv,"vertices":vertices,"triangles":[0,1,2,0,2,3],"color":tint ? "ff808080":"ffffffff"]
    return try JSONSerialization.data(withJSONObject:["skeleton":["hash":"device-proof","spine":"4.1.17","x":0,"y":0,"width":128,"height":128],"bones":[["name":"root"]],"slots":[["name":"slot","bone":"root","attachment":"mesh","color":tint ? "80ff40c0":"ffffffff"]],"skins":[["name":"default","attachments":["slot":["mesh":attachment]]]]])
}
private final class WarmupScene:SKScene {
    var frames=0
    var prepareFailures=0
    var ready:(()->Void)?
    let skeleton:Skeleton
    init(skeleton:Skeleton,size:CGSize) {self.skeleton=skeleton;super.init(size:size);backgroundColor = .darkGray;scaleMode = .aspectFit;anchorPoint=CGPoint(x:0.5,y:0.5);addChild(skeleton);skeleton.position=CGPoint(x:80,y:80)}
    required init?(coder:NSCoder) {fatalError()}
    override func didFinishUpdate() {
        do {if skeleton.scene === self,let view=view {try skeleton.prepareMeshes(in:view)}} catch {prepareFailures+=1;print("Native prepare failed",error)}
        frames+=1
        if frames==30 {let callback=ready;ready=nil;DispatchQueue.main.async {callback?()}}
    }
}
private final class DeviceGate {
    let view:SKView
    let device:MTLDevice
    let queue:MTLCommandQueue
    var cases:[[String:Any]]=[]
    init(view:SKView)throws {
        self.view=view
        guard let device=MTLCreateSystemDefaultDevice(),let queue=device.makeCommandQueue() else {throw ProbeFailure(message:"Metal unavailable")}
        self.device=device;self.queue=queue
    }
    func render(_ node:SKNode)throws->[UInt8] {
        guard let scene=view.scene else {throw ProbeFailure(message:"Native scene is missing")}
        scene.removeAllChildren();scene.backgroundColor = .clear;scene.addChild(node)
        view.presentScene(scene)
        let scale=view.contentScaleFactor,width=Int((view.bounds.width*scale).rounded()),height=Int((view.bounds.height*scale).rounded())
        if let skeleton=node as? Skeleton {try skeleton.prepareMeshes(in:view)}
        else if let mesh=node as? MeshTriangleNode {
            func p(_ v:CGPoint)->CGPoint {let x=scene.convertPoint(toView:node.convert(v,to:scene));return CGPoint(x:x.x*scale,y:x.y*scale)}
            let o=p(.zero),x=p(CGPoint(x:1024,y:0)),y=p(CGPoint(x:0,y:1024))
            try mesh.prepareForRendering(localToPixels:CGAffineTransform(a:(x.x-o.x)/1024,b:(x.y-o.y)/1024,c:(y.x-o.x)/1024,d:(y.y-o.y)/1024,tx:o.x,ty:o.y))
        }
        let renderer=SKRenderer(device:device);renderer.scene=scene;renderer.ignoresSiblingOrder=false;renderer.update(atTime:0)
        let descriptor=MTLTextureDescriptor.texture2DDescriptor(pixelFormat:.bgra8Unorm,width:width,height:height,mipmapped:false)
        descriptor.usage = .renderTarget;descriptor.storageMode = .shared
        guard let target=device.makeTexture(descriptor:descriptor),let command=queue.makeCommandBuffer() else {throw ProbeFailure(message:"Target allocation failed")}
        let pass=MTLRenderPassDescriptor();pass.colorAttachments[0].texture=target;pass.colorAttachments[0].loadAction = .clear;pass.colorAttachments[0].storeAction = .store;pass.colorAttachments[0].clearColor=MTLClearColorMake(0,0,0,0)
        renderer.render(withViewport:CGRect(x:0,y:0,width:width,height:height),commandBuffer:command,renderPassDescriptor:pass)
        command.commit();command.waitUntilCompleted()
        guard command.status == .completed else {throw ProbeFailure(message:"GPU command failed: \(String(describing:command.error))")}
        var data=Array(repeating:UInt8(0),count:width*height*4)
        data.withUnsafeMutableBytes {target.getBytes($0.baseAddress!,bytesPerRow:width*4,from:MTLRegionMake2D(0,0,width,height),mipmapLevel:0)}
        renderer.scene=nil;node.removeFromParent()
        return data
    }
    func compare(_ name:String,_ actual:SKNode,_ reference:SKNode)throws {
        let a=try render(actual),b=try render(reference)
        var maximum=0,over2=0,alphaOver2=0,occupied=0
        for i in a.indices {
            let d=abs(Int(a[i])-Int(b[i]));maximum=max(maximum,d)
            if d>2 {over2+=1;if i%4==3 {alphaOver2+=1}}
            if i%4==3 && (a[i-3]>0 || a[i-2]>0 || a[i-1]>0) {occupied+=1}
        }
        cases.append(["name":name,"maximumChannelDifference":maximum,"channelsOver2":over2,"alphaOver2":alphaOver2,"occupiedPixels":occupied])
        let width=Int((view.bounds.width*view.contentScaleFactor).rounded()),height=Int((view.bounds.height*view.contentScaleFactor).rounded())
        for (suffix,pixels) in [("actual",a),("reference",b)] {
            let provider=CGDataProvider(data:Data(pixels) as CFData)!
            let image=CGImage(width:width,height:height,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue),provider:provider,decode:nil,shouldInterpolate:false,intent:.defaultIntent)!
            let url=deviceOutput.appendingPathComponent(name+"-"+suffix+".png")
            try UIImage(cgImage:image).pngData()!.write(to:url)
        }
        guard occupied>100 else {throw ProbeFailure(message:"\(name) has no visible test geometry")}
        guard maximum<=2 else {throw ProbeFailure(message:"\(name) max channel difference \(maximum)")}
    }
    func run()throws {
        for tinted in [false,true] {
            let textures=ProbeTextures([128,64,32,128])
            let actual=try Skeleton(meshAsset:SpineMeshAsset(json:meshJSON(tint:tinted),textures:textures));actual.position=CGPoint(x:-40,y:-35);actual.alpha=0.5
            let tint=tinted ? SIMD4<Float>(128/255,128/255,64/255,(192/255)*(128/255)):SIMD4<Float>(repeating:1)
            let rgba=[UInt8((128*tint.x*tint.w).rounded()),UInt8((64*tint.y*tint.w).rounded()),UInt8((32*tint.z*tint.w).rounded()),UInt8((128*tint.w).rounded())]
            let reference=SKSpriteNode(texture:ProbeTextures(rgba).texture,size:CGSize(width:64,height:64));reference.anchorPoint = .zero;reference.position=actual.position;reference.alpha=actual.alpha
            try compare(tinted ? "native-frame-pair-pma-tint":"native-frame-pair-shared-edge",actual,reference)
        }
        let root=Bundle.main.bundleURL
        let atlas=try String(contentsOf:root.appendingPathComponent("authored.atlas"),encoding:.utf8)
        let provider=try SpineAtlasTextureProvider(atlasText:atlas,pageData:["authored-straight.png":Data(contentsOf:root.appendingPathComponent("authored-straight.png")),"authored-pma.png":Data(contentsOf:root.appendingPathComponent("authored-pma.png"))])
        let uv:[Double]=[2/12,1-3/14,10/12,1-3/14,10/12,1-9/14,2/12,1-9/14]
        let vertices:[Double]=[-32,-32,32,-32,32,16,-32,16]
        for path in ["rotated","pma-plain","pma-rotated"] {
            let actual=try Skeleton(meshAsset:SpineMeshAsset(json:meshJSON(path:path,uv:uv,vertices:vertices),textures:provider))
            let reference=try Skeleton(meshAsset:SpineMeshAsset(json:meshJSON(path:"plain",region:true),textures:provider))
            try compare("trim-rotation-"+path,actual,reference)
        }
        let texture=ProbeTextures([128,64,32,128]).texture
        let positions:[SIMD2<Float>]=[SIMD2(0,0),SIMD2(64,0),SIMD2(64,64),SIMD2(0,64)]
        let uvFloat:[SIMD2<Float>]=[SIMD2(0,0),SIMD2(1,0),SIMD2(1,1),SIMD2(0,1)]
        let indices=[0,1,2,0,2,3,2,1,0]
        let one=try MeshTriangleNode(material:MeshTriangleNode.Material(texture:texture,pixelSize:texture.size(),groupSize:.one),positions:positions,uvs:uvFloat,indices:indices)
        let pair=try MeshTriangleNode(material:MeshTriangleNode.Material(texture:texture,pixelSize:texture.size()),positions:positions,uvs:uvFloat,indices:indices)
        for node in [one,pair] {node.position=CGPoint(x:40,y:-32);node.xScale = -1;node.alpha=0.6;node.setTint(SIMD4(0.7,0.3,1,0.8))}
        try compare("fold-reflection-odd-tail",pair,one)
        // Real action-driven color/deform/draw-order and attachment transitions,
        // including compatible/incompatible skins, on this physical GPU.
        let transitionAsset=try authoredAsset("slot-transitions")
        let transitionReference=SpineMeshAsset(compiled:transitionAsset.compiled,diagnosticGroupSize:.one)
        func pose(_ asset:SpineMeshAsset,skin:String,time:Double)throws->Skeleton {
            let h=try DeviceActionHarness(asset:asset);try h.skeleton.apply(skin:skin)
            h.start(try h.skeleton.action(animation:"switches"));h.update(time)
            h.skeleton.stopMeshAnimation();h.skeleton.removeAllActions();h.skeleton.removeFromParent()
            h.skeleton.position=CGPoint(x:-40,y:-20);h.skeleton.setScale(2)
            return h.skeleton
        }
        for skin in ["default","compatible","incompatible"] {
            for (index,time) in [0.1,0.3,0.5,0.7,0.9].enumerated() {
                try compare("animated-\(skin)-\(index)",pose(transitionAsset,skin:skin,time:time),pose(transitionReference,skin:skin,time:time))
            }
        }
    }
}
@UIApplicationMain final class MeshDeviceApp:UIResponder,UIApplicationDelegate {
    var window:UIWindow?
    var releaseCoordinator:DeviceReleaseCoordinator?
    func application(_ application:UIApplication,didFinishLaunchingWithOptions options:[UIApplication.LaunchOptionsKey:Any]?)->Bool {
        application.isIdleTimerDisabled=true
        let window=UIWindow(frame:UIScreen.main.bounds),controller=UIViewController(),root=UIView(frame:window.bounds)
        root.backgroundColor = .black;controller.view=root;window.rootViewController=controller;self.window=window
        let label=UILabel(frame:CGRect(x:16,y:45,width:350,height:45));label.textColor = .white;label.text="Spine production device validation";label.numberOfLines=2;root.addSubview(label)
        let view=SKView(frame:CGRect(x:16,y:110,width:256,height:256));view.ignoresSiblingOrder=false;root.addSubview(view);window.makeKeyAndVisible()
        do {
            let runID=ProcessInfo.processInfo.environment["SPINE_VALIDATION_RUN_ID"] ?? ""
            let manifest=try Data(contentsOf:Bundle.main.bundleURL.appendingPathComponent("source-sha256.json"))
            let context=try DeviceRunContext(base:FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0],runID:runID,sourceManifest:manifest)
            DeviceRunContext.current=context
            let skeleton=try Skeleton(meshAsset:SpineMeshAsset(json:meshJSON(),textures:ProbeTextures([128,64,32,128])))
            let scene=WarmupScene(skeleton:skeleton,size:view.bounds.size)
            scene.ready={
                var report:[String:Any]=["phase":5,"scope":"six setup cases plus fifteen action-driven synthetic transition cases on current sources","productionRenderer":true,"os":UIDevice.current.systemVersion,"device":UIDevice.current.model,"nativeSKViewFrames":30,"nativePrepareFailures":scene.prepareFailures,"pixelSize":[Int(view.bounds.width*view.contentScaleFactor),Int(view.bounds.height*view.contentScaleFactor)],"readback":"SKRenderer on physical device with native SKView frame mapping"]
                var failure:Error?
                do {guard scene.prepareFailures==0 else {throw ProbeFailure(message:"Native warmup prepare failed")};let gate=try DeviceGate(view:view);defer {report["cases"]=gate.cases};try gate.run();report["status"]="passed";label.text="PASS: setup + animated transitions"}
                catch {failure=error;report["status"]="failed";report["error"]=String(describing:error);label.text="FAIL: \(error)"}
                do {
                    try deviceReport("production-gate.json",payload:report,status:failure==nil ? "completed":"failed")
                    if let failure=failure {try context.fail(failure);application.isIdleTimerDisabled=false}
                    else {
                        try context.markCompleted("render")
                        let release=DeviceReleaseCoordinator(view:view,label:label);self.releaseCoordinator=release
                        DispatchQueue.main.async {release.start()}
                    }
                } catch {
                    label.text="REPORT FAILURE: \(error)";print("Report failure",error)
                    do {try context.fail(error)} catch {print("Could not persist failed run",error)}
                    application.isIdleTimerDisabled=false
                }
            }
            view.presentScene(scene)
        } catch {
            label.text="Load failed: \(error)";print("Validation startup failed",error)
            if let context=DeviceRunContext.current {do {try context.fail(error)} catch {print("Could not persist startup failure",error)}}
            application.isIdleTimerDisabled=false
        }
        return true
    }
}
