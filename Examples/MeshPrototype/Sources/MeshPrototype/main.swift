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

    init(exampleSize: CGSize = CGSize(width: 1100, height: 760), boundsMode: TriangleMeshNode.BoundsMode = .triangle, groupSize: TriangleMeshNode.GroupSize = .two) throws {
        goblin = try Goblin(skin: "goblin", boundsMode: boundsMode, groupSize: groupSize)
        girl = try Goblin(skin: "goblingirl", boundsMode: boundsMode, groupSize: groupSize)
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
        let mesh = try TriangleMeshNode(texture: texture, positions: square, uvs: squareUV, indices: [0,1,2, 0,2,3], groupSize: groupSize)
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
    override func didMove(to view: SKView) { previousTime = nil }
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
    override func didFinishUpdate() {
        if let view = view { prepareRasterCoordinates(scene: self, view: view) }
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
        try capture(view: view, node: node, crop: CGRect(x: -32, y: -32, width: 192, height: 192))
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
        var failures = 0, tested = 0, maxDifference = 0, samplingEdges = 0
        for pixel in 0..<(expected.count/4) {
            if expected[pixel*4+3] > 0 { tested += 1 }
            let differences = (0..<4).map { abs(Int(expected[pixel*4+$0])-Int(actual[pixel*4+$0])) }
            maxDifference = max(maxDifference, differences.max()!)
            if differences.max()! > 2 {
                let x = pixel % expectedImage.width, y = pixel / expectedImage.width
                var adjacentSample = false
                if texture.filteringMode == .nearest && differences[3] == 0 {
                    for row in max(0,y-1)...min(expectedImage.height-1,y+1) {
                        for column in max(0,x-1)...min(expectedImage.width-1,x+1) {
                            let neighbor = (row*expectedImage.width+column)*4
                            if (0..<4).allSatisfy({ abs(Int(expected[neighbor+$0])-Int(actual[pixel*4+$0])) <= 2 }) {
                                adjacentSample = true
                            }
                        }
                    }
                }
                // Full-precision screen coordinates may select the other texel
                // at a nearest-sampling discontinuity. Coverage must still match
                // exactly; the color must equal an immediate reference neighbor.
                if adjacentSample { samplingEdges += 1 } else { failures += 1 }
            }
        }
        try save(actualImage, to: output.appendingPathComponent("\(name).png"))
        try save(expectedImage, to: output.appendingPathComponent("\(name)-reference.png"))
        report.append("\(name): \(tested) pixels, \(failures) unexpected mismatches (>2/255), \(samplingEdges) nearest-boundary pixels, raw max difference \(maxDifference)")
        print(report.last!)
        guard tested > 1000, failures == 0 else {
            try report.joined(separator: "\n").write(to: output.appendingPathComponent("verification.txt"), atomically: true, encoding: .utf8)
            throw PrototypeError("Pixel comparison failed: \(name)")
        }
    }
    report.append(contentsOf: try verifyOptimizedBounds(view: view, output: output))
    report.append(try verifySharedMaterial(view: view))
    report.append(try verifyTriangleGroups(view: view, output: output))
    var frameBytes: [[UInt8]] = []
    var snapshots: [[String: Any]] = []
    scene.playing = false
    for time: Float in [0, 0.1333, 0.25, 0.5, 0.7, 0.75, 0.8, 1] {
        try scene.sample(time)
        for goblin in [scene.goblin, scene.girl] {
            snapshots.append(["skin": goblin.skinName, "time": Double(time), "parts": goblin.vertexSnapshot()])
        }
        let image = try capture(view: view, node: scene, crop: scene.frame)
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
    let wire = try capture(view: view, node: scene, crop: scene.frame)
    try save(wire, to: output.appendingPathComponent("goblins-wireframe.png"))
    report.append("Goblins: eight time snapshots, animated pixels, \(scene.goblin.triangleCount + scene.girl.triangleCount) visible triangles. Use Scripts/compare-reference.mjs for pose and UV parity.")
    try report.joined(separator: "\n").write(to: output.appendingPathComponent("verification.txt"), atomically: true, encoding: .utf8)
    print("PASS: GPU pixel checks and Goblins animation smoke check. Artifacts: \(output.path)")
}

if let index=CommandLine.arguments.firstIndex(of:"--verify-library-mesh") {
    do {
        guard CommandLine.arguments.count>index+1 else {throw PrototypeError("Provide mesh validation output directory")}
        try verifyLibraryMesh(output:URL(fileURLWithPath:CommandLine.arguments[index+1]));exit(0)
    } catch {fputs("Library mesh validation failed: \(error)\n",stderr);exit(1)}
}

if let index = CommandLine.arguments.firstIndex(of: "--verify-library-legacy") ?? CommandLine.arguments.firstIndex(of: "--record-library-legacy-baseline") ?? CommandLine.arguments.firstIndex(of: "--benchmark-library-legacy") ?? CommandLine.arguments.firstIndex(of: "--record-library-legacy-benchmark") {
    _ = NSApplication.shared
    do {
        guard CommandLine.arguments.count > index+1 else { throw PrototypeError("Provide legacy validation output directory") }
        let output = URL(fileURLWithPath: CommandLine.arguments[index+1])
        if CommandLine.arguments.contains("--benchmark-library-legacy") || CommandLine.arguments.contains("--record-library-legacy-benchmark") { try benchmarkLibraryLegacy(output: output, record: CommandLine.arguments.contains("--record-library-legacy-benchmark")) }
        else if try !runLegacyBundleHostIfNeeded(output: output) { try verifyLibraryLegacy(output: output, record: CommandLine.arguments.contains("--record-library-legacy-baseline")) }
        exit(0)
    } catch { fputs("Legacy validation failed: \(error)\n", stderr); exit(1) }
}

if let index = CommandLine.arguments.firstIndex(of: "--compare-benchmarks") {
    do {
        guard CommandLine.arguments.count > index+2 else { throw PrototypeError("Provide reference and candidate benchmark directories") }
        try validateBenchmarkRevision(reference: URL(fileURLWithPath: CommandLine.arguments[index+1]),
                                      output: URL(fileURLWithPath: CommandLine.arguments[index+2])); exit(0)
    } catch { fputs("Revision image validation failed: \(error)\n", stderr); exit(1) }
}
if let index = CommandLine.arguments.firstIndex(of: "--validate-benchmark") {
    do {
        guard CommandLine.arguments.count > index+1 else { throw PrototypeError("Provide benchmark output directory") }
        try validateBenchmarkImages(output: URL(fileURLWithPath: CommandLine.arguments[index+1])); exit(0)
    } catch { fputs("Benchmark image validation failed: \(error)\n", stderr); exit(1) }
}
var selectedGroupSize = TriangleMeshNode.GroupSize.two
if let option = CommandLine.arguments.firstIndex(of: "--group-size") {
    guard CommandLine.arguments.count > option+1, let count = Int(CommandLine.arguments[option+1]),
          let selected = TriangleMeshNode.GroupSize(rawValue: count) else {
        fputs("--group-size expects 1, 2 or 4\n", stderr); exit(1)
    }
    selectedGroupSize = selected
}
let benchmarkIndex = CommandLine.arguments.firstIndex(of: "--benchmark") ?? CommandLine.arguments.firstIndex(of: "--benchmark-groups") ?? CommandLine.arguments.firstIndex(of:"--benchmark-library-mesh")
let verificationMode = CommandLine.arguments.contains("--verify") || CommandLine.arguments.contains("--verify-integration")
let showsSceneSwitcher = benchmarkIndex == nil && !verificationMode
let app = NSApplication.shared
app.setActivationPolicy(.regular)
let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: benchmarkIndex == nil ? 1100 : 960, height: benchmarkIndex == nil ? (showsSceneSwitcher ? 804 : 760) : 540),
                      styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
