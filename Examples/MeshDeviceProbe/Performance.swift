import UIKit
import SpriteKit
import Metal

private func deviceStats(_ values:[Double])->[String:Double] {
    let sorted=values.sorted();guard !sorted.isEmpty else {return [:]}
    return ["p50":sorted[(sorted.count-1)/2],"p95":sorted[Int(Double(sorted.count-1)*0.95)],"mean":values.reduce(0,+)/Double(values.count),"samples":Double(values.count)]
}
private final class DevicePerformanceScene:SKScene {
    let actors:[Skeleton]
    var complete:(([String:Any])->Void)?
    var failure:Error?
    var lastPoseMS=0.0
    private var begin=0.0,actionMS=0.0,previous:Double?,tick=0
    private var samples=[Double](),intervals=[Double]()
    private let thermalStart=ProcessInfo.processInfo.thermalState.rawValue
    init(count:Int,asset:SpineMeshAsset)throws {
        actors=try (0..<count).map {try Skeleton(meshAsset:asset,skin:$0.isMultiple(of:2) ? "goblin":"goblingirl")}
        super.init(size:CGSize(width:1920,height:1080));scaleMode = .aspectFit;backgroundColor=UIColor(white:0.1,alpha:1)
        let columns=min(count,count<=10 ? 5:10),rows=(count+columns-1)/columns
        for (index,actor) in actors.enumerated() {
            actor.setScale(0.65);actor.position=CGPoint(x:120+CGFloat(index%columns)*1680/CGFloat(max(columns-1,1)),y:50+CGFloat(index/columns)*730/CGFloat(max(rows-1,1)));actor.zPosition=CGFloat(index)*200;addChild(actor)
            actor.run(.repeatForever(try actor.action(animation:"walk")))
        }
    }
    required init?(coder:NSCoder) {fatalError()}
    override func update(_ currentTime:TimeInterval) {
        begin=CACurrentMediaTime()
        if complete != nil,tick>=30,let previous=previous {intervals.append((currentTime-previous)*1000)}
        previous=currentTime
    }
    override func didEvaluateActions() {actionMS=(CACurrentMediaTime()-begin)*1000}
    override func didFinishUpdate() {
        guard let view=view else {lastPoseMS=actionMS;return}
        let start=CACurrentMediaTime()
        do {for actor in actors {try actor.prepareMeshes(in:view)}} catch {failure=error}
        lastPoseMS=actionMS+(CACurrentMediaTime()-start)*1000
        guard let callback=complete else {return}
        if tick>=30 {samples.append(lastPoseMS)};tick+=1
        if tick==150 {
            complete=nil
            let report:[String:Any]=["poseAndGeometryCPU_ms":deviceStats(samples),"interval_ms":deviceStats(intervals),"callbackFPS":1000/(intervals.reduce(0,+)/Double(intervals.count)),"thermalStart":thermalStart,"thermalEnd":ProcessInfo.processInfo.thermalState.rawValue,"pixelSize":[Int(view.bounds.width*view.contentScaleFactor),Int(view.bounds.height*view.contentScaleFactor)]]
            DispatchQueue.main.async {callback(report)}
        }
    }
    func prepareOffscreen()throws {
        let start=CACurrentMediaTime()
        for actor in actors {
            let o=actor.convert(CGPoint.zero,to:self),x=actor.convert(CGPoint(x:1024,y:0),to:self),y=actor.convert(CGPoint(x:0,y:1024),to:self)
            try actor.prepareMeshes(for:SpineMeshFrameContext(skeletonToPixels:CGAffineTransform(a:(x.x-o.x)/1024,b:-(x.y-o.y)/1024,c:(y.x-o.x)/1024,d:-(y.y-o.y)/1024,tx:o.x,ty:1080-o.y),pixelSize:size))
        }
        lastPoseMS=actionMS+(CACurrentMediaTime()-start)*1000
    }
}
final class DevicePerformanceGate {
    let view:SKView,asset:SpineMeshAsset,referenceAsset:SpineMeshAsset
    private var lastPixels=[UInt8]()
    var results=[[String:Any]]()
    private var index=0
    private let configs=[(1,1),(10,1),(50,1),(50,2),(10,2),(1,2)]
    init(view:SKView)throws {self.view=view;asset=try goblinAsset();referenceAsset=SpineMeshAsset(compiled:asset.compiled,diagnosticGroupSize:.one)}
    func run(progress:@escaping(String)->Void,completion:@escaping(Result<[[String:Any]],Error>)->Void) {
        guard index<configs.count else {completion(.success(results));return}
        let (count,round)=configs[index]
        progress("Release benchmark: \(count) actors, round \(round)")
        do {
            let scene=try DevicePerformanceScene(count:count,asset:asset)
            scene.complete={ [weak scene] native in
                guard let scene=scene else {return}
                self.view.presentScene(nil)
                do {
                    if let error=scene.failure {throw error}
                    var offscreen=try self.measureOffscreen(count:count,round:round)
                    let actual=self.lastPixels
                    _=try self.measureOffscreen(count:count,round:round,reference:true)
                    guard actual.count==self.lastPixels.count else {throw DeviceValidationFailure("Device benchmark reference size differs")}
                    let maximum=zip(actual,self.lastPixels).map {abs(Int($0)-Int($1))}.max() ?? 255
                    guard maximum<=2 else {throw DeviceValidationFailure("Device benchmark group image max \(maximum)")}
                    offscreen["imageValidation"]="paired versus independent single-triangle shader passed"
                    offscreen["maximumChannelDifference"]=maximum
                    self.lastPixels=[]
                    self.results.append(["actors":count,"round":round,"native":native,"offscreen":offscreen])
                    try deviceReport("device-performance.json",payload:self.results,status:self.results.count==self.configs.count ? "completed":"running")
                    self.index+=1
                    DispatchQueue.main.asyncAfter(deadline:.now()+0.2) {self.run(progress:progress,completion:completion)}
                } catch {completion(.failure(error))}
            }
            view.preferredFramesPerSecond=60;view.shouldCullNonVisibleNodes=true;view.ignoresSiblingOrder=false;view.presentScene(scene)
        } catch {completion(.failure(error))}
    }
    private func measureOffscreen(count:Int,round:Int,reference:Bool=false)throws->[String:Any] {
        let scene=try DevicePerformanceScene(count:count,asset:reference ? referenceAsset:asset),device=try deviceUnwrap(MTLCreateSystemDefaultDevice()),queue=try deviceUnwrap(device.makeCommandQueue())
        let renderer=SKRenderer(device:device);renderer.scene=scene;renderer.ignoresSiblingOrder=false;renderer.shouldCullNonVisibleNodes=true;defer {renderer.scene=nil}
        let descriptor=MTLTextureDescriptor.texture2DDescriptor(pixelFormat:.bgra8Unorm,width:1920,height:1080,mipmapped:false);descriptor.usage = .renderTarget;descriptor.storageMode = .private
        let target=try deviceUnwrap(device.makeTexture(descriptor:descriptor)),pass=MTLRenderPassDescriptor();pass.colorAttachments[0].texture=target;pass.colorAttachments[0].loadAction = .clear;pass.colorAttachments[0].storeAction = .store
        var cpu=[Double](),encode=[Double](),gpu=[Double]()
        for frame in 0..<90 {
            try autoreleasepool {
                let start=CACurrentMediaTime();renderer.update(atTime:100+Double(frame)/60);try scene.prepareOffscreen()
                let command=try deviceUnwrap(queue.makeCommandBuffer())
                renderer.render(withViewport:CGRect(x:0,y:0,width:1920,height:1080),commandBuffer:command,renderPassDescriptor:pass)
                let elapsed=(CACurrentMediaTime()-start)*1000
                command.commit();command.waitUntilCompleted()
                guard command.status == .completed,command.gpuStartTime>0,command.gpuEndTime>command.gpuStartTime else {throw DeviceValidationFailure("Device GPU timing unavailable")}
                if frame>=30 {cpu.append(scene.lastPoseMS);encode.append(max(0,elapsed-scene.lastPoseMS));gpu.append((command.gpuEndTime-command.gpuStartTime)*1000)}
            }
        }
        let staging=try deviceUnwrap(device.makeBuffer(length:1920*1080*4,options:.storageModeShared)),command=try deviceUnwrap(queue.makeCommandBuffer()),blit=try deviceUnwrap(command.makeBlitCommandEncoder())
        blit.copy(from:target,sourceSlice:0,sourceLevel:0,sourceOrigin:MTLOrigin(x:0,y:0,z:0),sourceSize:MTLSize(width:1920,height:1080,depth:1),to:staging,destinationOffset:0,destinationBytesPerRow:1920*4,destinationBytesPerImage:1920*1080*4);blit.endEncoding();command.commit();command.waitUntilCompleted()
        guard command.status == .completed else {throw DeviceValidationFailure("Device readback failed")}
        let bytes=Data(bytes:staging.contents(),count:1920*1080*4),provider=try deviceUnwrap(CGDataProvider(data:Data(bytes:staging.contents(),count:1920*1080*4) as CFData))
        lastPixels=Array(bytes)
        let image=try deviceUnwrap(CGImage(width:1920,height:1080,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:1920*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue),provider:provider,decode:nil,shouldInterpolate:false,intent:.defaultIntent))
        try deviceUnwrap(UIImage(cgImage:image).pngData()).write(to:deviceOutput.appendingPathComponent("benchmark-r\(round)-\(count)\(reference ? "-single":"").png"))
        let foreground=bytes.withUnsafeBytes {raw->Int in let pixels=raw.bindMemory(to:UInt8.self);return stride(from:0,to:pixels.count,by:4).filter {i in (0..<3).contains {abs(Int(pixels[i+$0])-Int(pixels[$0]))>8}}.count }
        guard foreground>1000 else {throw DeviceValidationFailure("Device benchmark image is blank")}
        return ["device":device.name,"pixelSize":[1920,1080],"poseAndGeometryCPU_ms":deviceStats(cpu),"sceneUpdateAndEncodeCPU_ms":deviceStats(encode),"GPU_ms":deviceStats(gpu),"foregroundPixels":foreground,"imageValidation":"pending external full-image comparison; foreground guard passed"]
    }
}
