#if os(macOS)
import XCTest
import AppKit
import SpriteKit
@testable import Spine

private final class CompositionNativeScene: SKScene {
    var time: TimeInterval = 0
    var finish: ((TimeInterval) -> Void)?
    override func update(_ currentTime: TimeInterval) { time = currentTime }
    override func didFinishUpdate() { finish?(time) }
}

final class CompositionNativePlaybackTests: XCTestCase {
    func testNativeFinalEventCanStopAndRestartWithoutDeliveringOldTail() throws {
        _ = NSApplication.shared
        let owner = try Skeleton(meshAsset: wardrobeAsset(compositionEventJSON()), skin: "base")
        let scene = CompositionNativeScene(size: CGSize(width: 128, height: 128))
        scene.addChild(owner); owner.speed = 3
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 128, height: 128))
        let window = NSWindow(contentRect: view.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false; window.contentView = view
        let completed = expectation(description: "Replacement action completes")
        var events: [Int] = [], completions = 0
        owner.eventTriggered = { event in
            events.append(event.int)
            if event.int == 3 {
                do {
                    try owner.apply(skinComposition: hiddenHat)
                    owner.stopMeshAnimation(resetToSetupPose: false)
                    owner.removeAction(forKey: "old")
                    try owner.apply(skinComposition: hatA)
                    owner.run(.sequence([try owner.action(animation: "next"), .run { completions += 1 }]), withKey: "new")
                } catch { XCTFail("Final-event restart: \(error)") }
            }
        }
        var fulfilled = false
        scene.finish = { _ in
            do { try owner.prepareMeshes(in: view) } catch { XCTFail("Native prepare: \(error)") }
            if completions == 1, !fulfilled {
                fulfilled = true; completed.fulfill()
            }
        }
        owner.run(try owner.action(animation: "walk"), withKey: "old")
        view.presentScene(scene); window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        defer { scene.finish = nil; owner.eventTriggered = nil; view.presentScene(nil); window.orderOut(nil); window.close() }
        wait(for: [completed], timeout: 6)
        XCTAssertEqual(events, [0, 1, 2, 3, 9, 10]); XCTAssertEqual(completions, 1)
        XCTAssertEqual(owner.meshRuntime?.snapshot.beginCount, 2); XCTAssertEqual(owner.meshRuntime?.snapshot.endCount, 1)
        XCTAssertNil(owner.meshRuntime?.snapshot.executionID); XCTAssertNil(owner.meshPlaybackError)
        XCTAssertEqual(owner.skinComposition, hatA)
    }

    func testNativeNodeSpeedPauseAndEventChangesPreserveRepeatLifecycle() throws { try runLifecycle(actionSpeed: false) }
    func testNativeActionSpeedPauseAndEventChangesPreserveRepeatLifecycle() throws { try runLifecycle(actionSpeed: true) }

    private func runLifecycle(actionSpeed: Bool) throws {
        _ = NSApplication.shared
        let owner = try Skeleton(meshAsset: wardrobeAsset(compositionEventJSON()), skin: "base")
        try owner.apply(skinComposition: hatA)
        let scene = CompositionNativeScene(size: CGSize(width: 256, height: 160))
        scene.scaleMode = .aspectFit; scene.addChild(owner)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 256, height: 160))
        view.preferredFramesPerSecond = 60
        let window = NSWindow(contentRect: view.frame, styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false; window.contentView = view
        window.title = "Spine composition lifecycle checks"
        let completed = expectation(description: "Native composition repeat completes once")
        var events: [Int] = [], completions = 0
        owner.eventTriggered = { event in
            events.append(event.int)
            do {
                let before = owner.meshRuntime!.snapshot
                if event.int == 1 || event.int == 3 {
                    try owner.apply(skinComposition: hiddenHat)
                    assertMeshError(try owner.apply(skinComposition: .init(baseSkin: "base", layers: [.hide(slots: [])])), .invalidSkinComposition)
                    try owner.apply(skinComposition: hatA)
                }
                XCTAssertEqual(owner.meshRuntime!.snapshot.epoch, before.epoch)
                XCTAssertEqual(owner.meshRuntime!.snapshot.nextEvent, before.nextEvent)
                XCTAssertEqual(owner.meshRuntime!.snapshot.time, before.time)
            } catch { XCTFail("Native callback apply: \(error)") }
        }
        let container = SKAction.sequence([.repeat(try owner.action(animation: "walk"), count: 2), .run { completions += 1 }])
        if actionSpeed { container.speed = 0.5 } else { owner.speed = 0.5 }
        owner.run(container, withKey: "clip")
        var phase = 0, since: TimeInterval = 0, frozenTime: TimeInterval = 0
        var frozenRequest: [String?] = [], frozenColors: [SIMD4<Float>] = []
        scene.finish = { now in
            let runtime = owner.meshRuntime!, state = runtime.snapshot
            do {
                switch phase {
                case 0 where state.time > 0.1:
                    owner.isPaused = true
                    frozenTime = state.time; frozenRequest = state.requestedAttachments; frozenColors = runtime.slotStates.map(\.color)
                    try owner.apply(skinComposition: hiddenHat)
                    phase = 1; since = now
                case 1:
                    XCTAssertEqual(state.time, frozenTime); XCTAssertEqual(state.requestedAttachments, frozenRequest)
                    XCTAssertEqual(runtime.slotStates.map(\.color), frozenColors)
                    if now - since > 0.1 {
                        try owner.apply(skinComposition: hatA)
                        owner.isPaused = false
                        if actionSpeed { owner.action(forKey: "clip")!.speed = 0 } else { owner.speed = 0 }
                        phase = 2; since = now
                    }
                case 2:
                    XCTAssertEqual(state.time, frozenTime)
                    if now - since > 0.1 {
                        if actionSpeed { owner.action(forKey: "clip")!.speed = 2 } else { owner.speed = 2 }
                        phase = 3
                    }
                case 3 where !owner.hasActions():
                    XCTAssertEqual(events, [0, 1, 2, 3, 4, 0, 1, 2, 3, 4])
                    XCTAssertEqual(completions, 1); XCTAssertEqual(state.beginCount, 2); XCTAssertEqual(state.endCount, 2)
                    XCTAssertNil(state.executionID); XCTAssertNil(owner.meshPlaybackError)
                    XCTAssertEqual(owner.skinComposition, hatA)
                    phase = 4; completed.fulfill()
                default: break
                }
                // The production native frame boundary, after all actions and late appearance changes.
                try owner.prepareMeshes(in: view)
            } catch { XCTFail("Native frame: \(error)") }
        }
        view.presentScene(scene); window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        defer { scene.finish = nil; owner.eventTriggered = nil; view.presentScene(nil); window.orderOut(nil); window.close() }
        wait(for: [completed], timeout: 10)
        XCTAssertEqual(phase, 4)
    }
}
#endif
