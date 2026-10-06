import SpriteKit
import Spine

final class WardrobeScene: SKScene {
    private(set) var preparedFrames = 0
    private let asset: SpineMeshAsset
    private var characters: [Skeleton] = []
    private var looks = [Wardrobe(), Wardrobe(hat: 1, clothes: 1, team: 1, earring: false)]
    private var selected = 0, changeOnEvent = false
    private var repeats = [true, true]
    private let status = SKLabelNode(fontNamed: "Menlo")

    init(asset: SpineMeshAsset) throws {
        self.asset = asset
        super.init(size: CGSize(width: 680, height: 520))
        scaleMode = .aspectFit; backgroundColor = .darkGray
        for i in 0..<2 {
            let owner = try Skeleton(meshAsset: asset, skin: "base")
            owner.position = CGPoint(x: 210 + i * 260, y: 290); owner.setScale(1.6)
            characters.append(owner); addChild(owner)
            try owner.apply(skinComposition: looks[i].composition)
            owner.eventTriggered = { [weak self, weak owner] _ in
                guard let self = self, let owner = owner, self.changeOnEvent else { return }
                self.perform {
                    self.looks[i].hat = 1 - self.looks[i].hat
                    try owner.apply(skinComposition: self.looks[i].composition)
                }
            }
            try play(at: i)
        }
        let names = ["Character", "Hat", "Clothes", "Earring", "Team", "Pause", "Speed", "Repeat", "Reset", "Event", "Play", "Base"]
        for (i, title) in names.enumerated() {
            let button = SKShapeNode(rectOf: CGSize(width: 100, height: 36), cornerRadius: 5)
            button.fillColor = .black; button.strokeColor = .lightGray
            button.position = CGPoint(x: 65 + (i % 6) * 110, y: 125 - (i / 6) * 48)
            button.name = title
            let label = SKLabelNode(fontNamed: "Helvetica"); label.text = title; label.fontSize = 14; label.verticalAlignmentMode = .center; label.name = title
            button.addChild(label); addChild(button)
        }
        status.fontSize = 12; status.position = CGPoint(x: 340, y: 485); addChild(status)
        updateStatus()
    }
    required init?(coder: NSCoder) { fatalError("Use init(asset:)") }
    deinit { for owner in characters { owner.eventTriggered = nil } }

    private func play(at index: Int) throws {
        let owner = characters[index]
        owner.stopMeshAnimation(); owner.removeAction(forKey: "walk")
        let action = try owner.action(animation: "walk")
        owner.run(repeats[index] ? .repeatForever(action) : action, withKey: "walk")
    }
    private func perform(_ operation: () throws -> Void) {
        do { try operation(); updateStatus() }
        catch { status.text = String(describing: error); print(error) }
    }
    private func updateStatus() {
        let owner = characters[selected]
        status.text = "Character \(selected + 1) | speed \(owner.speed) | pause \(owner.isPaused) | repeat \(repeats[selected]) | event \(changeOnEvent)"
    }
    private func press(at point: CGPoint) {
        guard let name = nodes(at: point).compactMap(\.name).first else { return }
        perform {
            let owner = characters[selected]
            switch name {
            case "Character": selected = 1 - selected
            case "Hat": looks[selected].hat = 1 - looks[selected].hat
            case "Clothes": looks[selected].clothes = 1 - looks[selected].clothes
            case "Earring": looks[selected].earring.toggle()
            case "Team": looks[selected].team = (looks[selected].team + 1) % 4
            case "Pause": owner.isPaused.toggle()
            case "Speed": owner.speed = owner.speed == 1 ? 0.5 : (owner.speed == 0.5 ? 2 : 1)
            case "Repeat": repeats[selected].toggle(); try play(at: selected)
            case "Reset": owner.stopMeshAnimation(resetToSetupPose: true); owner.removeAction(forKey: "walk")
            case "Event": changeOnEvent.toggle()
            case "Play": try play(at: selected)
            case "Base": try owner.apply(skinComposition: .init(baseSkin: "base", layers: [])); return
            default: return
            }
            if ["Hat", "Clothes", "Earring", "Team"].contains(name) { try owner.apply(skinComposition: looks[selected].composition) }
        }
    }
    override func didFinishUpdate() {
        guard let view = view else { return }
        do { for owner in characters { try owner.prepareMeshes(in: view) }; preparedFrames += 1 }
        catch { status.text = String(describing: error) }
    }
    #if os(macOS)
    override func mouseDown(with event: NSEvent) { press(at: event.location(in: self)) }
    #else
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first { press(at: touch.location(in: self)) }
    }
    #endif
}
