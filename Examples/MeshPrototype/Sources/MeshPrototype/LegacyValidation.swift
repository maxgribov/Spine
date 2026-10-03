import AppKit
import SpriteKit
import Metal
import Spine

/// Baseline characterization uses the production library exclusively through its old public API.
/// The action clock is SKRenderer.update(atTime:), never elapsed wall-clock time.
private final class LegacyHarness {
    let device: MTLDevice
    let queue: MTLCommandQueue
    let renderer: SKRenderer
    let target: MTLTexture
    let scene = SKScene(size: CGSize(width: 256, height: 256))
    let view = SKView(frame: CGRect(x: 0, y: 0, width: 256, height: 256))
    let model: SpineModel
    let atlas: SKTextureAtlas
    let replacement: SKTexture
    var skeletons: [Skeleton] = []
    var events: [[String: Any]] = []
    var time: Double = 0

    init(data: Data, count: Int = 1) throws {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else {
            throw PrototypeError("Metal unavailable for legacy characterization")
        }
        self.device = device; self.queue = queue
        renderer = SKRenderer(device: device)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: 256, height: 256, mipmapped: false)
        descriptor.usage = .renderTarget; descriptor.storageMode = .shared
        guard let target = device.makeTexture(descriptor: descriptor) else { throw PrototypeError("Legacy render target unavailable") }
        self.target = target
        model = try JSONDecoder().decode(SpineModel.self, from: data)
        func texture(_ rgba: [UInt8]) -> SKTexture {
            let result = SKTexture(data: Data(Array(repeating: rgba, count: 16).flatMap { $0 }), size: CGSize(width: 4, height: 4))
            result.filteringMode = .nearest
            return result
        }
        let body = texture([224, 80, 32, 255]), open = texture([40, 180, 224, 255]), closed = texture([80, 224, 40, 255])
        replacement = texture([128, 16, 128, 128])
        atlas = SKTextureAtlas(dictionary: ["body": NSImage(cgImage: body.cgImage(), size: body.size()), "open": NSImage(cgImage: open.cgImage(), size: open.size()), "closed": NSImage(cgImage: closed.cgImage(), size: closed.size())])
        // Synchronous preload before the fixed action clock starts.
        let ready = DispatchSemaphore(value: 0)
        atlas.preload { ready.signal() }
        while ready.wait(timeout: .now()) != .success { RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.001)) }
        scene.backgroundColor = .black; scene.scaleMode = .aspectFit
        scene.physicsWorld.gravity = .zero
        for index in 0..<count {
            let skeleton = Skeleton(model, ["default": atlas])
            try skeleton.applyDefaultSkin()
            skeleton.position = CGPoint(x: 112 + index%5, y: 112 + index/5)
            skeleton.setBitMasks(category: 4, collision: 0)
            scene.addChild(skeleton); skeletons.append(skeleton)
        }
        skeletons[0].eventTriggered = { [weak self] event in
            guard let self = self else { return }
            var entry: [String: Any] = ["time": self.time]
            // EventModel's fields are not public in the baseline library.
            for field in Mirror(reflecting: event).children {
                if let key = field.label { entry[key] = String(describing: field.value) }
            }
            self.events.append(entry)
        }
        view.presentScene(scene)
        renderer.ignoresSiblingOrder = false; renderer.scene = scene
        renderer.update(atTime: 100)
        _ = try draw()
    }

    func advance(_ time: Double) {
        self.time = time
        renderer.update(atTime: 100 + time)
    }

    @discardableResult func draw() throws -> MTLCommandBuffer {
        guard let command = queue.makeCommandBuffer() else { throw PrototypeError("Legacy command allocation failed") }
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = target
        pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
        renderer.render(withViewport: CGRect(x: 0, y: 0, width: 256, height: 256), commandBuffer: command, renderPassDescriptor: pass)
        command.commit(); command.waitUntilCompleted()
        guard command.status == .completed else { throw PrototypeError("Legacy GPU render failed") }
        return command
    }

    func image() throws -> CGImage {
        var bytes = Data(count: 256*256*4)
        bytes.withUnsafeMutableBytes { target.getBytes($0.baseAddress!, bytesPerRow: 256*4, from: MTLRegionMake2D(0, 0, 256, 256), mipmapLevel: 0) }
        guard let provider = CGDataProvider(data: bytes as CFData), let image = CGImage(width: 256, height: 256, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 256*4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else { throw PrototypeError("Legacy image readback failed") }
        return image
    }

    func snapshot() -> [[String: Any]] {
        func visit(_ node: SKNode, path: String) -> [[String: Any]] {
            var item: [String: Any] = ["path": path, "type": String(describing: type(of: node)), "x": node.position.x, "y": node.position.y, "rotation": node.zRotation, "scaleX": node.xScale, "scaleY": node.yScale, "z": node.zPosition, "alpha": node.alpha, "hidden": node.isHidden, "hasActions": node.hasActions(), "speed": node.speed, "paused": node.isPaused]
            if let sprite = node as? SKSpriteNode {
                let color = sprite.color.usingColorSpace(.deviceRGB)!
                item["color"] = [color.redComponent, color.greenComponent, color.blueComponent, color.alphaComponent]
                item["size"] = [sprite.size.width, sprite.size.height]
                item["anchor"] = [sprite.anchorPoint.x, sprite.anchorPoint.y]
                item["blend"] = sprite.colorBlendFactor
                item["replacementTexture"] = sprite.texture === replacement
            }
            if let body = node.physicsBody { item["physics"] = ["dynamic": body.isDynamic, "category": body.categoryBitMask, "collision": body.collisionBitMask] }
            var result = [item]
            let children = node.children.sorted { ($0.name ?? "") < ($1.name ?? "") }
            for (index, child) in children.enumerated() { result += visit(child, path: path + "/" + (child.name ?? "unnamed-\(index)")) }
            return result
        }
        return visit(skeletons[0], path: "skeleton")
    }
}

