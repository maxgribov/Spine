import XCTest
import SpriteKit
import Spine

/// Client code uses only the API available at d1cbd6e. No frame preparation hook.
final class LegacyConstructionTests: XCTestCase {
    func testUnchangedModelConstructorsAndPublicNodes() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "legacy-4.1", withExtension: "json"))
        let model = try JSONDecoder().decode(SpineModel.self, from: Data(contentsOf: url))
        let texture = SKTexture(data: Data(repeating: 255, count: 16), size: CGSize(width: 2, height: 2))
        #if os(macOS)
        let image = NSImage(cgImage: texture.cgImage(), size: texture.size())
        #else
        let image = UIImage(cgImage: texture.cgImage())
        #endif
        let atlas = SKTextureAtlas(dictionary: ["body": image, "open": image, "closed": image])
        let character = Skeleton(model, ["default": atlas])
        try character.applyDefaultSkin()
        XCTAssertNotNil(character.boneNode(named: "root"))
        XCTAssertEqual(character.slotNode(named: "hand")?.parent, character.boneNode(named: "arm"))
        let region = try XCTUnwrap(character.regionAttachmentNode(named: "body"))
        region.texture = texture
        XCTAssertTrue(region.texture === texture)
        try character.apply(texture: texture, region: "body")
        XCTAssertEqual(character.points?.count, 1)
        XCTAssertNotNil(character.slotNode(named: "hitbox")?.physicsBody)
        character.setBitMasks(category: 4, collision: 8)
        XCTAssertEqual(character.slotNode(named: "hitbox")?.physicsBody?.categoryBitMask, 4)
        XCTAssertEqual(character.slotNode(named: "hitbox")?.physicsBody?.collisionBitMask, 8)
        XCTAssertEqual(Set(character.skinsNames), ["default", "alternate"])
        XCTAssertEqual(character.animationsNames, ["motion"])
        XCTAssertGreaterThan(try character.action(animation: "motion").duration, 0)
        XCTAssertNotNil(try character.action(applySkin: "alternate"))
        XCTAssertNotNil(character.dropToDefaultsAction())
        try character.run(animation: "motion")
        character.removeAllActions()
        let folderConstructor = Skeleton(model, atlas: "missing-baseline-atlas")
        XCTAssertNotNil(folderConstructor.boneNode(named: "arm"))
        let defaultConstructor = Skeleton(model)
        XCTAssertNotNil(defaultConstructor.boneNode(named: "root"))
    }

    func testDeprecatedAndBundleConstructorSignaturesRemainCallable() throws {
        // Bundle-backed success is exercised by the executable characterization runner.
        XCTAssertThrowsError(try Skeleton(json: "missing-baseline-fixture", folder: nil, skin: nil))
        XCTAssertNil(Skeleton(fromJSON: "missing-baseline-fixture", atlas: nil, skin: nil))
        let model = try JSONDecoder().decode(SpineModel.self, from: Data(contentsOf:
            XCTUnwrap(Bundle.module.url(forResource: "legacy-4.1", withExtension: "json"))))
        let character = Skeleton(model, [:])
        XCTAssertNotNil(character.animation(named: "motion"))
        character.applySkin(named: "alternate")
        XCTAssertNotNil(character.boneNode(named: "root"))
    }
}
