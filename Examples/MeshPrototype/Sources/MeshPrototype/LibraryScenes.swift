import AppKit
import SpriteKit
import Spine

final class LibrarySceneResources {
    let asset:SpineMeshAsset
    init()throws {
        let root=Bundle.module.resourceURL!
        let atlas=try String(contentsOf:root.appendingPathComponent("goblins.atlas"),encoding:.utf8)
        let pages=["goblins.png":try Data(contentsOf:root.appendingPathComponent("goblins.png"))]
        let textures=try SpineAtlasTextureProvider(atlasText:atlas,pageData:pages)
        asset=try SpineMeshAsset(json:Data(contentsOf:root.appendingPathComponent("goblins-pro.json")),textures:textures)
    }
    func character(_ skin:String)throws->Skeleton {
        let character=try Skeleton(meshAsset:asset,skin:skin)
        character.run(.repeatForever(try character.action(animation:"walk")),withKey:"walk")
        return character
    }
}

final class LibraryDemoScene:SKScene {
    let goblin:Skeleton
    let girl:Skeleton
    var playing=true {didSet {for actor in [goblin,girl] {actor.isPaused = !playing}}}
    private let status=SKLabelNode(fontNamed:"Menlo")
    private var translucent=false
    init(resources:LibrarySceneResources)throws {
        goblin=try resources.character("goblin");girl=try resources.character("goblingirl")
        super.init(size:CGSize(width:1100,height:760));scaleMode = .aspectFit
        backgroundColor=NSColor(calibratedRed:0.065,green:0.078,blue:0.11,alpha:1)
        func label(_ text:String,_ point:CGPoint,_ size:CGFloat) {
            let node=SKLabelNode(fontNamed:"Menlo");node.text=text;node.fontSize=size;node.horizontalAlignmentMode = .left;node.position=point;addChild(node)
        }
        label("SPINE / LIBRARY MESH ANIMATION",CGPoint(x:40,y:710),25)
        label("Spine 4.1 · Skeleton + SKAction · shared asset, independent characters",CGPoint(x:40,y:676),13)
        for x:CGFloat in [40,560] {
            let panel=SKShapeNode(rect:CGRect(x:x,y:180,width:500,height:455),cornerRadius:16)
            panel.fillColor=NSColor(calibratedWhite:0.13,alpha:1);panel.strokeColor = .clear;panel.zPosition = -1;addChild(panel)
        }
        goblin.position=CGPoint(x:285,y:225);girl.position=CGPoint(x:805,y:225)
        for actor in [goblin,girl] {actor.setScale(0.95);addChild(actor)}
        label("GOBLIN",CGPoint(x:65,y:610),16);label("GOBLINGIRL",CGPoint(x:585,y:610),16)
        label("SPACE pause   A transparency   R mirror   0 reset",CGPoint(x:40,y:114),15)
        label("TAB switch scene   L switch Prototype / Library",CGPoint(x:40,y:80),13)
        status.fontSize=12;status.horizontalAlignmentMode = .left;status.position=CGPoint(x:40,y:34);addChild(status)
    }
    required init?(coder:NSCoder) {fatalError("Use init(resources:)")}
    override func didMove(to view:SKView) {for actor in [goblin,girl] {actor.isPaused = !playing}}
    override func willMove(from view:SKView) {for actor in [goblin,girl] {actor.isPaused=true}}
    override func didFinishUpdate() {
        guard let view=view else {return}
        do {
            // Final scene operation after SpriteKit actions, physics and all manual edits.
            try goblin.prepareMeshes(in:view);try girl.prepareMeshes(in:view)
            status.text=playing ? "LIBRARY · PLAYING":"LIBRARY · PAUSED"
        } catch {playing=false;status.text="ERROR: \(error.localizedDescription)"}
    }
    override func keyDown(with event:NSEvent) {
        do {
            if event.keyCode==49 {playing.toggle();return}
            switch event.charactersIgnoringModifiers?.lowercased() {
            case "a":translucent.toggle();for actor in [goblin,girl] {actor.alpha=translucent ? 0.5:1}
            case "r":for actor in [goblin,girl] {actor.xScale *= -1}
            case "0":
                for actor in [goblin,girl] {
                    actor.stopMeshAnimation(resetToSetupPose:true);actor.removeAction(forKey:"walk")
                    actor.setScale(0.95);actor.alpha=1
                    actor.run(.repeatForever(try actor.action(animation:"walk")),withKey:"walk")
                }
                translucent=false
            default:break
            }
        } catch {status.text="ERROR: \(error.localizedDescription)"}
    }
}
