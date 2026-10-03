import AppKit
import SpriteKit
import Metal
import Spine

/// Real action scheduling and Metal readback; it is not an interactive UI review.
func verifyLibraryScenes(view:PrototypeView,switcher:SceneSwitcher,output:URL)throws {
    try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
    let originalFrame=view.frame
    defer {view.frame=originalFrame}
    func key(_ text:String,_ code:UInt16)throws {
        guard let event=NSEvent.keyEvent(with:.keyDown,location:.zero,modifierFlags:[],timestamp:0,windowNumber:view.window?.windowNumber ?? 0,context:nil,characters:text,charactersIgnoringModifiers:text,isARepeat:false,keyCode:code) else {throw PrototypeError("Cannot create keyboard event")}
        view.keyDown(with:event)
    }
    switcher.demo.playing=false
    let originalTime=switcher.demo.playhead,originalCount=switcher.demo.children.count
    switcher.select(0);try key("l",37)
    guard let demo=switcher.libraryDemo,view.scene === demo else {throw PrototypeError("Library renderer selector failed")}
    demo.playing=false
    try key("\t",48)
    guard let integration=switcher.libraryIntegration,view.scene === integration else {throw PrototypeError("Library scene selector failed")}
    integration.playing=false;integration.arrangeWorld(at:3.25)
    try key("l",37)
    guard view.scene === switcher.integration else {throw PrototypeError("Retained prototype integration missing")}
    try key("\t",48)
    guard view.scene === switcher.demo,switcher.demo.playhead==originalTime,switcher.demo.children.count==originalCount else {throw PrototypeError("Prototype demo state changed")}
    try key("l",37)
    guard view.scene === demo,!demo.playing else {throw PrototypeError("Library demo state not retained")}
    try key("\t",48)
    guard view.scene === integration,integration.playhead==3.25,!integration.playing else {throw PrototypeError("Library integration state not retained")}

    guard let device=MTLCreateSystemDefaultDevice(),let queue=device.makeCommandQueue() else {throw PrototypeError("Metal unavailable")}
    func render(_ scene:SKScene,characters:[Skeleton],time:Float?)throws->CGImage {
        view.presentScene(scene)
        let renderer=SKRenderer(device:device);renderer.ignoresSiblingOrder=view.ignoresSiblingOrder
        renderer.scene=scene
        if let time=time {
            for actor in characters {
                actor.stopMeshAnimation(resetToSetupPose:true);actor.removeAction(forKey:"walk");actor.isPaused=false
                actor.run(try actor.action(animation:"walk"),withKey:"walk")
            }
            renderer.update(atTime:100);renderer.update(atTime:100+Double(time))
            for actor in characters {actor.isPaused=true}
        } else {renderer.update(atTime:100)}
        // The view remains the projection authority; preparation follows all actions.
        for actor in characters {try actor.prepareMeshes(in:view)}
        if characters.isEmpty {prepareRasterCoordinates(scene:scene,view:view)}
        let scale=view.window?.backingScaleFactor ?? 1
        let width=Int(view.bounds.width*scale),height=Int(view.bounds.height*scale)
        let descriptor=MTLTextureDescriptor.texture2DDescriptor(pixelFormat:.bgra8Unorm,width:width,height:height,mipmapped:false)
        descriptor.usage = .renderTarget;descriptor.storageMode = .shared
        guard let target=device.makeTexture(descriptor:descriptor),let command=queue.makeCommandBuffer() else {throw PrototypeError("Cannot allocate readback target")}
        let pass=MTLRenderPassDescriptor();pass.colorAttachments[0].texture=target;pass.colorAttachments[0].loadAction = .clear;pass.colorAttachments[0].storeAction = .store
        renderer.render(withViewport:CGRect(x:0,y:0,width:width,height:height),commandBuffer:command,renderPassDescriptor:pass)
        command.commit();command.waitUntilCompleted()
        guard command.status == .completed else {throw PrototypeError("Library scene GPU command failed")}
        var data=Data(count:width*height*4)
        data.withUnsafeMutableBytes {target.getBytes($0.baseAddress!,bytesPerRow:width*4,from:MTLRegionMake2D(0,0,width,height),mipmapLevel:0)}
        renderer.scene=nil
        guard let provider=CGDataProvider(data:data as CFData),let image=CGImage(width:width,height:height,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:width*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue),provider:provider,decode:nil,shouldInterpolate:false,intent:.defaultIntent) else {throw PrototypeError("Cannot decode readback")}
        return image
    }
    try save(render(demo,characters:[demo.goblin,demo.girl],time:0.25),to:output.appendingPathComponent("library-demo.png"))
    integration.arrangeWorld(at:3.25)
    try save(render(integration,characters:[integration.goblin,integration.girl],time:0.25),to:output.appendingPathComponent("library-integration.png"))
    let reference=try IntegrationScene(boundsMode:.mesh,groupSize:.one);reference.playing=false
    // HUD text intentionally differs between implementations; compare the same world.
    reference.hud.isHidden=true;integration.hud.isHidden=true
    defer {integration.hud.isHidden=false}
    var reports=[[String:Any]]()
    for (index,time) in [0.0,2.0,4.0,7.85,9.85,11.8,15.7,18.0].enumerated() {
        let sizes=[CGSize(width:1100,height:760),CGSize(width:900,height:680),CGSize(width:1200,height:600)]
        view.frame.size=sizes[index%sizes.count]
        reference.cameraMotion=index != 0;integration.cameraMotion=reference.cameraMotion
        reference.translucent=index.isMultiple(of:2);integration.translucent=reference.translucent
        reference.manualZoom=index==6 ? 0.7:index==7 ? 1.3:1;integration.manualZoom=reference.manualZoom
        reference.mirrored=index==5;integration.mirrored=reference.mirrored
        try reference.sample(time);integration.arrangeWorld(at:time)
        let clipTime=Float(time.truncatingRemainder(dividingBy:1))
        try reference.goblin.sample(time:clipTime);try reference.girl.sample(time:clipTime)
        let expected=try render(reference,characters:[],time:nil)
        let actual=try render(integration,characters:[integration.goblin,integration.girl],time:clipTime)
        let a=try bitmap(expected),b=try bitmap(actual)
        let differences=zip(a,b).map {abs(Int($0)-Int($1))}
        let maximum=differences.max() ?? 255,overTwo=differences.filter {$0>2}.count,overThree=differences.filter {$0>3}.count
        try save(expected,to:output.appendingPathComponent("world-\(index)-reference.png"));try save(actual,to:output.appendingPathComponent("world-\(index).png"))
        reports.append(["case":index,"time":time,"maximumChannelDifference":maximum,"channelsOver2":overTwo,"channelsOver3":overThree])
        print("Library integration \(index): max \(maximum), channels >2 \(overTwo), >3 \(overThree)")
    }
    try JSONSerialization.data(withJSONObject:["selector":"four cached scenes, Tab/L, retained state passed","comparisons":reports],options:[.prettyPrinted,.sortedKeys]).write(to:output.appendingPathComponent("library-scenes.json"))
    guard reports.allSatisfy({($0["maximumChannelDifference"] as! Int)<=3}) else {throw PrototypeError("Library environment comparison exceeds 3/255")}
}
