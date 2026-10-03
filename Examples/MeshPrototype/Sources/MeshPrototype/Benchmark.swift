import AppKit
import SpriteKit
import Metal
import TriangleRenderer

private func statistics(_ samples: [Double]) -> [String: Double] {
    let sorted = samples.sorted()
    guard !sorted.isEmpty else { return [:] }
    return ["mean": samples.reduce(0,+)/Double(samples.count),
            "p50": sorted[(sorted.count-1)/2], "p95": sorted[Int(Double(sorted.count-1)*0.95)],
            "max": sorted.last!, "samples": Double(samples.count)]
}

private final class BenchmarkScene: SKScene {
    let actors: [Goblin]
    var onComplete: (([String: Any]) -> Void)?
    private var tick = 0, completed = false
    private var previous: TimeInterval?
    private var occludedFrames = 0
    private let thermalStart = ProcessInfo.processInfo.thermalState.rawValue
    private var cpu: [Double] = [], intervals: [Double] = [], areas: [Double] = [], triangles: [Double] = []
    let warmup = 30, measured = 120

    init(count: Int, mode: TriangleMeshNode.BoundsMode, groupSize: TriangleMeshNode.GroupSize) throws {
        actors = try (0..<count).map { try Goblin(skin: $0.isMultiple(of: 2) ? "goblin" : "goblingirl", boundsMode: mode, groupSize: groupSize) }
        super.init(size: CGSize(width: 1920, height: 1080))
        scaleMode = .aspectFit
        backgroundColor = NSColor(calibratedWhite: 0.1, alpha: 1)
        let columns = min(count, count <= 10 ? 5 : 10), rows = (count+columns-1)/columns
        for (index, actor) in actors.enumerated() {
            actor.setScale(0.65)
            actor.position = CGPoint(x: 120 + CGFloat(index % columns)*1680/CGFloat(max(columns-1,1)),
                                     y: 50 + CGFloat(index/columns)*730/CGFloat(max(rows-1,1)))
            // Unique top-level order makes overlapping actors deterministic.
            actor.zPosition = CGFloat(index)*200
            addChild(actor)
        }
    }
    required init?(coder: NSCoder) { fatalError("Use init(count:mode:)") }
    func sample(tick: Int) throws {
        // Identical poses and phase offsets for both bounds modes.
        for (index, actor) in actors.enumerated() {
            try actor.sample(time: Float((tick+index*7)%60)/60)
        }
        if let view = view { prepareRasterCoordinates(scene: self, view: view) }
    }
    func area() -> (Double, Double) {
        let scaleSquared = 0.65*0.65
        return (actors.reduce(0) { $0 + $1.submittedQuadArea }*scaleSquared,
                actors.reduce(0) { $0 + $1.coveredTriangleArea }*scaleSquared)
    }
    override func update(_ currentTime: TimeInterval) {
        guard onComplete != nil, !completed else { return }
        let start = CACurrentMediaTime()
        do { try sample(tick: tick) }
        catch { fputs("Benchmark pose failed: \(error)\n", stderr); exit(1) }
        let elapsed = (CACurrentMediaTime()-start)*1000
        if tick >= warmup {
            if view?.window?.occlusionState.contains(.visible) != true { occludedFrames += 1 }
            cpu.append(elapsed)
            if let previous = previous { intervals.append((currentTime-previous)*1000) }
            let areasNow = area(); areas.append(areasNow.0); triangles.append(areasNow.1)
        }
        previous = currentTime
        tick += 1
        if tick == warmup+measured {
            completed = true
            var shaders = Set<ObjectIdentifier>(), textures = Set<ObjectIdentifier>(), sprites = 0
            func inspect(_ node: SKNode) {
                guard !node.isHidden else { return }
                if let sprite = node as? SKSpriteNode {
                    sprites += 1
                    if let shader = sprite.shader { shaders.insert(ObjectIdentifier(shader)) }
                    if let texture = sprite.texture { textures.insert(ObjectIdentifier(texture)) }
                }
                node.children.forEach(inspect)
            }
            actors.forEach(inspect)
            let result: [String: Any] = ["poseAndGeometryCPU_ms": statistics(cpu), "frameInterval_ms": statistics(intervals),
                "effectiveFPS": 1000/(intervals.reduce(0,+)/Double(intervals.count)),
                "intervalsOver25ms": intervals.filter { $0 > 25 }.count,
                "submittedQuadArea_px2": statistics(areas), "triangleArea_px2": statistics(triangles),
                "visibleTrianglesLastFrame": actors.reduce(0) { $0 + $1.triangleCount },
                "visibleSpriteNodesLastFrame": sprites, "uniqueShaderObjectsLastFrame": shaders.count,
                "uniquePrimaryTextureObjectsLastFrame": textures.count,
                "occludedMeasuredFrames": occludedFrames, "appActiveAtEnd": NSApp.isActive,
                "thermalStart": thermalStart, "thermalEnd": ProcessInfo.processInfo.thermalState.rawValue]
            let callback = onComplete
            DispatchQueue.main.async { callback?(result) }
        }
    }
}

