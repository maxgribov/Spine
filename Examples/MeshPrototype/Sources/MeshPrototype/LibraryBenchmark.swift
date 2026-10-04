import AppKit
import SpriteKit
import Metal
import Spine
import TriangleRenderer

private func meshStatistics(_ values:[Double])->[String:Double] {
    let sorted=values.sorted()
    guard !sorted.isEmpty else {return [:]}
    return ["p50":sorted[(sorted.count-1)/2],"p95":sorted[Int(Double(sorted.count-1)*0.95)],"mean":values.reduce(0,+)/Double(values.count),"max":sorted.last!,"samples":Double(values.count)]
}
private final class LibraryBenchmarkScene:SKScene {
    let characters:[Skeleton]
    let reference:[Goblin]
    let library:Bool
    var nativeComplete:(([String:Any])->Void)?
    var preparationError:Error?
    var lastPoseMS=0.0
    private var start=0.0,actionMS=0.0,origin:Double?,previous:Double?
    private var tick=0,finished=false,occluded=0,inactive=0
    private var cpu=[Double](),intervals=[Double]()
    private var activeSamples=[Bool](),visibleSamples=[Bool](),thermalSamples=[Int]()
    private let thermalStart=ProcessInfo.processInfo.thermalState.rawValue
    init(count:Int,library:Bool,asset:SpineMeshAsset)throws {
        self.library=library
        characters=library ? try (0..<count).map {try Skeleton(meshAsset:asset,skin:$0.isMultiple(of:2) ? "goblin":"goblingirl")}:[]
        reference=library ? []:try (0..<count).map {try Goblin(skin:$0.isMultiple(of:2) ? "goblin":"goblingirl",boundsMode:.triangle,groupSize:.one)}
        super.init(size:CGSize(width:1920,height:1080));scaleMode = .aspectFit;backgroundColor=NSColor(calibratedWhite:0.1,alpha:1)
        let columns=min(count,count<=10 ? 5:10),rows=(count+columns-1)/columns
        let actors:[SKNode]=library ? characters:reference
        for (index,actor) in actors.enumerated() {
            actor.setScale(0.65);actor.position=CGPoint(x:120+CGFloat(index%columns)*1680/CGFloat(max(columns-1,1)),y:50+CGFloat(index/columns)*730/CGFloat(max(rows-1,1)))
            actor.zPosition=CGFloat(index)*200;addChild(actor)
        }
        for actor in characters {actor.run(.repeatForever(try actor.action(animation:"walk")))}
        cpu.reserveCapacity(120);intervals.reserveCapacity(120);activeSamples.reserveCapacity(120);visibleSamples.reserveCapacity(120);thermalSamples.reserveCapacity(120)
    }
    required init?(coder:NSCoder) {fatalError()}
    override func update(_ currentTime:TimeInterval) {
        start=CACurrentMediaTime()
        if origin==nil {origin=currentTime}
        if !library {
            do {for actor in reference {try actor.sample(time:Float((currentTime-origin!).truncatingRemainder(dividingBy:1)))}}
            catch {preparationError=error}
        }
        if nativeComplete != nil,tick>=30,let previous=previous {intervals.append((currentTime-previous)*1000)}
        previous=currentTime
    }
    override func didEvaluateActions() {actionMS=(CACurrentMediaTime()-start)*1000}
    override func didFinishUpdate() {
        // Offscreen has no SKView; it uses explicit context after renderer.update.
        guard let view=view else {lastPoseMS=actionMS;return}
        let begin=CACurrentMediaTime()
        do {
            if library {for actor in characters {try actor.prepareMeshes(in:view)}}
            else {prepareRasterCoordinates(scene:self,view:view)}
        } catch {preparationError=error}
        lastPoseMS=actionMS+(CACurrentMediaTime()-begin)*1000
        guard let completion=nativeComplete,!finished else {return}
        if tick>=30 {
            let active=NSApp.isActive,visible=view.window?.occlusionState.contains(.visible)==true
            activeSamples.append(active);visibleSamples.append(visible);thermalSamples.append(ProcessInfo.processInfo.thermalState.rawValue)
            cpu.append(lastPoseMS);if !active {inactive+=1};if !visible {occluded+=1}
        }
        tick+=1
        if tick==150 {
            finished=true
            let result:[String:Any]=["poseAndGeometryCPU_ms":meshStatistics(cpu),"frameInterval_ms":meshStatistics(intervals),"callbackFPS":1000/(intervals.reduce(0,+)/Double(intervals.count)),"occludedMeasuredFrames":occluded,"inactiveMeasuredFrames":inactive,"thermalStart":thermalStart,"thermalEnd":ProcessInfo.processInfo.thermalState.rawValue,"appActiveAtEnd":NSApp.isActive,"activeSamples":activeSamples,"visibleSamples":visibleSamples,"thermalSamples":thermalSamples]
            DispatchQueue.main.async {completion(result)}
        }
    }
    func prepareOffscreen()throws {
        if let error=preparationError {throw error}
        let begin=CACurrentMediaTime()
        if library {
            for actor in characters {
                let o=actor.convert(.zero,to:self),x=actor.convert(CGPoint(x:1024,y:0),to:self),y=actor.convert(CGPoint(x:0,y:1024),to:self)
                try actor.prepareMeshes(for:SpineMeshFrameContext(skeletonToPixels:CGAffineTransform(a:(x.x-o.x)/1024,b:-(x.y-o.y)/1024,c:(y.x-o.x)/1024,d:-(y.y-o.y)/1024,tx:o.x,ty:size.height-o.y),pixelSize:size))
            }
        } else {prepareRasterCoordinates(root:self,crop:frame,scale:1,topLeftOrigin:true)}
        lastPoseMS=actionMS+(CACurrentMediaTime()-begin)*1000
    }
}

