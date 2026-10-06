#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

func managedNodes(_ root: SKNode) -> [SKNode] { [root] + root.children.flatMap(managedNodes) }

final class CompositionAtomicityTests: XCTestCase {
    private enum Injected: Error { case staging }
    func testContentAndStagingFailuresLeaveExactLiveStateAndReleaseStaging() throws {
        let h = try compositionHarness(), owner = h.skeleton
        h.start(try owner.action(animation: "walk")); h.advance(0.6)
        try owner.apply(skinComposition: hatA)
        try owner.prepareMeshes(for: validMeshContext)
        let runtime = try XCTUnwrap(owner.meshRuntime)
        let before = runtime.snapshot, nodes = managedNodes(runtime.managedVisuals)
        let parents = nodes.map { $0.parent.map(ObjectIdentifier.init) }
        let states = runtime.slotStates, colors = states.map(\.color)
        var diagnostics = 0; owner.meshDiagnosticHandler = { _ in diagnostics += 1 }
        weak var staged: SKNode?
        runtime.compositionStageCheck = { node in staged = node; throw Injected.staging }
        XCTAssertThrowsError(try autoreleasepool { try owner.apply(skinComposition: .init(baseSkin: "base", layers: [.overlay(skin: "hat/b")])) }) {
            guard case Injected.staging = $0 else { return XCTFail("Unexpected error \($0)") }
        }
        XCTAssertNil(staged)
        runtime.compositionStageCheck = nil
        let invalid = SpineSkinComposition(baseSkin: "base", layers: [.overlay(skin: "hat/b"), .hide(slots: ["absent"])])
        assertMeshError(try owner.apply(skinComposition: invalid), .missingSlot)
        assertMeshError(try owner.apply(skinComposition: .init(baseSkin: "default", layers: [])), .skinCompositionBaseMismatch)
        XCTAssertEqual(runtime.snapshot, before)
        XCTAssertEqual(owner.skinComposition, hatA)
        XCTAssertEqual(managedNodes(runtime.managedVisuals).map(ObjectIdentifier.init), nodes.map(ObjectIdentifier.init))
        XCTAssertEqual(nodes.map { $0.parent.map(ObjectIdentifier.init) }, parents)
        XCTAssertEqual(runtime.slotStates.map(ObjectIdentifier.init), states.map(ObjectIdentifier.init))
        XCTAssertEqual(runtime.slotStates.map(\.color), colors)
        XCTAssertEqual(diagnostics, 0); XCTAssertNil(owner.meshPlaybackError)
    }

    func testApplyAndValidateHaveIdenticalContentErrors() throws {
        let asset = try wardrobeAsset(), owner = try Skeleton(meshAsset: asset, skin: "base")
        for layers: [SpineSkinLayer] in [[.replace(skin: "partial", slots: ["hat-front"])], [.hide(slots: [])], [.overlay(skin: "missing")]] {
            let look = SpineSkinComposition(baseSkin: "base", layers: layers)
            var expected: SpineRuntimeError?
            do { try asset.validate(skinComposition: look) } catch { expected = error as? SpineRuntimeError }
            XCTAssertNotNil(expected)
            XCTAssertThrowsError(try owner.apply(skinComposition: look)) {
                let actual = $0 as? SpineRuntimeError
                XCTAssertEqual(actual?.code, expected?.code); XCTAssertEqual(actual?.path, expected?.path)
                XCTAssertEqual(actual?.message, expected?.message)
            }
        }
    }
}
#endif
