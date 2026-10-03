import XCTest
import SpriteKit
@testable import TriangleRenderer

final class TriangleMeshNodeTests: XCTestCase {
    private let vertices: [SIMD2<Float>] = [SIMD2(0,0), SIMD2(1,0), SIMD2(0,1)]
    private func makeMesh(indices: [Int] = [0,1,2]) throws -> TriangleMeshNode {
        try TriangleMeshNode(texture: SKTexture(data: Data([255,255,255,255]), size: CGSize(width: 1, height: 1)),
                             positions: vertices, uvs: vertices, indices: indices)
    }
    func testMalformedTopologyIsRejectedBeforeRendering() {
        for indices in [[0,1], [0,1,3], [-1,1,2], []] {
            XCTAssertThrowsError(try makeMesh(indices: indices)) { XCTAssertEqual($0 as? MeshError, .invalidGeometry) }
        }
    }
    func testInvalidUpdateDoesNotReplaceLastValidPose() throws {
        let node = try makeMesh()
        XCTAssertThrowsError(try node.updatePositions([SIMD2(.nan, 0), vertices[1], vertices[2]]))
        XCTAssertThrowsError(try node.updatePositions(Array(vertices.dropLast())))
        XCTAssertEqual(node.positions, vertices)
    }
    func testCollapsedTriangleCanRecoverOnFollowingFrame() throws {
        let node = try makeMesh()
        let originalChildren = node.children
        try node.updatePositions([SIMD2(0,0), SIMD2(1,1), SIMD2(2,2)])
        XCTAssertTrue(node.children.allSatisfy(\.isHidden))
        try node.updatePositions(vertices)
        XCTAssertTrue(node.children.allSatisfy { !$0.isHidden })
        XCTAssertTrue(zip(originalChildren, node.children).allSatisfy { $0 === $1 })
    }
}