/// A sequential benchmark: actual SKView cadence, followed by isolated GPU
/// timings of the SAME SpriteKit nodes through SKRenderer. No timed readback.
final class BenchmarkRunner {
    private let view: SKView
    private let output: URL
    private var results: [[String: Any]] = []
    private var index = 0
    private var activity: NSObjectProtocol?
    private let groupExperiment = CommandLine.arguments.contains("--benchmark-groups")
    private let configurations: [(count: Int, mode: TriangleMeshNode.BoundsMode, groupSize: TriangleMeshNode.GroupSize, round: Int)] = {
        let groups = CommandLine.arguments.contains("--benchmark-groups")
        return (0..<2).flatMap { round in
            [1,10,50].flatMap { count -> [(Int, TriangleMeshNode.BoundsMode, TriangleMeshNode.GroupSize, Int)] in
                if groups {
                    let sizes: [TriangleMeshNode.GroupSize] = round == 0 ? [.one,.two,.four] : [.four,.two,.one]
                    return sizes.map { (count,.triangle,$0,round) }
                }
                return (round == 0 ? [TriangleMeshNode.BoundsMode.mesh, .triangle] : [.triangle, .mesh]).map { (count,$0,selectedGroupSize,round) }
            }
        }
    }()
    init(view: SKView, output: URL) { self.view = view; self.output = output }
    func start() {
        activity = ProcessInfo.processInfo.beginActivity(options: [.userInitiated, .latencyCritical], reason: "Spine renderer performance measurement")
        view.window?.level = .floating
        view.window?.orderFrontRegardless()
        view.preferredFramesPerSecond = 60
        view.showsFPS = false; view.showsNodeCount = false; view.showsDrawCount = false
        view.ignoresSiblingOrder = CommandLine.arguments.contains("--ignore-sibling-order")
        view.shouldCullNonVisibleNodes = true
        runNext()
    }
    private func runNext() {
        guard index < configurations.count else {
            do {
                try saveReport()
                if groupExperiment { try validateGroupedBenchmarkImages(output: output) }
                else { try validateBenchmarkImages(output: output) }
                if let activity = activity { ProcessInfo.processInfo.endActivity(activity) }
                print("BENCHMARK COMPLETE: \(output.path)"); exit(0)
            }
            catch { fputs("Benchmark report failed: \(error)\n", stderr); exit(1) }
        }
        let configuration = configurations[index]
        print("BENCHMARK round \(configuration.round+1), \(configuration.count) actors, \(configuration.mode.rawValue), group \(configuration.groupSize.rawValue)")
        fflush(stdout)
        do {
            let scene = try BenchmarkScene(count: configuration.count, mode: configuration.mode, groupSize: configuration.groupSize)
            scene.onComplete = { [weak self, weak scene] native in
                guard let self = self, let scene = scene else { return }
                scene.onComplete = nil
                // Detach the SKView before offscreen timing to prevent a second
                // renderer from competing for the GPU or updating the scene.
                self.view.presentScene(nil)
                do {
                    let suffix = self.groupExperiment ? "g\(configuration.groupSize.rawValue)" : configuration.mode.rawValue
                    let gpu = try self.measureGPU(scene, label: "r\(configuration.round+1)-\(configuration.count)-\(suffix)")
                    self.results.append(["actors": configuration.count, "mode": configuration.mode.rawValue,
                                         "round": configuration.round+1, "groupSize": configuration.groupSize.rawValue, "skView": native, "offscreen": gpu])
                    try self.saveReport()
                    self.index += 1
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.2) { self.runNext() }
                } catch { fputs("GPU benchmark failed: \(error)\n", stderr); exit(1) }
            }
            view.presentScene(scene)
        } catch { fputs("Benchmark setup failed: \(error)\n", stderr); exit(1) }
    }
    private func measureGPU(_ scene: BenchmarkScene, label: String) throws -> [String: Any] {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else { throw PrototypeError("Metal unavailable") }
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: 1920, height: 1080, mipmapped: false)
        descriptor.usage = .renderTarget; descriptor.storageMode = .private
        guard let target = device.makeTexture(descriptor: descriptor) else { throw PrototypeError("Render target allocation failed") }
        let renderer = SKRenderer(device: device)
        renderer.scene = scene
        renderer.ignoresSiblingOrder = view.ignoresSiblingOrder; renderer.shouldCullNonVisibleNodes = true
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = target
        pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
        var cpu: [Double] = [], encode: [Double] = [], gpu: [Double] = [], wall: [Double] = []
        // Serialized command buffers isolate timing. Wall time is NOT FPS.
        for frame in 0..<90 {
            try autoreleasepool {
                let begin = CACurrentMediaTime()
                try scene.sample(tick: frame)
                prepareRasterCoordinates(root: scene, crop: scene.frame, scale: 1, topLeftOrigin: true)
                let poseDone = CACurrentMediaTime()
                renderer.update(atTime: Double(frame)/60)
                guard let command = queue.makeCommandBuffer() else { throw PrototypeError("No command buffer") }
                renderer.render(withViewport: CGRect(x: 0, y: 0, width: 1920, height: 1080), commandBuffer: command, renderPassDescriptor: pass)
                let encoded = CACurrentMediaTime()
                command.commit(); command.waitUntilCompleted()
                guard command.status == .completed else { throw PrototypeError("GPU command failed: \(String(describing: command.error))") }
                guard command.gpuEndTime > command.gpuStartTime, command.gpuStartTime > 0 else { throw PrototypeError("GPU timestamps unavailable") }
                if frame >= 30 {
                    cpu.append((poseDone-begin)*1000)
                    encode.append((encoded-poseDone)*1000)
                    gpu.append((command.gpuEndTime-command.gpuStartTime)*1000)
                    wall.append((CACurrentMediaTime()-begin)*1000)
                }
            }
        }
        // Diagnostic readback after all timed samples; excluded from timings.
        let rowBytes = 1920*4
        guard let staging = device.makeBuffer(length: rowBytes*1080, options: .storageModeShared),
              let copy = queue.makeCommandBuffer(), let blit = copy.makeBlitCommandEncoder() else {
            throw PrototypeError("Diagnostic staging allocation failed")
        }
        blit.copy(from: target, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                  sourceSize: MTLSize(width: 1920, height: 1080, depth: 1), to: staging,
                  destinationOffset: 0, destinationBytesPerRow: rowBytes, destinationBytesPerImage: rowBytes*1080)
        blit.endEncoding(); copy.commit(); copy.waitUntilCompleted()
        guard copy.status == .completed else { throw PrototypeError("Diagnostic readback failed") }
        let pixels = Data(bytes: staging.contents(), count: rowBytes*1080)
        let alphaSum = pixels.withUnsafeBytes { bytes -> Int in
            let rgba = bytes.bindMemory(to: UInt8.self)
            return stride(from: 3, to: rgba.count, by: 4).reduce(0) { $0 + Int(rgba[$1]) }
        }
        guard let provider = CGDataProvider(data: pixels as CFData),
              let image = CGImage(width: 1920, height: 1080, bitsPerComponent: 8, bitsPerPixel: 32,
                  bytesPerRow: rowBytes, space: CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
                  provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else {
            throw PrototypeError("Diagnostic image creation failed")
        }
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        try save(image, to: output.appendingPathComponent("gpu-\(label).png"))
        renderer.scene = nil
        return ["device": device.name, "alphaSum": alphaSum, "sizePixels": [1920,1080], "poseAndGeometryCPU_ms": statistics(cpu),
                "sceneUpdateAndEncodeCPU_ms": statistics(encode), "GPU_ms": statistics(gpu), "serializedWall_ms": statistics(wall)]
    }
    private func saveReport() throws {
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let report: [String: Any] = ["schema": 2, "benchmarkType": groupExperiment ? "triangleGroups" : "bounds",
            "groupSizes": groupExperiment ? [1,2,4] : [selectedGroupSize.rawValue], "date": ISO8601DateFormatter().string(from: Date()),
            "os": ProcessInfo.processInfo.operatingSystemVersionString,
            "nativeViewSizePoints": [Double(view.bounds.width), Double(view.bounds.height)],
            "backingScale": view.window?.backingScaleFactor ?? 1,
            "targetFPS": 60, "nativeWarmupFrames": 30, "nativeMeasuredFrames": 120,
            "gpuWarmupFrames": 30, "gpuMeasuredFrames": 60, "results": results,
            "appNapPrevented": true, "floatingWindow": true, "ignoresSiblingOrder": view.ignoresSiblingOrder,
            "notes": "Release build recommended. Two rounds, reversed variant order. Geometry areas are proxies, not fragment counters. Native intervals are vsync-paced; GPU samples use SKRenderer, serialized command buffers, no readback. No measured draw-call counters."]
        try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
            .write(to: output.appendingPathComponent("benchmark.json"))
    }
}
