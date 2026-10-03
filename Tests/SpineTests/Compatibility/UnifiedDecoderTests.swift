import XCTest
@testable import Spine

final class UnifiedDecoderTests: XCTestCase {
    func testExistingESSFixtureAndDefaults() throws {
        let data = try Data(contentsOf: XCTUnwrap(Bundle.module.url(forResource: "spineboy-ess", withExtension: "json")))
        let model = try JSONDecoder().decode(SpineModel.self, from: data)
        XCTAssertEqual(model.skeleton.spine, "4.1.17")
        XCTAssertEqual(model.bones.first?.name, "root")
        let minimal = try decode(version: "4.1.17")
        XCTAssertTrue(minimal.bones.isEmpty)
        XCTAssertTrue(minimal.slots.isEmpty)
        XCTAssertTrue(minimal.skins.isEmpty)
        XCTAssertTrue(minimal.animations.isEmpty)
        XCTAssertEqual(minimal.skeleton.fps, 30)
    }

    func testDecoderDoesNotAddGlobalVersionOrUnknownFieldGate() throws {
        for version in ["4.1.17", "historically-accepted-metadata", "4.0.00"] {
            XCTAssertNoThrow(try decode(version: version))
        }
        // Previously ignored mesh/timeline-shaped data must not select another loader.
        let json = #"{"skeleton":{"hash":"test","spine":"4.1.17","x":0,"y":0,"width":1,"height":1},"animations":{"ignored":{"attachments":{"default":{"s":{"m":{"deform":[{}]}}}}}},"unknown":{"meshes":true}}"#
        XCTAssertNoThrow(try JSONDecoder().decode(SpineModel.self, from: Data(json.utf8)))
    }

    func testMalformedVersionRetainsDecodingError() {
        let json = #"{"skeleton":{"hash":"test","spine":41,"x":0,"y":0,"width":1,"height":1}}"#
        XCTAssertThrowsError(try JSONDecoder().decode(SpineModel.self, from: Data(json.utf8))) { error in
            guard case DecodingError.typeMismatch(_, let context) = error else {
                return XCTFail("Expected existing DecodingError, got \(error)")
            }
            XCTAssertEqual(context.codingPath.map(\.stringValue), ["skeleton", "spine"])
        }
    }

    private func decode(version: String) throws -> SpineModel {
        let data = try JSONSerialization.data(withJSONObject: ["skeleton": ["hash": "test", "spine": version, "x": 0, "y": 0, "width": 1, "height": 1]])
        return try JSONDecoder().decode(SpineModel.self, from: data)
    }
}
