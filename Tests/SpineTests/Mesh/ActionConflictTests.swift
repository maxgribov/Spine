#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class ActionConflictTests: XCTestCase {
    func testConcurrentSameDifferentAndCopiedActionsFaultBeforeConflictingWrites() throws {
        for kind in ["same", "different", "copy"] {
            let h = try MeshActionHarness()
            let independent = try Skeleton(meshAsset: meshTestAsset())
            h.scene.addChild(independent)
            independent.run(try independent.action(animation: "move"))
            var diagnostics: [SpineRuntimeError] = []
            h.skeleton.meshDiagnosticHandler = { diagnostics.append($0) }
            let first = try h.skeleton.action(animation: "move")
            h.start(first)
            h.advance(0.3)
            let pose = h.bone.position, deformation = h.snapshot.deform
            let second: SKAction
            if kind == "same" { second = try h.skeleton.action(animation: "move") }
            else if kind == "copy" { second = first.copy() as! SKAction }
            else { second = try h.skeleton.action(animation: "other") }
            h.start(second,key: "conflict")
            XCTAssertEqual(h.skeleton.meshPlaybackError?.code,.concurrentClip,kind)
            XCTAssertEqual(h.bone.position,pose,kind)
            XCTAssertEqual(h.snapshot.deform,deformation,kind)
            XCTAssertEqual(diagnostics.count,1,kind)
            XCTAssertTrue(h.skeleton.meshRuntime!.managedVisuals.isHidden)
            XCTAssertFalse(independent.meshRuntime!.managedVisuals.isHidden)
            h.advance(0.4)
            XCTAssertEqual(h.bone.position,pose,kind)
            XCTAssertEqual(h.snapshot.deform,deformation,kind)
            XCTAssertNil(independent.meshPlaybackError)
            assertMeshError(try h.skeleton.prepareMeshes(for: validMeshContext),.concurrentClip)
            XCTAssertEqual(diagnostics.count,1)
            h.skeleton.stopMeshAnimation()
            XCTAssertNil(h.skeleton.meshPlaybackError)
            XCTAssertNil(h.snapshot.executionID)
            h.start(try h.skeleton.action(animation: "move"),key: "fresh")
            h.advance(0.3)
            XCTAssertNil(h.skeleton.meshPlaybackError)
            XCTAssertGreaterThan(h.snapshot.deform[0][0],0)
        }
    }

    func testSimultaneousCopiesInGroupAreDistinctActivations() throws {
        let h = try MeshActionHarness()
        let action = try h.skeleton.action(animation: "move")
        h.start(.group([action,action.copy() as! SKAction]))
        XCTAssertEqual(h.skeleton.meshPlaybackError?.code,.concurrentClip)
        XCTAssertEqual(h.snapshot.beginCount,1)
    }

    func testMissingAnimationAndRuntimeErrorPathsEscapeNames() throws {
        let name = "walk/a~b"
        let h = try MeshActionHarness(asset: meshTestAsset(clips: [meshClip(name)]))
        h.start(try h.skeleton.action(animation: name))
        h.start(try h.skeleton.action(animation: name),key:"second")
        XCTAssertEqual(h.skeleton.meshPlaybackError?.path,"/runtime/animations/walk~1a~0b")
        assertMeshError(try { _ = try h.skeleton.action(animation: "missing/a~b") }(),.missingAnimation,path:"/animations/missing~1a~0b")
    }
}
#endif
