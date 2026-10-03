import AppKit
import SpriteKit
import Metal

/// Uses SKRenderer for readback, but the same SKView/camera coordinate conversion
/// as the live scene. Mesh-bounds reference does not depend on gl_FragCoord.
func verifyIntegration(view: PrototypeView, switcher: SceneSwitcher, output: URL) throws {
    try FileManager.default.createDirectory(at: output,withIntermediateDirectories: true)
    let originalFrame = view.frame
    defer { view.frame = originalFrame }
    switcher.demo.playing = false
    let originalTime = switcher.demo.playhead, originalChildren = switcher.demo.children.count
    switcher.control.selectedSegment = 1
    guard switcher.control.sendAction(switcher.control.action,to: switcher.control.target) else { throw PrototypeError("Scene control action failed") }
    guard let retained = switcher.integration, view.scene === retained else { throw PrototypeError("Integration scene switch failed") }
    retained.playing = false
    try retained.sample(3.25)
    guard let tab = NSEvent.keyEvent(with: .keyDown,location: .zero,modifierFlags: [],timestamp: 0,
                                    windowNumber: view.window?.windowNumber ?? 0,context: nil,characters: "\t",
                                    charactersIgnoringModifiers: "\t",isARepeat: false,keyCode: 48) else { throw PrototypeError("Tab event creation failed") }
    view.keyDown(with: tab)
    guard view.scene === switcher.demo, switcher.demo.playhead == originalTime,
          switcher.demo.children.count == originalChildren else { throw PrototypeError("Original demo was modified by switching") }
    switcher.select(1)
    guard view.scene === retained, retained.playhead == 3.25 else { throw PrototypeError("Integration scene state lost") }

    guard let device = MTLCreateSystemDefaultDevice(),let queue = device.makeCommandQueue() else { throw PrototypeError("Metal unavailable") }
    let renderer = SKRenderer(device: device)
    renderer.ignoresSiblingOrder = false
    let reference = try IntegrationScene(boundsMode: .mesh,groupSize: .one)
    let candidate = try IntegrationScene(boundsMode: .triangle,groupSize: .two)
    reference.playing = false; candidate.playing = false
    func render(_ scene: IntegrationScene) throws -> CGImage {
        view.presentScene(scene)
        let scale = view.window?.backingScaleFactor ?? 1
        let width = Int(view.bounds.width*scale), height = Int(view.bounds.height*scale)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,width: width,height: height,mipmapped: false)
        descriptor.usage = .renderTarget; descriptor.storageMode = .shared
        guard let target = device.makeTexture(descriptor: descriptor),let command = queue.makeCommandBuffer() else { throw PrototypeError("Integration target allocation failed") }
        renderer.scene = scene; renderer.update(atTime: 0)
        prepareRasterCoordinates(scene: scene,view: view)
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = target; pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
        renderer.render(withViewport: CGRect(x: 0,y: 0,width: width,height: height),commandBuffer: command,renderPassDescriptor: pass)
        command.commit(); command.waitUntilCompleted()
        guard command.status == .completed else { throw PrototypeError("Integration render failed: \(String(describing: command.error))") }
        var data = Data(count: width*height*4)
        data.withUnsafeMutableBytes { bytes in
            target.getBytes(bytes.baseAddress!,bytesPerRow: width*4,from: MTLRegionMake2D(0,0,width,height),mipmapLevel: 0)
        }
        guard let provider = CGDataProvider(data: data as CFData),let image = CGImage(width: width,height: height,bitsPerComponent: 8,bitsPerPixel: 32,
            bytesPerRow: width*4,space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
            provider: provider,decode: nil,shouldInterpolate: false,intent: .defaultIntent) else { throw PrototypeError("Integration readback failed") }
        renderer.scene = nil
        return image
    }
    var reports: [[String: Any]] = []
    var treeRelations = Set<String>()
    let times = [0.0,2.0,4.0,7.85,9.85,11.8,15.7,18.0]
    for (index,time) in times.enumerated() {
        let sizes = [CGSize(width: 1100,height: 760),CGSize(width: 900,height: 680),CGSize(width: 1200,height: 600)]
        view.frame.size = sizes[index%sizes.count]
        for scene in [reference,candidate] {
            scene.cameraMotion = index != 0
            scene.translucent = index.isMultiple(of: 2)
            scene.manualZoom = index == 6 ? 0.7 : index == 7 ? 1.3 : 1
            scene.mirrored = index == 5
            try scene.sample(time)
            guard let fence = scene.world.childNode(withName: "fence"),
                  let tree = scene.world.childNode(withName: "crossing-tree") else { throw PrototypeError("Missing environment occluder") }
            for actor in [scene.goblin,scene.girl] {
                for object in [fence,tree] {
                    guard (actor.position.y > object.position.y) == (actor.zPosition < object.zPosition) else { throw PrototypeError("Incorrect actor/environment order") }
                }
                if abs(actor.position.x-tree.position.x) < 90 {
                    treeRelations.insert(actor.position.y > tree.position.y ? "behind" : "front")
                }
                func validateBand(_ node: SKNode, depth: CGFloat) throws {
                    let local = depth+node.zPosition
                    guard local >= 0 && local < 1 else { throw PrototypeError("Actor escaped its scene depth band") }
                    for child in node.children { try validateBand(child,depth: local) }
                }
                for child in actor.children { try validateBand(child,depth: 0) }
            }
        }
        let expected = try render(reference), actual = try render(candidate)
        let a = try bitmap(expected), b = try bitmap(actual)
        // Camera conversion and linear texture interpolation can differ by a
        // few LSBs from the UV-interpolated mesh-bounds reference. Count >2
        // separately; the full image still has a strict 3/255 upper bound.
        var bad = 0, overTwo = 0, maximum = 0
        for index in a.indices {
            let delta = abs(Int(a[index])-Int(b[index]))
            maximum = max(maximum,delta)
            if delta > 2 { overTwo += 1 }
            if delta > 3 { bad += 1 }
        }
        try save(actual,to: output.appendingPathComponent("integration-\(index).png"))
        if bad > 0 { try save(expected,to: output.appendingPathComponent("integration-\(index)-reference.png")) }
        reports.append(["frame": index,"time": time,"width": actual.width,"height": actual.height,
                        "maximumChannelDifference": maximum,"channelsDifferingOver2": overTwo,"channelsDifferingOver3": bad])
        guard bad == 0 else { throw PrototypeError("Integration frame \(index): \(bad) channels >3/255, max \(maximum)") }
    }
    guard treeRelations == Set(["behind","front"]) else { throw PrototypeError("Test did not exercise both sides of the tree") }
    try JSONSerialization.data(withJSONObject: ["treeFrontAndBehindPassed": true,"sceneSwitchPreservesState": true,"depthBandsPassed": true,"frames": reports],options: [.prettyPrinted,.sortedKeys])
        .write(to: output.appendingPathComponent("integration-validation.json"))
    switcher.select(0)
    print("Integration: scene switching/state, depth bands, 8 camera/alpha/resize image comparisons passed.")
}
