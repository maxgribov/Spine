import AppKit
import SpriteKit
import TriangleRenderer

final class PrototypeView: SKView {
    var switchScene: (() -> Void)?
    var switchRuntime:(()->Void)?
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 48,let switchScene = switchScene { switchScene() }
        else if event.charactersIgnoringModifiers?.lowercased()=="l",let switchRuntime=switchRuntime {switchRuntime()}
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
    private(set) var libraryDemo:LibraryDemoScene?
    private(set) var libraryIntegration:LibraryIntegrationScene?
    private var libraryResources:LibrarySceneResources?
    private(set) var usesLibrary=false
    private(set) var runtimeControl:NSSegmentedControl!
    private(set) var selectedIndex = 0
    private(set) var control: NSSegmentedControl!

    init(view: PrototypeView, demo: DemoScene, boundsMode: TriangleMeshNode.BoundsMode, groupSize: TriangleMeshNode.GroupSize) {
        self.view = view; self.demo = demo; self.boundsMode = boundsMode; self.groupSize = groupSize
        super.init()
        control = NSSegmentedControl(labels: ["Mesh demo", "Integration scene"],trackingMode: .selectOne,target: self,action: #selector(selectionChanged))
        control.selectedSegment = 0
        runtimeControl=NSSegmentedControl(labels:["Prototype","Library"],trackingMode:.selectOne,target:self,action:#selector(runtimeChanged))
        runtimeControl.selectedSegment=0
        view.switchRuntime={ [weak self] in guard let self=self else{return};self.selectRuntime(!self.usesLibrary) }
        view.switchScene = { [weak self] in self?.select(1-(self?.selectedIndex ?? 0)) }
    }
    @objc private func runtimeChanged() {selectRuntime(runtimeControl.selectedSegment==1)}
    func selectRuntime(_ library:Bool) {
        let previous=usesLibrary;usesLibrary=library
        if !select(selectedIndex) {usesLibrary=previous}
        runtimeControl.selectedSegment=usesLibrary ? 1:0
    }
    @objc private func selectionChanged() { select(control.selectedSegment) }
    @discardableResult func select(_ index: Int) -> Bool {
        guard index == 0 || index == 1 else { return false }
        do {
            if !usesLibrary && index == 1 && integration == nil {
                integration = try IntegrationScene(boundsMode: boundsMode,groupSize: groupSize)
            }
            let scene:SKScene
            if usesLibrary {
                if libraryResources==nil {libraryResources=try LibrarySceneResources()}
                if index==0 {
                    if libraryDemo==nil {libraryDemo=try LibraryDemoScene(resources:libraryResources!)}
                    scene=libraryDemo!
                } else {
                    if libraryIntegration==nil {libraryIntegration=try LibraryIntegrationScene(resources:libraryResources!)}
                    scene=libraryIntegration!
                }
            } else {scene=index==0 ? demo:integration!}
            if view.scene !== scene { view.presentScene(scene) }
            selectedIndex = index; control.selectedSegment = index
            view.window?.makeFirstResponder(view)
            return true
        } catch {
            control.selectedSegment = selectedIndex
            fputs("Scene switch failed: \(error)\n",stderr)
            return false
        }
    }
}
