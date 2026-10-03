import AppKit
import SpriteKit
import TriangleRenderer

func checkerTexture() -> SKTexture {
    var bytes = [UInt8]()
    for y in 0..<64 {
        for x in 0..<64 {
            let white = (x/8+y/8).isMultiple(of: 2)
            // Asymmetric quadrants expose flips/rotations; texture alpha checks PMA.
            let color: [UInt8] = white ? [128, 128, 128, 128] : (x < 32 ? [128, 24, 16, 128] : [16, 80, 128, 128])
            bytes.append(contentsOf: color)
        }
    }
    let texture = SKTexture(data: Data(bytes), size: CGSize(width: 64, height: 64))
    texture.filteringMode = .nearest
    return texture
}
let square: [SIMD2<Float>] = [SIMD2(0,0), SIMD2(128,0), SIMD2(128,128), SIMD2(0,128)]
let squareUV: [SIMD2<Float>] = [SIMD2(0,0), SIMD2(1,0), SIMD2(1,1), SIMD2(0,1)]

final class DemoScene: SKScene {
    let goblin: Goblin
    let girl: Goblin
    private let status = SKLabelNode(fontNamed: "Menlo")
    private var previousTime: TimeInterval?
    var playhead: Float = 0
    var playing = true
    private var translucent = false

    init(exampleSize: CGSize = CGSize(width: 1100, height: 760)) throws {
        goblin = try Goblin(skin: "goblin")
        girl = try Goblin(skin: "goblingirl")
        super.init(size: exampleSize)
        scaleMode = .aspectFit
        backgroundColor = NSColor(calibratedRed: 0.065, green: 0.078, blue: 0.11, alpha: 1)
        label("SPINE / TRIANGLE SHADER PROTOTYPE", at: CGPoint(x: 40, y: 714), size: 25)
        label("Official Goblins Pro 4.1.17  ·  SpriteKit nodes + SKShader  ·  no Metal host", at: CGPoint(x: 40, y: 682), size: 13, color: .lightGray)
        for x: CGFloat in [40, 560] {
            let panel = SKShapeNode(rect: CGRect(x: x, y: 247, width: 500, height: 412), cornerRadius: 16)
            panel.fillColor = NSColor(calibratedWhite: 0.13, alpha: 1); panel.strokeColor = .clear
            panel.zPosition = -1; addChild(panel)
        }
        label("GOBLIN", at: CGPoint(x: 64, y: 629), size: 16)
        label("GOBLINGIRL / LINKED FEET", at: CGPoint(x: 584, y: 629), size: 16)
        goblin.position = CGPoint(x: 285, y: 280); goblin.setScale(0.95)
        girl.position = CGPoint(x: 805, y: 280); girl.setScale(0.95)
        addChild(goblin); addChild(girl)
        let texture = checkerTexture()
        let reference = SKSpriteNode(texture: texture, size: CGSize(width: 128, height: 128))
        reference.anchorPoint = .zero; reference.position = CGPoint(x: 64, y: 71); addChild(reference)
        let mesh = try TriangleMeshNode(texture: texture, positions: square, uvs: squareUV, indices: [0,1,2, 0,2,3])
        mesh.position = CGPoint(x: 254, y: 71); addChild(mesh)
        label("SKSpriteNode", at: CGPoint(x: 64, y: 210), size: 12)
        label("2 shader triangles", at: CGPoint(x: 254, y: 210), size: 12)
        label("50% texture alpha: a shared edge must not become a dark/bright diagonal.", at: CGPoint(x: 430, y: 186), size: 12, color: .lightGray)
        label("SPACE pause  ·  ← / → step  ·  W wireframe  ·  A alpha", at: CGPoint(x: 430, y: 145), size: 13)
        label("R mirror  ·  + / − scale  ·  0 reset", at: CGPoint(x: 430, y: 117), size: 13)
        status.fontSize = 12; status.horizontalAlignmentMode = .left; status.position = CGPoint(x: 40, y: 29)
        addChild(status)
        try sample(0)
    }
    required init?(coder: NSCoder) { fatalError("Use init()") }
    private func label(_ text: String, at position: CGPoint, size: CGFloat, color: NSColor = .white) {
        let node = SKLabelNode(fontNamed: "Menlo"); node.text = text; node.position = position
        node.fontSize = size; node.fontColor = color; node.horizontalAlignmentMode = .left; addChild(node)
    }
    func sample(_ time: Float) throws {
        playhead = time
        try goblin.sample(time: time); try girl.sample(time: time)
        status.text = String(format: "walk %.3fs / %.2fs  |  %d visible triangles  |  %@", time, goblin.duration,
                             goblin.triangleCount + girl.triangleCount, playing ? "PLAYING" : "PAUSED")
    }
    override func update(_ currentTime: TimeInterval) {
        defer { previousTime = currentTime }
        guard playing, let previous = previousTime else { return }
        do { try sample((playhead + Float(min(currentTime-previous, 0.1))).truncatingRemainder(dividingBy: goblin.duration)) }
        catch { fputs("Animation failed: \(error)\n", stderr); playing = false; status.text = "ERROR: \(error)" }
    }
    override func keyDown(with event: NSEvent) {
        do {
            switch event.keyCode {
            case 49: playing.toggle()
            case 123, 124:
                playing = false
                let delta: Float = event.keyCode == 124 ? 1/30 : -1/30
                try sample((playhead + delta + goblin.duration).truncatingRemainder(dividingBy: goblin.duration))
            default:
                switch event.charactersIgnoringModifiers?.lowercased() {
                case "w": goblin.showsWireframe.toggle(); girl.showsWireframe = goblin.showsWireframe
                case "a": translucent.toggle(); goblin.alpha = translucent ? 0.5 : 1; girl.alpha = goblin.alpha
                case "r": goblin.xScale *= -1; girl.xScale *= -1
                case "+", "=": for node in [goblin, girl] { node.xScale *= 1.1; node.yScale *= 1.1 }
                case "-": for node in [goblin, girl] { node.xScale /= 1.1; node.yScale /= 1.1 }
                case "0": for node in [goblin, girl] { node.setScale(0.95) }; try sample(0)
                default: break
                }
            }
            try sample(playhead)
        } catch { fputs("Input failed: \(error)\n", stderr) }
    }
}