private func compareLegacyJSON(_ expected: Any, _ actual: Any, path: String = "") throws {
    if let a = expected as? [String: Any], let b = actual as? [String: Any] {
        guard Set(a.keys) == Set(b.keys) else { throw PrototypeError("Legacy snapshot keys changed at \(path)") }
        for key in a.keys { try compareLegacyJSON(a[key]!, b[key]!, path: path + "/" + key) }
    } else if let a = expected as? [Any], let b = actual as? [Any] {
        guard a.count == b.count else { throw PrototypeError("Legacy snapshot count changed at \(path)") }
        for index in a.indices { try compareLegacyJSON(a[index], b[index], path: path + "/\(index)") }
    } else if let a = expected as? NSNumber, let b = actual as? NSNumber {
        guard abs(a.doubleValue-b.doubleValue) <= 1e-6 else { throw PrototypeError("Legacy numeric mismatch \(path): \(a) vs \(b)") }
    } else if String(describing: expected) != String(describing: actual) {
        throw PrototypeError("Legacy value mismatch \(path): \(expected) vs \(actual)")
    }
}

/// Resolve symlinks before any output writes, including recording/bootstrap modes.
/// Goldens and their descendants/ancestors are never an output staging directory.
private func validateLegacyOutput(_ output: URL, baseline: URL) throws {
    // URL.resolvingSymlinksInPath alone leaves a nonexistent leaf unresolved.
    // Resolve its nearest existing ancestor first, then append the missing suffix.
    var ancestor = output.standardizedFileURL
    var suffix: [String] = []
    while !FileManager.default.fileExists(atPath: ancestor.path), ancestor.path != "/" {
        suffix.insert(ancestor.lastPathComponent, at: 0)
        ancestor.deleteLastPathComponent()
    }
    var resolvedOutput = ancestor.resolvingSymlinksInPath()
    for component in suffix { resolvedOutput.appendPathComponent(component) }
    let destination = resolvedOutput.standardizedFileURL.path
    let reference = baseline.standardizedFileURL.resolvingSymlinksInPath().path
    guard destination != reference,
          !destination.hasPrefix(reference + "/"),
          !reference.hasPrefix(destination + "/") else {
        throw PrototypeError("Legacy output must be a separate staging directory, outside the baseline tree")
    }
    // Existing file symlinks must not redirect a candidate write into the goldens.
    if let files = try? FileManager.default.contentsOfDirectory(at: output, includingPropertiesForKeys: nil) {
        for file in files {
            let resolved = file.resolvingSymlinksInPath().path
            guard resolved != reference, !resolved.hasPrefix(reference + "/") else {
                throw PrototypeError("Legacy output contains a file aliasing the baseline")
            }
        }
    }
}