window.title = "Spine · Triangle Mesh Prototype"
window.center()
let content = NSView(frame: window.contentView!.bounds)
window.contentView = content
let view = PrototypeView(frame: CGRect(x: 0,y: 0,width: content.bounds.width,height: content.bounds.height-(showsSceneSwitcher ? 44 : 0)))
view.autoresizingMask = [.width, .height]
view.ignoresSiblingOrder = CommandLine.arguments.contains("--ignore-sibling-order")
content.addSubview(view)
var sceneSwitcher: SceneSwitcher?
var demo: DemoScene?
do {
    if benchmarkIndex == nil {
        var mode = TriangleMeshNode.BoundsMode.triangle
        if let option = CommandLine.arguments.firstIndex(of: "--bounds") {
            guard CommandLine.arguments.count > option+1,
                  let selected = TriangleMeshNode.BoundsMode(rawValue: CommandLine.arguments[option+1]) else {
                throw PrototypeError("--bounds expects mesh or triangle")
            }
            mode = selected
        }
        demo = try DemoScene(boundsMode: mode, groupSize: selectedGroupSize)
        view.presentScene(demo)
        if showsSceneSwitcher || CommandLine.arguments.contains("--verify-integration") {
            let switcher = SceneSwitcher(view: view,demo: demo!,boundsMode: mode,groupSize: selectedGroupSize)
            sceneSwitcher = switcher
            if showsSceneSwitcher {
                let control = switcher.control!
                control.frame = CGRect(x: 18,y: content.bounds.height-36,width: 310,height: 28)
                control.autoresizingMask = [.minYMargin]
                content.addSubview(control)
                let runtimeControl=switcher.runtimeControl!
                runtimeControl.frame=CGRect(x:345,y:content.bounds.height-36,width:240,height:28)
                runtimeControl.autoresizingMask=[.minYMargin];content.addSubview(runtimeControl)
                let hint = NSTextField(labelWithString: "Tab — scene · L — renderer")
                hint.textColor = .secondaryLabelColor
                hint.frame = CGRect(x: 610,y: content.bounds.height-30,width: 260,height: 20)
                hint.autoresizingMask = [.minYMargin]; content.addSubview(hint)
            }
            if CommandLine.arguments.contains("--integration") { switcher.select(1) }
            if CommandLine.arguments.contains("--library") {switcher.selectRuntime(true)}
        }
    }
} catch {
    fputs("Failed to load prototype: \(error)\n", stderr)
    exit(1)
}
window.makeKeyAndOrderFront(nil)
window.makeFirstResponder(view)
app.activate(ignoringOtherApps: true)
var benchmarkRunner: BenchmarkRunner?
var libraryBenchmarkRunner:LibraryBenchmarkRunner?
if let index=CommandLine.arguments.firstIndex(of:"--benchmark-library-mesh") {
    do {
        guard CommandLine.arguments.count>index+1 else {throw PrototypeError("Provide production benchmark output directory")}
        libraryBenchmarkRunner=try LibraryBenchmarkRunner(view:view,output:URL(fileURLWithPath:CommandLine.arguments[index+1]))
        DispatchQueue.main.asyncAfter(deadline:.now()+0.5) {libraryBenchmarkRunner!.start()}
    } catch {fputs("Production benchmark setup failed: \(error)\n",stderr);exit(1)}
} else if let index = benchmarkIndex {
    let path = CommandLine.arguments.count > index+1 ? CommandLine.arguments[index+1] : "output/benchmark"
    benchmarkRunner = BenchmarkRunner(view: view, output: URL(fileURLWithPath: path))
    DispatchQueue.main.asyncAfter(deadline: .now()+0.5) { benchmarkRunner!.start() }
} else if let index = CommandLine.arguments.firstIndex(of: "--verify-library-scenes") {
    let path=CommandLine.arguments.count>index+1 ? CommandLine.arguments[index+1]:"output/library-scenes"
    DispatchQueue.main.asyncAfter(deadline:.now()+1) {
        do {try verifyLibraryScenes(view:view,switcher:sceneSwitcher!,output:URL(fileURLWithPath:path));exit(0)}
        catch {fputs("Library scene verification failed: \(error)\n",stderr);exit(1)}
    }
} else if let index = CommandLine.arguments.firstIndex(of: "--verify-integration") {
    let path = CommandLine.arguments.count > index+1 ? CommandLine.arguments[index+1] : "output/integration"
    demo!.playing = false
    DispatchQueue.main.asyncAfter(deadline: .now()+1) {
        do { try verifyIntegration(view: view,switcher: sceneSwitcher!,output: URL(fileURLWithPath: path)); exit(0) }
        catch { fputs("Integration verification failed: \(error)\n",stderr); exit(1) }
    }
} else if let index = CommandLine.arguments.firstIndex(of: "--verify") {
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
