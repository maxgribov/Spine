import SpriteKit
import TriangleRenderer

/// A separate scene exercising meshes alongside ordinary SpriteKit content.
final class IntegrationScene: SKScene {
    let goblin: Goblin
    let girl: Goblin
    let world = SKNode()
    let sceneCamera = SKCameraNode()
    let hud = SKNode()
    private var depthObjects: [SKNode] = []
    private var motes: [SKSpriteNode] = []
    private let status = SKLabelNode(fontNamed: "Menlo")
    private var previousTime: TimeInterval?
    private(set) var playhead: Double = 0
    var playing = true
    var cameraMotion = true
    var translucent = false
    var manualZoom: CGFloat = 1
    var mirrored = false

    init(boundsMode: TriangleMeshNode.BoundsMode = .triangle, groupSize: TriangleMeshNode.GroupSize = .two) throws {
        goblin = try Goblin(skin: "goblin", boundsMode: boundsMode, groupSize: groupSize)
        girl = try Goblin(skin: "goblingirl", boundsMode: boundsMode, groupSize: groupSize)
        super.init(size: CGSize(width: 1100,height: 760))
        scaleMode = .aspectFit
        backgroundColor = NSColor(red: 0.075,green: 0.13,blue: 0.14,alpha: 1)
        addChild(world); addChild(sceneCamera); camera = sceneCamera
        sceneCamera.addChild(hud); hud.zPosition = 1000
        buildEnvironment()
        for actor in [goblin,girl] {
            actor.confineDrawOrder(to: 1)
            world.addChild(actor); depthObjects.append(actor)
        }
        addLabel("FOREST CROSSING", at: CGPoint(x: -505,y: 320), size: 26, to: hud)
        addLabel("Two travellers, one shared world", at: CGPoint(x: -505,y: 292), size: 14, to: hud, color: .lightGray)
        let bar = SKSpriteNode(color: NSColor(white: 0.04,alpha: 0.88), size: CGSize(width: 1100,height: 95))
        bar.position.y = -332; bar.zPosition = -1; hud.addChild(bar)
        addLabel("SPACE pause   ← / → step   C camera   + / − zoom", at: CGPoint(x: -505,y: -315), size: 14, to: hud)
        addLabel("A transparency   W wireframe   R mirror   0 reset   TAB switch scene", at: CGPoint(x: -505,y: -340), size: 13, to: hud, color: .lightGray)
        status.fontSize = 12; status.horizontalAlignmentMode = .right
        status.position = CGPoint(x: 505,y: 323); hud.addChild(status)
        try sample(0)
    }
    required init?(coder: NSCoder) { fatalError("Use init(boundsMode:groupSize:)") }
    override func didMove(to view: SKView) { previousTime = nil }

    private func addLabel(_ text: String, at point: CGPoint, size: CGFloat, to parent: SKNode, color: NSColor = .white) {
        let label = SKLabelNode(fontNamed: "Menlo")
        label.text = text; label.fontSize = size; label.fontColor = color
        label.horizontalAlignmentMode = .left; label.position = point; parent.addChild(label)
    }
    private func rect(_ size: CGSize, color: NSColor, at point: CGPoint, parent: SKNode, z: CGFloat = 0) {
        let node = SKSpriteNode(color: color,size: size)
        node.position = point; node.zPosition = z; parent.addChild(node)
    }
    private func ellipse(_ rect: CGRect, color: NSColor, parent: SKNode, z: CGFloat = 0) {
        let node = SKShapeNode(ellipseIn: rect)
        node.fillColor = color; node.strokeColor = .clear; node.zPosition = z; parent.addChild(node)
    }
    private func tree(at point: CGPoint, scale: CGFloat, name: String? = nil) {
        let root = SKNode(); root.name = name; root.position = point; root.setScale(scale)
        world.addChild(root); depthObjects.append(root)
        ellipse(CGRect(x: -64,y: -14,width: 128,height: 30), color: NSColor(white: 0,alpha: 0.18), parent: root)
        rect(CGSize(width: 26,height: 160),color: NSColor(red: 0.28,green: 0.22,blue: 0.15,alpha: 1),at: CGPoint(x: 0,y: 77),parent: root,z: 0.1)
        for index in 0..<3 {
            let y = CGFloat(index)*48+67, width = CGFloat(190-index*36)
            let path = CGMutablePath(); path.move(to: CGPoint(x: -width/2,y: y))
            path.addLine(to: CGPoint(x: 0,y: y+115)); path.addLine(to: CGPoint(x: width/2,y: y)); path.closeSubpath()
            let crown = SKShapeNode(path: path)
            crown.fillColor = NSColor(red: 0.09+CGFloat(index)*0.018,green: 0.24+CGFloat(index)*0.027,blue: 0.21,alpha: 1)
            crown.strokeColor = NSColor(white: 1,alpha: 0.05); crown.zPosition = 0.2+CGFloat(index)*0.1
            root.addChild(crown)
        }
    }
    private func buildEnvironment() {
        rect(CGSize(width: 2000,height: 1400),color: NSColor(red: 0.13,green: 0.22,blue: 0.20,alpha: 1),at: CGPoint(x: 550,y: 380),parent: world,z: -100)
        ellipse(CGRect(x: -140,y: 215,width: 1380,height: 265),color: NSColor(red: 0.28,green: 0.29,blue: 0.23,alpha: 1),parent: world,z: -90)
        ellipse(CGRect(x: -120,y: 230,width: 1340,height: 232),color: NSColor(red: 0.34,green: 0.33,blue: 0.25,alpha: 1),parent: world,z: -89)
        for index in 0..<70 {
            let x = CGFloat((index*137+41)%1400)-150, y = CGFloat((index*83+79)%570)+55
            if y > 230 && y < 450 { continue }
            rect(CGSize(width: 3,height: 10),color: NSColor(red: 0.35,green: 0.43,blue: 0.26,alpha: 0.65),at: CGPoint(x: x,y: y),parent: world,z: -80)
        }
        tree(at: CGPoint(x: 135,y: 415),scale: 1.15)
        tree(at: CGPoint(x: 915,y: 400),scale: 1.05)
        tree(at: CGPoint(x: 730,y: 335),scale: 0.85,name: "crossing-tree")
        // The fence is sorted as one object by its ground contact point.
        let fence = SKNode(); fence.name = "fence"; fence.position = CGPoint(x: 550,y: 335)
        world.addChild(fence); depthObjects.append(fence)
        ellipse(CGRect(x: -95,y: -10,width: 190,height: 20),color: NSColor(white: 0,alpha: 0.16),parent: fence)
        for x: CGFloat in [-82,0,82] {
            rect(CGSize(width: 13,height: 90),color: NSColor(red: 0.53,green: 0.36,blue: 0.20,alpha: 1),at: CGPoint(x: x,y: 40),parent: fence,z: 0.1)
        }
        for y: CGFloat in [27,62] {
            rect(CGSize(width: 182,height: 13),color: NSColor(red: 0.67,green: 0.48,blue: 0.27,alpha: 1),at: CGPoint(x: 0,y: y),parent: fence,z: 0.2)
        }
        // Ordinary transparent sprites overlap both the environment and meshes.
        for index in 0..<12 {
            let mote = SKSpriteNode(color: NSColor(red: 0.95,green: 0.84,blue: 0.40,alpha: 1),size: CGSize(width: 4,height: 4))
            mote.zPosition = 300; world.addChild(mote); motes.append(mote)
            mote.name = "mote-\(index)"
        }
        let foreground = SKNode(); foreground.zPosition = 400; world.addChild(foreground)
        for index in 0..<12 {
            let x = CGFloat(index)*108-60
            ellipse(CGRect(x: x,y: 112+CGFloat(index%3)*12,width: 135,height: 50),color: NSColor(red: 0.08,green: 0.18,blue: 0.17,alpha: 0.65),parent: foreground)
        }
    }