/// Atomic replacement also prevents existing hard links from modifying goldens.
private func saveLegacyCandidate(_ image: CGImage, to url: URL) throws {
    guard let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
        throw PrototypeError("Legacy PNG encoding failed")
    }
    try data.write(to: url, options: .atomic)
}

func verifyLibraryLegacy(output: URL, record: Bool) throws {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let fixture = root.appendingPathComponent("Tests/SpineTests/Resources/Compatibility/legacy-4.1.json")
    let baseline = root.appendingPathComponent("features/mesh-support/validation/legacy-baseline")
    try validateLegacyOutput(output, baseline: baseline)
    let data = try Data(contentsOf: fixture)
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    // The wrapper stages an app bundle before process launch, matching a client app.
    let bundled = try Skeleton(json: "legacy-characterization-bundle", folder: "missing-baseline-atlas", skin: "alternate")
    guard bundled.boneNode(named: "arm") != nil, Skeleton(fromJSON: "legacy-characterization-bundle") != nil else { throw PrototypeError("Unchanged bundle constructors failed") }

    let cases = ["once", "sequence", "repeat", "group", "reuse", "removal", "pause", "speed", "reset", "skin-texture-manual"]
    var records: [[String: Any]] = []
    var imageCount = 0, maxDifference = 0
    for name in cases {
        let harness = try LegacyHarness(data: data), skeleton = harness.skeletons[0]
        let action = try skeleton.action(animation: "motion")
        switch name {
        case "sequence": skeleton.run(.sequence([.wait(forDuration: 0.2), action, .wait(forDuration: 0.1), action]), withKey: "clip")
        case "repeat": skeleton.run(.repeat(action, count: 2), withKey: "clip")
        case "group": skeleton.run(.group([action, .moveBy(x: 24, y: -8, duration: 1)]), withKey: "clip")
        default: skeleton.run(action, withKey: "clip")
        }
        var frames: [[String: Any]] = []
        let captures: Set<Int> = [0, 15, 30, 45, 60, 90, 150]
        for frame in 0...150 {
            let time = Double(frame)/60
            if frame == 20 {
                if name == "removal" { skeleton.removeAction(forKey: "clip") }
                if name == "pause" { skeleton.isPaused = true }
                if name == "speed" { skeleton.speed = 0.5 }
            }
            if frame == 40 && name == "pause" { skeleton.isPaused = false }
            if frame == 45 {
                if name == "reset" { skeleton.run(skeleton.dropToDefaultsAction()) }
                if name == "skin-texture-manual" { try skeleton.apply(skin: "alternate") }
            }
            if frame == 90 {
                if name == "reuse" { skeleton.run(action, withKey: "clip") }
                if name == "skin-texture-manual" {
                    skeleton.regionAttachmentNode(named: "body")?.texture = harness.replacement
                    skeleton.boneNode(named: "root")?.xScale = -0.8
                    skeleton.boneNode(named: "arm")?.position = CGPoint(x: 44, y: 21)
                }
            }
            if frame == 120 && name == "skin-texture-manual" { skeleton.run(try skeleton.action(applySkin: "default")) }
            harness.advance(time)
            if captures.contains(frame) {
                try harness.draw()
                let image = try harness.image(), file = "\(name)-\(frame).png"
                if !record {
                    guard let ref = NSImage(contentsOf: baseline.appendingPathComponent(file))?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { throw PrototypeError("Missing legacy golden \(file)") }
                    let a = try bitmap(ref), b = try bitmap(image)
                    guard a.count == b.count else { throw PrototypeError("Legacy image dimensions changed") }
                    for index in a.indices { maxDifference = max(maxDifference, abs(Int(a[index])-Int(b[index]))) }
                    guard maxDifference <= 1 else { throw PrototypeError("Legacy RGBA difference >1/255: \(file), max \(maxDifference)") }
                }
                try saveLegacyCandidate(image, to: output.appendingPathComponent(file))
                frames.append(["time": time, "nodes": harness.snapshot(), "events": harness.events, "points": skeleton.points?.count ?? 0, "activePoints": skeleton.activePoints?.count ?? 0])
                imageCount += 1
            }
        }
        records.append(["scenario": name, "duration": action.duration, "frames": frames])
    }
    let states: [String: Any] = ["clock": "SKRenderer fixed 1/60s; origin 100", "scenarios": records]
    if !record { try compareLegacyJSON(JSONSerialization.jsonObject(with: Data(contentsOf: baseline.appendingPathComponent("states.json"))), states) }
    try JSONSerialization.data(withJSONObject: states, options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("states.json"), options: .atomic)
    try JSONSerialization.data(withJSONObject: ["mode": record ? "record" : "verify", "images": imageCount, "maximumChannelDifference": maxDifference, "numericTolerance": 1e-6, "scenarios": cases], options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("compatibility.json"), options: .atomic)
    print("Legacy characterization: \(cases.count) scenarios, \(imageCount) images, numeric ≤1e-6, RGBA max \(maxDifference)/255 (\(record ? "recorded" : "verified")).")
}

