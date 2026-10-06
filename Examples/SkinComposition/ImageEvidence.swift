import Foundation
import ImageIO
import CryptoKit
import SpriteKit
import Metal
import Spine

enum EvidenceError: Error { case unavailable(String), mismatch(String) }

/// Compares changing an outfit against wearing it from the beginning of the same clip.
/// Both owners share one SpriteKit backend and deterministic action timestamps.
func captureCompositionEvidence(to output: URL) throws {
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    guard let device = MTLCreateSystemDefaultDevice() else { throw EvidenceError.unavailable("Metal") }
    let asset = try loadAsset()
    var results: [[String: Any]] = []
    let cases: [(String, Double, Bool, Bool)] = [
        ("setup", 0, false, false), ("color-front", 0.3, false, false),
        ("side-draw-order", 0.6, false, false), ("nil", 0.8, false, false),
        ("paused", 0.6, true, false), ("callback", 0.6, false, true)
    ]
    for (name, time, paused, callback) in cases {
        let scene = SKScene(size: CGSize(width: 256, height: 256)); scene.scaleMode = .aspectFit
        scene.backgroundColor = .clear; scene.physicsWorld.gravity = .zero
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 256, height: 256))
        let actual = try Skeleton(meshAsset: asset, skin: "base"), control = try Skeleton(meshAsset: asset, skin: "base")
        let actualRoot = SKNode(), controlRoot = SKNode()
        actualRoot.addChild(actual); controlRoot.addChild(control); scene.addChild(actualRoot); scene.addChild(controlRoot)
        actual.position = CGPoint(x: 128, y: 100); control.position = actual.position
        let look = Wardrobe(hat: 1, clothes: 1, team: 3, earring: false).composition
        try control.apply(skinComposition: look)
        var callbackCount = 0, callbackError: Error?
        actual.eventTriggered = { _ in
            callbackCount += 1
            if callback { do { try actual.apply(skinComposition: look) } catch { callbackError = error } }
        }
        defer { actual.eventTriggered = nil; view.presentScene(nil) }
        let renderer = SKRenderer(device: device); renderer.scene = scene
        renderer.update(atTime: 100)
        actual.run(try actual.action(animation: "walk")); control.run(try control.action(animation: "walk"))
        renderer.update(atTime: 100)
        if time > 0 { renderer.update(atTime: 100 + time) }
        if let error = callbackError { throw error }
        let angleBeforePause = actual.boneNode(named: "root")?.zRotation
        let controlAngleBeforePause = control.boneNode(named: "root")?.zRotation
        if paused {
            actual.isPaused = true; control.isPaused = true
        }
        if !callback { try actual.apply(skinComposition: look) }
        if paused {
            renderer.update(atTime: 100 + time + 0.2)
            guard actual.boneNode(named: "root")?.zRotation == angleBeforePause,
                  control.boneNode(named: "root")?.zRotation == controlAngleBeforePause else {
                throw EvidenceError.mismatch(name + " advanced while paused")
            }
        }
        actual.isPaused = true; control.isPaused = true
        guard actual.skinComposition == control.skinComposition else { throw EvidenceError.mismatch(name + " descriptor") }
        view.presentScene(scene)
        // texture(from:crop:) uses its own bottom-left framebuffer coordinates.
        let context = SpineMeshFrameContext(skeletonToPixels: CGAffineTransform(translationX: 128, y: 100), pixelSize: CGSize(width: 256, height: 256))
        try actual.prepareMeshes(for: context); try control.prepareMeshes(for: context)
        let crop = CGRect(x: 0, y: 0, width: 256, height: 256)
        guard let a = view.texture(from: actualRoot, crop: crop)?.cgImage(),
              let b = view.texture(from: controlRoot, crop: crop)?.cgImage(),
              let ad = a.dataProvider?.data as Data?, let bd = b.dataProvider?.data as Data? else { throw EvidenceError.unavailable("Readback") }
        let differences = zip(ad, bd).filter { $0 != $1 }.count + abs(ad.count - bd.count)
        guard ad.contains(where: { $0 != 0 }) else { throw EvidenceError.mismatch(name + " empty image") }
        var artifacts: [String: String] = [:]
        for (suffix, image) in [("actual", a), ("control", b)] {
            let filename = name + "-" + suffix + ".png"
            let url = output.appendingPathComponent(filename)
            try saveEvidencePNG(image, to: url)
            artifacts[filename] = try evidenceSHA256(url)
        }
        results.append(["case": name, "sampleTime": time, "paused": paused, "callback": callback,
                        "callbackCount": callbackCount, "width": a.width, "height": a.height,
                        "bitsPerPixel": a.bitsPerPixel, "bitmapInfo": a.bitmapInfo.rawValue,
                        "appliedWhilePaused": paused, "pausePosePreserved": paused, "artifacts": artifacts,
                        "differentBytes": differences, "passed": differences == 0])
        if differences != 0 { throw EvidenceError.mismatch("\(name): \(differences) differing raw bytes") }
        renderer.scene = nil
    }
    let build = try JSONSerialization.jsonObject(with: Data(contentsOf: Bundle.main.resourceURL!.appendingPathComponent("build.json")))
    let report: [String: Any] = ["schemaVersion": 1, "build": build,
        "os": ProcessInfo.processInfo.operatingSystemVersionString,
        "backend": "SpriteKit SKView texture readback after SKRenderer deterministic action sampling",
        "comparison": "raw same-backend image bytes; no tolerance or color conversion", "cases": results,
        "limitations": ["Deterministic paired capture is not native wall-clock video", "Not manual UI screenshot inspection"]]
    try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("comparisons.json"))
}

func evidenceSHA256(_ url: URL) throws -> String {
    SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined()
}

func saveEvidencePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else { throw EvidenceError.unavailable("PNG destination") }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw EvidenceError.unavailable("PNG encoding") }
}