    func sample(_ time: Double) throws {
        playhead = max(0,time)
        let phase = playhead*0.4
        goblin.position = CGPoint(x: 550+250*sin(phase),y: 335+55*cos(phase))
        girl.position = CGPoint(x: 550-250*sin(phase),y: 335-55*cos(phase))
        goblin.setScale(0.65); girl.setScale(0.65)
        goblin.xScale *= (cos(phase) < 0 ? -1 : 1) * (mirrored ? -1 : 1)
        girl.xScale *= (cos(phase) < 0 ? 1 : -1) * (mirrored ? -1 : 1)
        for (index,actor) in [goblin,girl].enumerated() {
            actor.alpha = translucent ? 0.5 : 1
            try actor.sample(time: Float((playhead+Double(index)*0.27).truncatingRemainder(dividingBy: Double(actor.duration))))
        }
        // Stable depth bands: every object's descendants remain in [root, root+1).
        let ordered = depthObjects.enumerated().sorted {
            $0.element.position.y == $1.element.position.y ? $0.offset < $1.offset : $0.element.position.y > $1.element.position.y
        }
        for (rank,entry) in ordered.enumerated() { entry.element.zPosition = 100+CGFloat(rank)*2 }
        for (index,mote) in motes.enumerated() {
            let t = playhead*0.4+Double(index)*1.7
            mote.position = CGPoint(x: 180+Double(index)*67+sin(t)*18,y: 320+Double(index%4)*42+cos(t*1.3)*22)
            mote.alpha = 0.3+CGFloat((sin(t)+1)*0.3)
        }
        sceneCamera.position = CGPoint(x: 550+(cameraMotion ? sin(playhead*0.19)*55 : 0),y: 380+(cameraMotion ? sin(playhead*0.23)*18 : 0))
        sceneCamera.setScale(manualZoom*(cameraMotion ? 1+CGFloat(sin(playhead*0.17))*0.08 : 1))
        sceneCamera.zRotation = cameraMotion ? CGFloat(sin(playhead*0.13))*0.025 : 0
        status.text = "\(playing ? "PLAYING" : "PAUSED")  ·  \(cameraMotion ? "CAMERA ON" : "CAMERA OFF")  ·  \(translucent ? "50% ALPHA" : "OPAQUE")"
    }
    override func update(_ currentTime: TimeInterval) {
        defer { previousTime = currentTime }
        guard playing,let previous = previousTime else { return }
        do { try sample(playhead+min(currentTime-previous,0.1)) }
        catch { playing = false; status.text = "ERROR: \(error)" }
    }
    override func didFinishUpdate() { if let view = view { prepareRasterCoordinates(scene: self,view: view) } }
    override func keyDown(with event: NSEvent) {
        do {
            switch event.keyCode {
            case 49: playing.toggle()
            case 123,124: playing = false; try sample(playhead+(event.keyCode == 124 ? 1.0/30 : -1.0/30))
            default:
                switch event.charactersIgnoringModifiers?.lowercased() {
                case "c": cameraMotion.toggle()
                case "a": translucent.toggle()
                case "w": goblin.showsWireframe.toggle(); girl.showsWireframe = goblin.showsWireframe
                case "r": mirrored.toggle()
                case "+","=": manualZoom = max(0.65,manualZoom/1.1)
                case "-": manualZoom = min(1.4,manualZoom*1.1)
                case "0": manualZoom = 1; cameraMotion = true; mirrored = false; translucent = false; try sample(0)
                default: break
                }
            }
            try sample(playhead)
        } catch { fputs("Integration input failed: \(error)\n",stderr) }
    }
}
