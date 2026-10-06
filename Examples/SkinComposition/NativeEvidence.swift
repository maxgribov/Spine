import Foundation
import SpriteKit
import Spine

/// Native SKView frame sequence; the control wears the target outfit from clip start.
final class NativeEvidenceScene: SKScene {
    private let output: URL
    private let actual: Skeleton, control: Skeleton
    private let actualRoot = SKNode(), controlRoot = SKNode()
    private let look = Wardrobe(hat: 1, clothes: 1, team: 3, earring: false).composition
    private var clock: TimeInterval = 0, first: TimeInterval?
    private var frames: [[String: Any]] = []
    private var changes = 0, finished = false
    var completion: ((Error?) -> Void)?

    init(output: URL) throws {
        self.output = output
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let asset = try loadAsset()
        actual = try Skeleton(meshAsset: asset, skin: "base"); control = try Skeleton(meshAsset: asset, skin: "base")
        super.init(size: CGSize(width: 256, height: 256)); scaleMode = .aspectFit; backgroundColor = .clear
        actual.position = CGPoint(x: 128, y: 100); control.position = actual.position
        actualRoot.addChild(actual); controlRoot.addChild(control); addChild(actualRoot); addChild(controlRoot)
        try control.apply(skinComposition: look)
        actual.eventTriggered = { [weak self] _ in
            guard let self = self else { return }
            do { try self.actual.apply(skinComposition: self.look); self.changes += 1 }
            catch { self.finish(error) }
        }
        actual.run(try actual.action(animation: "walk")); control.run(try control.action(animation: "walk"))
    }
    required init?(coder: NSCoder) { fatalError("Use init(output:)") }
    override func update(_ currentTime: TimeInterval) { clock = currentTime; if first == nil { first = currentTime } }
    private func finish(_ error: Error?) {
        guard !finished else { return }
        finished = true; actual.eventTriggered = nil; completion?(error)
    }
    override func didFinishUpdate() {
        guard !finished, let view = view, let first = first else { return }
        do {
            try actual.prepareMeshes(in: view); try control.prepareMeshes(in: view)
            let elapsed = clock - first
            let crop = CGRect(x: 0, y: 0, width: 256, height: 256)
            guard let a = view.texture(from: actualRoot, crop: crop)?.cgImage(), let b = view.texture(from: controlRoot, crop: crop)?.cgImage(),
                  let ad = a.dataProvider?.data as Data?, let bd = b.dataProvider?.data as Data? else { throw EvidenceError.unavailable("Native readback") }
            let differences = zip(ad, bd).filter { $0 != $1 }.count + abs(ad.count - bd.count)
            if changes > 0, differences != 0 { throw EvidenceError.mismatch("Native frame after callback: \(differences) differing bytes") }
            let file = String(format: "frame-%04d.png", frames.count)
            try saveEvidencePNG(a, to: output.appendingPathComponent(file))
            let actualAngle = actual.boneNode(named: "root")?.zRotation ?? 0
            let controlAngle = control.boneNode(named: "root")?.zRotation ?? 0
            guard actualAngle == controlAngle else { throw EvidenceError.mismatch("Native phase") }
            frames.append(["file": file, "time": elapsed, "actualRootRotation": actualAngle, "controlRootRotation": controlAngle,
                           "sha256": try evidenceSHA256(output.appendingPathComponent(file)),
                           "changes": changes, "differentBytes": differences, "compareRequired": changes > 0])
            if elapsed >= 1.1 {
                guard changes == 1, frames.count > 2 else { throw EvidenceError.mismatch("Missing native callback/frames") }
                let build = try JSONSerialization.jsonObject(with: Data(contentsOf: Bundle.main.resourceURL!.appendingPathComponent("build.json")))
                try JSONSerialization.data(withJSONObject: ["schemaVersion": 1, "build": build, "os": ProcessInfo.processInfo.operatingSystemVersionString,
                    "backend": "native SKView didFinishUpdate with native prepare and texture readback", "frames": frames, "passed": true],
                    options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("native.json"))
                finish(nil)
            }
        } catch { finish(error) }
    }
}