func benchmarkLibraryLegacy(output: URL, record: Bool = false) throws {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    let baseline = root.appendingPathComponent("features/mesh-support/validation/legacy-baseline")
    try validateLegacyOutput(output, baseline: baseline)
    if !record {
        // Fail before benchmarking/writing when even one reference is absent or corrupt.
        for round in 0..<2 {
            for count in [1, 10, 50] {
                let file = "benchmark-\(round)-\(count).png"
                guard NSImage(contentsOf: baseline.appendingPathComponent(file))?.cgImage(forProposedRect: nil, context: nil, hints: nil) != nil else {
                    throw PrototypeError("Missing or invalid legacy benchmark golden \(file)")
                }
            }
        }
    }
    let data = try Data(contentsOf: root.appendingPathComponent("Tests/SpineTests/Resources/Compatibility/legacy-4.1.json"))
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    var records: [[String: Any]] = []
    for round in 0..<2 {
        for count in (round == 0 ? [1, 10, 50] : [50, 10, 1]) {
            let harness = try LegacyHarness(data: data, count: count)
            for skeleton in harness.skeletons { skeleton.run(.repeatForever(try skeleton.action(animation: "motion"))) }
            var updateTimes: [Double] = [], encodeTimes: [Double] = [], gpuTimes: [Double] = []
            for frame in 0..<150 {
                let start = ProcessInfo.processInfo.systemUptime
                harness.advance(Double(frame)/60)
                let updated = ProcessInfo.processInfo.systemUptime
                guard let command = harness.queue.makeCommandBuffer() else { throw PrototypeError("Legacy benchmark command unavailable") }
                let pass = MTLRenderPassDescriptor()
                pass.colorAttachments[0].texture = harness.target; pass.colorAttachments[0].loadAction = .clear; pass.colorAttachments[0].storeAction = .store
                harness.renderer.render(withViewport: CGRect(x: 0,y: 0,width: 256,height: 256),commandBuffer: command,renderPassDescriptor: pass)
                let encoded = ProcessInfo.processInfo.systemUptime
                command.commit(); command.waitUntilCompleted()
                guard command.status == .completed else { throw PrototypeError("Legacy benchmark GPU failed") }
                if frame >= 30 {
                    updateTimes.append((updated-start)*1000); encodeTimes.append((encoded-start)*1000)
                    gpuTimes.append((command.gpuEndTime-command.gpuStartTime)*1000)
                }
            }
            func median(_ values: [Double]) -> Double { let sorted = values.sorted(); return (sorted[59]+sorted[60])/2 }
            let imageName = "benchmark-\(round)-\(count).png"
            let image = try harness.image()
            let referenceURL = root.appendingPathComponent("features/mesh-support/validation/legacy-baseline/" + imageName)
            var imageVerified = false
            if !record {
                guard let reference = NSImage(contentsOf: referenceURL)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { throw PrototypeError("Invalid legacy benchmark golden") }
                let expected = try bitmap(reference), actual = try bitmap(image)
                guard expected.count == actual.count, zip(expected, actual).allSatisfy({ abs(Int($0)-Int($1)) <= 1 }) else { throw PrototypeError("Legacy benchmark image mismatch") }
                imageVerified = true
            }
            try saveLegacyCandidate(image, to: output.appendingPathComponent(imageName))
            records.append(["imageVerified": imageVerified,"round": round,"characters": count,"warmupFrames": 30,"measuredFrames": 120,"updateMedianMS": median(updateTimes),"updateEncodeMedianMS": median(encodeTimes),"gpuMedianMS": median(gpuTimes),"updateSamplesMS": updateTimes,"updateEncodeSamplesMS": encodeTimes])
        }
    }
    try JSONSerialization.data(withJSONObject: ["mode": record ? "record" : "verify", "kind": "legacy-only fixed-clock offscreen CPU; not native callback FPS", "pixelSize": [256,256],"records": records],options: [.prettyPrinted,.sortedKeys]).write(to: output.appendingPathComponent("legacy-performance.json"), options: .atomic)
    print("Legacy CPU benchmark: two reversed rounds ×1/10/50, 30 warmup +120 measured, no timed readback (\(record ? "recorded; not verified" : "images verified")).")
}

