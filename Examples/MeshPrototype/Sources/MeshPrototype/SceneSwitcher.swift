import AppKit
import SpriteKit
import TriangleRenderer

final class PrototypeView: SKView {
    var switchScene: (() -> Void)?
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 48,let switchScene = switchScene { switchScene() }
        else { super.keyDown(with: event) }
    }
}

/// Keeps both scenes alive so switching preserves each scene's controls/playhead.
final class SceneSwitcher: NSObject {
    private let view: PrototypeView
    let demo: DemoScene
    private(set) var integration: IntegrationScene?
    private let boundsMode: TriangleMeshNode.BoundsMode
    private let groupSize: TriangleMeshNode.GroupSize
    private(set) var selectedIndex = 0
    private(set) var control: NSSegmentedControl!

    init(view: PrototypeView, demo: DemoScene, boundsMode: TriangleMeshNode.BoundsMode, groupSize: TriangleMeshNode.GroupSize) {
        self.view = view; self.demo = demo; self.boundsMode = boundsMode; self.groupSize = groupSize
        super.init()
        control = NSSegmentedControl(labels: ["Mesh demo", "Integration scene"],trackingMode: .selectOne,target: self,action: #selector(selectionChanged))
        control.selectedSegment = 0
        view.switchScene = { [weak self] in self?.select(1-(self?.selectedIndex ?? 0)) }
    }
    @objc private func selectionChanged() { select(control.selectedSegment) }
    func select(_ index: Int) {
        guard index == 0 || index == 1 else { return }
        do {
            if index == 1 && integration == nil {
                integration = try IntegrationScene(boundsMode: boundsMode,groupSize: groupSize)
            }
            let scene: SKScene = index == 0 ? demo : integration!
            if view.scene !== scene { view.presentScene(scene) }
            selectedIndex = index; control.selectedSegment = index
            view.window?.makeFirstResponder(view)
        } catch {
            control.selectedSegment = selectedIndex
            fputs("Scene switch failed: \(error)\n",stderr)
        }
    }
}
