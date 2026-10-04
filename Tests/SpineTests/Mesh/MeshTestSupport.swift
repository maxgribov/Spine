#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
import Metal
@testable import Spine

func meshEvent(_ time: Double, _ value: Int) -> MeshClip.Event {
    .init(time: time, value: EventModel(name: "event", int: value, float: 0, string: nil, audio: nil, volume: 1, balance: 0))
}

func meshClip(_ name: String = "move", duration: Float = 1, events: [MeshClip.Event]? = nil) throws -> MeshClip {
    let keys = duration == 0 ? [MeshScalarTimeline.Key(0, 20)] : [.init(0, 0), .init(duration, 20)]
    let timeline = try MeshScalarTimeline(keys: keys)
    return try MeshClip(name: name, channels: [
        .init(target: .boneX(0), timeline: timeline),
        .init(target: .deform(slot: 0, component: 0), timeline: timeline)
    ], events: events ?? [meshEvent(0, 0), meshEvent(Double(duration), 1)].filter { duration > 0 || $0.value.int == 0 })
}

func meshTestAsset(clips: [MeshClip]? = nil) throws -> SpineMeshAsset {
    // A compiled fixture only; no phase-3 loader/compiler is used to exercise lifecycle.
    let bone = BoneModel(name: "root", parent: nil, lenght: 0, transform: .normal,
                         position: CGPoint(x: 3, y: 4), rotation: 20, scale: CGVector(dx: 2,dy: 0.5),
                         shear: .zero, inheritScale: true, inheritRotation: true, color: .init(value: "ffffffff"))
    let slot = SlotModel(name: "slot", bone: "root", color: .init(value: "ffffffff"), dark: nil, attachment: "mesh", blend: .normal)
    return SpineMeshAsset(compiled: CompiledMeshSkeleton(bones: [bone], slots: [slot], deformComponentCounts: [2],
                                                         clips: try clips ?? [meshClip(), meshClip("other")], skinNames: ["default"]))
}

final class MeshActionHarness {
    let scene = SKScene(size: CGSize(width: 256,height: 256))
    let renderer: SKRenderer
    let skeleton: Skeleton
    var time: Double = 0

    init(asset: SpineMeshAsset? = nil) throws {
        #if os(macOS)
        _ = NSApplication.shared
        #endif
        guard let device = MTLCreateSystemDefaultDevice() else { throw XCTSkip("Real SpriteKit action tests require a Metal device") }
        renderer = SKRenderer(device: device)
        skeleton = try Skeleton(meshAsset: asset ?? meshTestAsset())
        scene.scaleMode = .aspectFit; scene.physicsWorld.gravity = .zero
        scene.addChild(skeleton)
        renderer.scene = scene; renderer.update(atTime: 100)
    }

    func update(_ time: Double) {
        self.time = time
        renderer.update(atTime: 100 + time)
    }
    func advance(_ seconds: Double) {
        let target = time + seconds
        while time + 1/60 < target - 1e-10 { update(time + 1/60) }
        update(target)
    }
    func start(_ action: SKAction, key: String = "clip", on node: SKNode? = nil) {
        (node ?? skeleton).run(action, withKey: key)
        update(time)
    }
    var snapshot: MeshPlaybackSnapshot { skeleton.meshRuntime!.snapshot }
    var bone: SKSpriteNode { skeleton.boneNode(named: "root")! }
}

func assertMeshError(_ expression: @autoclosure () throws -> Void, _ code: SpineRuntimeError.Code,
                     path: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertThrowsError(try expression(), file: file, line: line) { error in
        guard let error = error as? SpineRuntimeError else { return XCTFail("Wrong error type: \(error)",file: file,line: line) }
        XCTAssertEqual(error.code, code, file: file,line: line)
        if let path = path { XCTAssertEqual(error.path,path,file:file,line:line) }
    }
}
let validMeshContext = SpineMeshFrameContext(skeletonToPixels: .identity, pixelSize: CGSize(width: 256,height: 256))
#endif