/// Foundation caches bundle resources. Stage the fixture BEFORE launching the host.
/// The temporary app has no signature/install and is removed after characterization.
func runLegacyBundleHostIfNeeded(output: URL) throws -> Bool {
    guard Bundle.main.bundleURL.pathExtension != "app" else { return false }
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    try validateLegacyOutput(output, baseline: root.appendingPathComponent("features/mesh-support/validation/legacy-baseline"))
    let host = FileManager.default.temporaryDirectory.appendingPathComponent("SpineLegacy-" + UUID().uuidString + ".app")
    let contents = host.appendingPathComponent("Contents")
    let executable = contents.appendingPathComponent("MacOS/MeshPrototype")
    try FileManager.default.createDirectory(at: executable.deletingLastPathComponent(), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: contents.appendingPathComponent("Resources"), withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: host) }
    try FileManager.default.copyItem(at: URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL, to: executable)
    try FileManager.default.copyItem(at: root.appendingPathComponent("Tests/SpineTests/Resources/Compatibility/legacy-4.1.json"), to: contents.appendingPathComponent("Resources/legacy-characterization-bundle.json"))
    try PropertyListSerialization.data(fromPropertyList: ["CFBundleExecutable": "MeshPrototype", "CFBundleIdentifier": "dev.spine.legacy-characterization", "CFBundlePackageType": "APPL"], format: .xml, options: 0).write(to: contents.appendingPathComponent("Info.plist"))
    let process = Process(); process.executableURL = executable
    process.arguments = [CommandLine.arguments.contains("--record-library-legacy-baseline") ? "--record-library-legacy-baseline" : "--verify-library-legacy", output.path]
    try process.run(); process.waitUntilExit()
    guard process.terminationStatus == 0 else { throw PrototypeError("Legacy bundle host failed (\(process.terminationStatus))") }
    return true
}
