#if os(macOS) || os(iOS)
import XCTest
@testable import Spine

final class SkinDescriptionTests: XCTestCase {
    func testOwnEntriesHaveStableOrderAndSourceTypesIncludingLinkedChain() throws {
        let textures = TestMeshTextures()
        let asset = try SpineMeshAsset(json: meshResource("skin-composition/mixed.json"), textures: textures)
        let requests = textures.requests
        let compilations = MeshAssetCompiler.compilationCount
        let description = try asset.skinDescription(named: "default")
        XCTAssertEqual(description.name, "default")
        let torso = description.entries.filter { $0.slot == "torso" }
        XCTAssertEqual(torso.map(\.name), ["box", "chain", "front", "linked", "mesh", "point", "side"])
        XCTAssertEqual(torso.map(\.kind), [.boundingBox, .linkedMesh, .region, .linkedMesh, .mesh, .point, .region])
        XCTAssertEqual(description.entries.first?.slot, "hat-front")
        XCTAssertEqual(try asset.skinDescription(named: "hat/a").entries.map(\.name), ["front", "side", "front", "side"])
        XCTAssertEqual(try asset.skinDescription(named: "empty").entries, [])
        for _ in 0..<20 {
            XCTAssertEqual(try asset.skinDescription(named: "default"), description)
            try asset.validate(skinComposition: .init(baseSkin: "base", layers: [.replace(skin: "hat/a", slots: ["hat-front", "hat-back"])]))
        }
        XCTAssertEqual(textures.requests, requests)
        XCTAssertEqual(MeshAssetCompiler.compilationCount, compilations)
        XCTAssertThrowsError(try asset.skinDescription(named: "missing/~")) {
            XCTAssertEqual(($0 as? SpineRuntimeError)?.code, .missingSkin)
            XCTAssertEqual(($0 as? SpineRuntimeError)?.path, "/skins/missing~1~0")
        }
    }
}
#endif
