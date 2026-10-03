#if os(macOS)
import XCTest
import AppKit
import SpriteKit
@testable import Spine

private final class NativeMeshTestScene: SKScene {
    var frameTime: TimeInterval = 0
    var finishedFrame: ((TimeInterval) -> Void)?
    override func update(_ currentTime: TimeInterval) { frameTime = currentTime }
    override func didFinishUpdate() { finishedFrame?(frameTime) }
}

final class NativeActionLifecycleTests: XCTestCase {
    func testNativeRepeatBoundariesPauseAndDynamicNodeSpeedThroughZero() throws {
        try runNativeLifecycle(changeActionSpeed: false)
    }

    func testNativeRepeatBoundariesPauseAndDynamicActionSpeedThroughZero() throws {
        try runNativeLifecycle(changeActionSpeed: true)
    }

    private func runNativeLifecycle(changeActionSpeed: Bool) throws {
        _ = NSApplication.shared
        let skeleton = try Skeleton(meshAsset: meshTestAsset(clips: [meshClip(duration: 0.3)]))
        let scene = NativeMeshTestScene(size: CGSize(width: 256,height: 160))
        scene.scaleMode = .aspectFit; scene.addChild(skeleton)
        let view = SKView(frame: CGRect(x: 0,y: 0,width: 256,height: 160))
        view.preferredFramesPerSecond = 60
        let window = NSWindow(contentRect: view.frame,styleMask: [.titled],backing: .buffered,defer: false)
        window.isReleasedWhenClosed = false
        window.title = "Spine native lifecycle checks"; window.contentView = view
        let completed = expectation(description: "Native SKView completes two owner-bound executions")
        var values: [Int] = []
        skeleton.eventTriggered = { values.append($0.int) }
        let container = SKAction.repeat(try skeleton.action(animation: "move"),count: 2)
        if changeActionSpeed { container.speed = 0.5 } else { skeleton.speed = 0.5 }
        skeleton.run(container,withKey: "clip")
        var phase = 0, since: TimeInterval = 0
        var frozen: [Float] = [], frozenTime: TimeInterval = 0
        var lastTime: TimeInterval = 0, lastExecution: UInt64?
        scene.finishedFrame = { currentTime in
            let state = skeleton.meshRuntime!.snapshot
            if let id = state.executionID {
                if id == lastExecution { XCTAssertGreaterThanOrEqual(state.time,lastTime) }
                lastExecution = id; lastTime = state.time
            }
            switch phase {
            case 0 where state.time > 0.06:
                phase = 1; since = currentTime
                frozen = state.deform[0]; frozenTime = state.time
                skeleton.isPaused = true
            case 1:
                XCTAssertEqual(state.deform[0],frozen)
                XCTAssertEqual(state.time,frozenTime)
                if currentTime-since > 0.12 {
                    skeleton.isPaused = false
                    if changeActionSpeed { skeleton.action(forKey: "clip")!.speed = 0 } else { skeleton.speed = 0 }
                    phase = 2; since = currentTime
                }
            case 2:
                XCTAssertEqual(state.deform[0],frozen)
                XCTAssertEqual(state.time,frozenTime)
                if currentTime-since > 0.12 {
                    if changeActionSpeed { skeleton.action(forKey: "clip")!.speed = 1.5 } else { skeleton.speed = 1.5 }
                    phase = 3
                }
            case 3 where !skeleton.hasActions():
                XCTAssertEqual(values,[0,1,0,1])
                XCTAssertEqual(state.beginCount,2)
                XCTAssertEqual(state.endCount,2)
                XCTAssertNil(state.executionID)
                XCTAssertNil(skeleton.meshPlaybackError)
                XCTAssertEqual(state.deform[0][0],20,accuracy: 1e-5)
                // No repeated zero-duration boundary, duplicate event or leaked lease.
                phase = 4; completed.fulfill()
            default: break
            }
        }
        view.presentScene(scene); window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        defer { scene.finishedFrame = nil; view.presentScene(nil); window.orderOut(nil); window.close() }
        wait(for: [completed],timeout: 6)
        XCTAssertEqual(phase,4)
    }
}
#endif
