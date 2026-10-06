#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class CompositionFrameTests: XCTestCase {
    func testCompositionDoesNotClearSingularVisibilityOrPlaybackFault() throws {
        let h = try compositionHarness(), owner = h.skeleton
        let runtime = try XCTUnwrap(owner.meshRuntime)
        let singular = SpineMeshFrameContext(skeletonToPixels: CGAffineTransform(scaleX: 0, y: 1), pixelSize: CGSize(width: 256, height: 256))
        try owner.prepareMeshes(for: singular)
        XCTAssertTrue(runtime.managedVisuals.isHidden)
        try owner.apply(skinComposition: hatA)
        XCTAssertTrue(runtime.managedVisuals.isHidden)
        try owner.prepareMeshes(for: validMeshContext)
        XCTAssertFalse(runtime.managedVisuals.isHidden)
        h.start(try owner.action(animation: "walk"))
        h.start(try owner.action(animation: "walk"), key: "second")
        let error = try XCTUnwrap(owner.meshPlaybackError)
        var diagnostics = 0; owner.meshDiagnosticHandler = { _ in diagnostics += 1 }
        try owner.apply(skinComposition: hiddenHat)
        XCTAssertEqual(owner.meshPlaybackError?.code, error.code)
        XCTAssertEqual(owner.meshPlaybackError?.path, error.path)
        XCTAssertTrue(runtime.managedVisuals.isHidden)
        assertMeshError(try owner.prepareMeshes(for: validMeshContext), .concurrentClip)
        XCTAssertEqual(diagnostics, 0)
    }

    func testPrepareUsesCurrentColorOrderAndApplyDoesNotClearFrameIncident() throws {
        let h = try compositionHarness(), owner = h.skeleton
        h.start(try owner.action(animation: "walk")); h.advance(0.6)
        let runtime = try XCTUnwrap(owner.meshRuntime), before = runtime.snapshot
        let colors = runtime.slotStates.map(\.color)
        try owner.apply(skinComposition: .init(baseSkin: "base", layers: [.overlay(skin: "clothes/a")]))
        XCTAssertEqual(runtime.snapshot, before); XCTAssertEqual(runtime.slotStates.map(\.color), colors)
        try owner.prepareMeshes(for: validMeshContext)
        let torso = try XCTUnwrap(runtime.setupRenderer?.regionNode(named: "front", slot: 2))
        XCTAssertEqual(torso.value(forAttributeNamed: "a_tint")?.vectorFloat4Value, colors[2] * SIMD4<Float>(0, 0, 1, 1))
        XCTAssertEqual(torso.zPosition, CGFloat(Float(2.0 / Double(runtime.slots.count))))
        runtime.bones[0].position.x = .nan
        XCTAssertThrowsError(try owner.prepareMeshes(for: validMeshContext))
        XCTAssertTrue(runtime.managedVisuals.isHidden)
        try owner.apply(skinComposition: hatA)
        XCTAssertTrue(runtime.managedVisuals.isHidden)
        runtime.bones[0].position.x = 0
        try owner.prepareMeshes(for: validMeshContext)
        XCTAssertFalse(runtime.managedVisuals.isHidden)
    }

    func testExactDescriptorNoOpAndOldRegionReleasesAfterCommit() throws {
        let owner = try Skeleton(meshAsset: wardrobeAsset(), skin: "base")
        let runtime = try XCTUnwrap(owner.meshRuntime)
        var retained: SKNode?
        weak var released: SKNode?
        try autoreleasepool {
            try owner.apply(skinComposition: hatA)
            retained = try XCTUnwrap(runtime.setupRenderer?.regionNode(named: "front", slot: 0))
            let snapshot = runtime.snapshot
            runtime.compositionStageCheck = { _ in XCTFail("Equal descriptor must not stage nodes") }
            try owner.apply(skinComposition: hatA)
            XCTAssertTrue(runtime.setupRenderer?.regionNode(named: "front", slot: 0) === retained)
            XCTAssertEqual(runtime.snapshot, snapshot)
            runtime.compositionStageCheck = nil
            released = runtime.setupRenderer?.regionNode(named: "side", slot: 0)
            try owner.apply(skinComposition: hiddenHat)
        }
        let old = try XCTUnwrap(retained)
        XCTAssertNil(released); XCTAssertNil(old.parent)
        let position = old.position
        runtime.bones[0].position.x = 42
        try owner.prepareMeshes(for: validMeshContext)
        XCTAssertEqual(old.position, position)
    }
}
#endif