func bitmap(_ image: CGImage) throws -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: image.width*image.height*4)
    let success = bytes.withUnsafeMutableBytes { pointer -> Bool in
        guard let context = CGContext(data: pointer.baseAddress, width: image.width, height: image.height,
                                      bitsPerComponent: 8, bytesPerRow: image.width*4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return true
    }
    guard success else { throw PrototypeError("Could not read rendered pixels") }
    return bytes
}
func save(_ image: CGImage, to url: URL) throws {
    guard let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { throw PrototypeError("PNG encoding failed") }
    try data.write(to: url)
}

func verify(view: SKView, scene: DemoScene, output: URL) throws {
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    let texture = checkerTexture()
    var report: [String] = []
    func render(_ node: SKNode) throws -> CGImage {
        guard let result = view.texture(from: node, crop: CGRect(x: -32, y: -32, width: 192, height: 192)) else {
            throw PrototypeError("SKView did not render the test node")
        }
        return result.cgImage()
    }
    // Compare hardware-rendered mesh pixels against SpriteKit's own quad.
    // Checking the interior includes the diagonal and a four-triangle junction.
    let cases: [(String, [SIMD2<Float>], [SIMD2<Float>], [Int], CGFloat, CGFloat)] = [
        ("quad", square, squareUV, [0,1,2,0,2,3], 1, 1),
        ("clockwise", square, squareUV, [2,1,0,3,2,0], 1, 1),
        ("fan", square + [SIMD2(64,64)], squareUV + [SIMD2(0.5,0.5)], [0,1,4,1,2,4,2,3,4,3,0,4], 1, 1),
        ("off-center-fan", square + [SIMD2(31.25,77.125)], squareUV + [SIMD2(31.25/128,77.125/128)], [0,1,4,1,2,4,2,3,4,3,0,4], 1, 1),
        ("parent-alpha", square, squareUV, [0,1,2,0,2,3], 0.5, 1),
        ("reflected", square, squareUV, [0,1,2,0,2,3], 1, -1),
        ("minified", square, squareUV, [0,1,2,0,2,3], 1, 0.37),
        ("rotated", square, squareUV, [0,1,2,0,2,3], 1, 1),
        ("subpixel", square, squareUV, [0,1,2,0,2,3], 1, 1),
        ("linear-filter", square, squareUV, [0,1,2,0,2,3], 1, 1)
    ]
    for (name, positions, uv, indices, alpha, scale) in cases {
        texture.filteringMode = name == "linear-filter" ? .linear : .nearest
        let referenceRoot = SKNode(), meshRoot = SKNode()
        let reference = SKSpriteNode(texture: texture, size: CGSize(width: 128, height: 128))
        reference.anchorPoint = .zero
        let mesh = try TriangleMeshNode(texture: texture, positions: positions, uvs: uv, indices: indices)
        for node in [reference as SKNode, mesh] {
            node.xScale = scale; node.yScale = abs(scale); node.position.x = scale < 0 ? 128 : 0
            if name == "rotated" { node.zRotation = 0.13 }
            if name == "subpixel" { node.position = CGPoint(x: 0.37, y: 0.29) }
        }
        referenceRoot.alpha = alpha; meshRoot.alpha = alpha
        referenceRoot.addChild(reference); meshRoot.addChild(mesh)
        let expectedImage = try render(referenceRoot), actualImage = try render(meshRoot)
        let expected = try bitmap(expectedImage), actual = try bitmap(actualImage)
        guard expectedImage.width == actualImage.width, expectedImage.height == actualImage.height else { throw PrototypeError("Different output sizes") }
        var failures = 0, tested = 0, maxDifference = 0
        for pixel in 0..<(expected.count/4) {
            if expected[pixel*4+3] > 0 { tested += 1 }
            for channel in 0..<4 {
                let difference = abs(Int(expected[pixel*4+channel])-Int(actual[pixel*4+channel]))
                maxDifference = max(maxDifference, difference)
                if difference > 2 { failures += 1; break }
            }
        }
        try save(actualImage, to: output.appendingPathComponent("\(name).png"))
        try save(expectedImage, to: output.appendingPathComponent("\(name)-reference.png"))
        report.append("\(name): \(tested) pixels, \(failures) mismatches (>2/255), max difference \(maxDifference)")
        print(report.last!)
        guard tested > 1000, failures == 0 else {
            try report.joined(separator: "\n").write(to: output.appendingPathComponent("verification.txt"), atomically: true, encoding: .utf8)
            throw PrototypeError("Pixel comparison failed: \(name)")
        }
    }
    var frameBytes: [[UInt8]] = []
    var snapshots: [[String: Any]] = []
    scene.playing = false
    for time: Float in [0, 0.1333, 0.25, 0.5, 0.7, 0.75, 0.8, 1] {
        try scene.sample(time)
        for goblin in [scene.goblin, scene.girl] {
            snapshots.append(["skin": goblin.skinName, "time": Double(time), "parts": goblin.vertexSnapshot()])
        }
        guard let rendered = view.texture(from: scene, crop: scene.frame) else { throw PrototypeError("Scene capture failed") }
        let image = rendered.cgImage()
        frameBytes.append(try bitmap(image))
        try save(image, to: output.appendingPathComponent(String(format: "goblins-%.2f.png", time)))
    }
    try JSONSerialization.data(withJSONObject: snapshots, options: [.prettyPrinted, .sortedKeys])
        .write(to: output.appendingPathComponent("vertices.json"))
    guard frameBytes[0] != frameBytes[3], scene.goblin.triangleCount > 20, scene.girl.triangleCount > 20 else {
        throw PrototypeError("Goblins animation is blank or stationary")
    }
    scene.goblin.showsWireframe = true; scene.girl.showsWireframe = true
    try scene.sample(0.25)
    guard let wire = view.texture(from: scene, crop: scene.frame) else { throw PrototypeError("Wireframe capture failed") }
    try save(wire.cgImage(), to: output.appendingPathComponent("goblins-wireframe.png"))
    report.append("Goblins: eight time snapshots, animated pixels, \(scene.goblin.triangleCount + scene.girl.triangleCount) visible triangles. Use Scripts/compare-reference.mjs for pose and UV parity.")
    try report.joined(separator: "\n").write(to: output.appendingPathComponent("verification.txt"), atomically: true, encoding: .utf8)
    print("PASS: GPU pixel checks and Goblins animation smoke check. Artifacts: \(output.path)")
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 1100, height: 760),
                      styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
window.title = "Spine · Triangle Mesh Prototype"
window.center()
let view = SKView(frame: window.contentView!.bounds)
view.autoresizingMask = [.width, .height]
view.ignoresSiblingOrder = false
window.contentView = view
var demo: DemoScene?
do {
    demo = try DemoScene()
    view.presentScene(demo)
} catch {
    fputs("Failed to load prototype: \(error)\n", stderr)
    exit(1)
}
window.makeKeyAndOrderFront(nil)
window.makeFirstResponder(view)
app.activate(ignoringOtherApps: true)
if let index = CommandLine.arguments.firstIndex(of: "--verify") {
    let path = CommandLine.arguments.count > index+1 ? CommandLine.arguments[index+1] : "output"
    demo!.playing = false
    DispatchQueue.main.asyncAfter(deadline: .now()+1) {
        do { try verify(view: view, scene: demo!, output: URL(fileURLWithPath: path)); exit(0) }
        catch { fputs("Verification failed: \(error)\n", stderr); exit(1) }
    }
} else {
    view.showsFPS = true; view.showsDrawCount = true; view.showsNodeCount = true
}
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
let delegate = AppDelegate()
app.delegate = delegate
app.run()