/// Production group-two benchmark with an independent single-triangle reference.
/// All actors start at phase zero in both variants; no unsupported public seek.
final class LibraryBenchmarkRunner {
    private let view:SKView,output:URL,asset:SpineMeshAsset
    private var index=0,results=[[String:Any]](),activity:NSObjectProtocol?
    private let configurations:[(Int,Bool,Int)]=(0..<2).flatMap {round in [1,10,50].flatMap {count in (round==0 ? [false,true]:[true,false]).map {(count,$0,round)}}}
    init(view:SKView,output:URL)throws {self.view=view;self.output=output;asset=try LibrarySceneResources().asset}
    func start() {
        do {try exportReferences()} catch {fputs("Benchmark reference export failed: \(error)\n",stderr);exit(1)}
        activity=ProcessInfo.processInfo.beginActivity(options:[.userInitiated,.latencyCritical],reason:"Spine production mesh benchmark")
        NSApp.activate(ignoringOtherApps:true)
        view.window?.makeKeyAndOrderFront(nil)
        view.window?.level = .floating;view.window?.orderFrontRegardless();view.preferredFramesPerSecond=60
        view.showsFPS=false;view.showsNodeCount=false;view.showsDrawCount=false;view.ignoresSiblingOrder=false;view.shouldCullNonVisibleNodes=true
        next()
    }
    private func exportReferences()throws {
        let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        try validateLegacyOutput(output,baseline:root.appendingPathComponent("features/mesh-support/validation/legacy-baseline"))
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        let logURL=output.appendingPathComponent("reference-export.log")
        FileManager.default.createFile(atPath:logURL.path,contents:nil)
        let log=try FileHandle(forWritingTo:logURL);defer {try? log.close()}
        let process=Process();process.executableURL=URL(fileURLWithPath:"/usr/bin/xcrun")
        process.arguments=["swift","test","-c","release","--package-path",root.path,"--filter","BenchmarkReferenceExportTests"]
        var environment=ProcessInfo.processInfo.environment;environment["SPINE_BENCHMARK_REFERENCE_OUTPUT"]=output.path
        process.environment=environment;process.standardOutput=log;process.standardError=log
        try process.run();process.waitUntilExit()
        guard process.terminationStatus==0 else {throw PrototypeError("Single-triangle reference generation failed")}
    }
    private func next() {
        guard index<configurations.count else {
            do {try finish();if let activity=activity {ProcessInfo.processInfo.endActivity(activity)};exit(0)}
            catch {fputs("Production benchmark failed: \(error)\n",stderr);exit(1)}
        }
        let (count,library,round)=configurations[index]
        print("Production benchmark round \(round+1) count \(count) \(library ? "library-pairs":"reference-single")");fflush(stdout)
        do {
            let scene=try LibraryBenchmarkScene(count:count,library:library,asset:asset)
            scene.nativeComplete={ [weak self,weak scene] native in
                guard let self=self,let scene=scene else {return}
                scene.nativeComplete=nil;self.view.presentScene(nil)
                do {
                    if let error=scene.preparationError {throw error}
                    // A fresh graph avoids clock-origin transfer between two renderers.
                    let offscreen=try self.offscreen(count:count,library:library,round:round)
                    self.results.append(["round":round+1,"actors":count,"variant":library ? "library-pairs":"reference-single","skView":native,"offscreen":offscreen])
                    try self.report(passed:false);self.index+=1
                    DispatchQueue.main.asyncAfter(deadline:.now()+0.2) {self.next()}
                } catch {fputs("Production measurement failed: \(error)\n",stderr);exit(1)}
            }
            NSApp.activate(ignoringOtherApps:true);view.window?.makeKeyAndOrderFront(nil)
            view.presentScene(scene)
        } catch {fputs("Production setup failed: \(error)\n",stderr);exit(1)}
    }
    private func offscreen(count:Int,library:Bool,round:Int)throws->[String:Any] {
        let scene=try LibraryBenchmarkScene(count:count,library:library,asset:asset)
        guard let device=MTLCreateSystemDefaultDevice(),let queue=device.makeCommandQueue() else {throw PrototypeError("Metal unavailable")}
        let renderer=SKRenderer(device:device);renderer.scene=scene;renderer.ignoresSiblingOrder=false;renderer.shouldCullNonVisibleNodes=true
        defer {renderer.scene=nil}
        let descriptor=MTLTextureDescriptor.texture2DDescriptor(pixelFormat:.bgra8Unorm,width:1920,height:1080,mipmapped:false);descriptor.usage = .renderTarget;descriptor.storageMode = .private
        guard let target=device.makeTexture(descriptor:descriptor) else {throw PrototypeError("No GPU target")}
        let pass=MTLRenderPassDescriptor();pass.colorAttachments[0].texture=target;pass.colorAttachments[0].loadAction = .clear;pass.colorAttachments[0].storeAction = .store
        var cpu=[Double](),encode=[Double](),gpu=[Double]()
        for frame in 0..<90 {
            try autoreleasepool {
                let begin=CACurrentMediaTime();renderer.update(atTime:100+Double(frame)/60);try scene.prepareOffscreen()
                guard let command=queue.makeCommandBuffer() else {throw PrototypeError("No command buffer")}
                renderer.render(withViewport:CGRect(x:0,y:0,width:1920,height:1080),commandBuffer:command,renderPassDescriptor:pass)
                let total=(CACurrentMediaTime()-begin)*1000
                command.commit();command.waitUntilCompleted()
                guard command.status == .completed,command.gpuStartTime>0,command.gpuEndTime>command.gpuStartTime else {throw PrototypeError("GPU timestamps/command unavailable")}
                if frame>=30 {cpu.append(scene.lastPoseMS);encode.append(max(0,total-scene.lastPoseMS));gpu.append((command.gpuEndTime-command.gpuStartTime)*1000)}
            }
        }
        // Copy/readback occurs only after all measured command buffers complete.
        guard let staging=device.makeBuffer(length:1920*1080*4,options:.storageModeShared),let command=queue.makeCommandBuffer(),let blit=command.makeBlitCommandEncoder() else {throw PrototypeError("Readback allocation failed")}
        blit.copy(from:target,sourceSlice:0,sourceLevel:0,sourceOrigin:MTLOrigin(x:0,y:0,z:0),sourceSize:MTLSize(width:1920,height:1080,depth:1),to:staging,destinationOffset:0,destinationBytesPerRow:1920*4,destinationBytesPerImage:1920*1080*4);blit.endEncoding();command.commit();command.waitUntilCompleted()
        guard command.status == .completed else {throw PrototypeError("Readback failed")}
        let data=Data(bytes:staging.contents(),count:1920*1080*4),provider=CGDataProvider(data:Data(bytes:staging.contents(),count:1920*1080*4) as CFData)!
        guard let image=CGImage(width:1920,height:1080,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:1920*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue),provider:provider,decode:nil,shouldInterpolate:false,intent:.defaultIntent),data.count==1920*1080*4 else {throw PrototypeError("Invalid image")}
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        try save(image,to:output.appendingPathComponent("r\(round+1)-\(count)-\(library ? "library":"reference").png"))
        return ["device":device.name,"poseAndGeometryCPU_ms":meshStatistics(cpu),"sceneUpdateAndEncodeCPU_ms":meshStatistics(encode),"GPU_ms":meshStatistics(gpu)]
    }
    private func report(passed:Bool)throws {
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        try JSONSerialization.data(withJSONObject:["passed":passed,"nativeWarmupFrames":30,"nativeMeasuredFrames":120,"offscreenWarmupFrames":30,"offscreenMeasuredFrames":60,"results":results,"notes":"Release, two reversed variant rounds. Both variants use phase-zero starts. CPU pose includes SpriteKit action phase plus prepare; encode excludes that CPU interval. Callback FPS is not presented FPS. No timed readback or measured draw-call counters."],options:[.prettyPrinted,.sortedKeys]).write(to:output.appendingPathComponent("mesh-performance.json"))
    }
    private func finish()throws {
        var images=[[String:Any]]()
        for round in 1...2 {for count in [1,10,50] {
            func pixels(_ variant:String)throws->[UInt8] {guard let image=NSImage(contentsOf:output.appendingPathComponent("r\(round)-\(count)-\(variant).png"))?.cgImage(forProposedRect:nil,context:nil,hints:nil) else {throw PrototypeError("Missing benchmark image")};return try bitmap(image)}
            let a=try pixels("library"),prototype=try pixels("reference")
            guard let single=NSImage(contentsOf:output.appendingPathComponent("single-\(count).png"))?.cgImage(forProposedRect:nil,context:nil,hints:nil) else {throw PrototypeError("Missing single-triangle reference")}
            let b=try bitmap(single)
            guard a.count==b.count else {throw PrototypeError("Different image sizes")}
            let maximum=zip(a,b).map {abs(Int($0)-Int($1))}.max() ?? 255
            let foreground=stride(from:0,to:b.count,by:4).filter {i in (0..<3).contains {abs(Int(b[i+$0])-Int(b[$0]))>8}}.count
            guard foreground>1000 else {throw PrototypeError("Single-triangle reference is blank")}
            images.append(["round":round,"actors":count,"maximumChannelDifference":maximum,"foregroundPixels":foreground,"prototypeDiagnosticMaximum":zip(a,prototype).map {abs(Int($0)-Int($1))}.max() ?? 255,"reference":"independent one-triangle shader with same compiled pose; numeric pose checked separately against spine-core4.1.56"])
        }}
        try JSONSerialization.data(withJSONObject:images,options:[.prettyPrinted,.sortedKeys]).write(to:output.appendingPathComponent("mesh-performance-images.json"))
        guard images.allSatisfy({($0["maximumChannelDifference"] as! Int)<=2}) else {throw PrototypeError("Benchmark image validation failed")}
        guard results.allSatisfy({LibraryBenchmarkPolicy.acceptsThermalSamples(($0["skView"] as! [String:Any])["thermalSamples"] as! [Int])}) else {
            throw PrototypeError("Measured thermal conditions were non-nominal or incomplete; all samples retained")
        }
        let large=results.filter {($0["actors"] as! Int)==50 && ($0["variant"] as! String)=="library-pairs"}
        func mean(_ section:String,_ key:String)->Double {large.reduce(0) {sum,row in sum+(((row[section] as! [String:Any])[key] as! [String:Double])["p50"]!)/2}}
        let pose=mean("offscreen","poseAndGeometryCPU_ms"),encode=mean("offscreen","sceneUpdateAndEncodeCPU_ms"),gpu=mean("offscreen","GPU_ms")
        let fps=large.reduce(0) {$0+(($1["skView"] as! [String:Any])["callbackFPS"] as! Double)/2}
        print("50 actors: pose \(pose)ms, encode \(encode)ms, GPU \(gpu)ms, callback \(fps)FPS")
        guard pose<=10,encode<=21.3,gpu<=0.52,LibraryBenchmarkPolicy.acceptsCallbackRounds(large.map {($0["skView"] as! [String:Any])["callbackFPS"] as! Double}) else {throw PrototypeError("Spec V.4 performance threshold failed")}
        guard results.allSatisfy({(($0["skView"] as! [String:Any])["occludedMeasuredFrames"] as! Int)==0 && (($0["skView"] as! [String:Any])["inactiveMeasuredFrames"] as! Int)==0}) else {throw PrototypeError("Measured application/window was inactive or occluded")}
        try report(passed:true)
    }
}
