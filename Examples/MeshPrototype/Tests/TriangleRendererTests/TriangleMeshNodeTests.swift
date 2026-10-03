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

    func testTriangleBoundsReduceSubmittedAreaWithoutChangingTriangleArea() throws {
        let positions: [SIMD2<Float>] = [SIMD2(0,0), SIMD2(100,0), SIMD2(100,100), SIMD2(0,100), SIMD2(50,50)]
        let indices = [0,1,4, 1,2,4, 2,3,4, 3,0,4]
        let texture = SKTexture(data: Data([255,255,255,255]), size: CGSize(width: 1, height: 1))
        let baseline = try TriangleMeshNode(texture: texture, positions: positions, uvs: positions, indices: indices, boundsMode: .mesh)
        let optimized = try TriangleMeshNode(texture: texture, positions: positions, uvs: positions, indices: indices, boundsMode: .triangle)
        optimized.prepareForRendering(localToPixels: .identity)
        XCTAssertLessThan(optimized.submittedQuadArea, baseline.submittedQuadArea * 0.6)
        XCTAssertEqual(optimized.coveredTriangleArea, baseline.coveredTriangleArea, accuracy: 0.001)
        XCTAssertEqual(optimized.children.count, baseline.children.count)
    }

    func testSingularProjectionHidesGeometryAndCanRecover() throws {
        let node = try makeMesh()
        node.prepareForRendering(localToPixels: CGAffineTransform(scaleX: 0, y: 1))
        XCTAssertTrue(node.children.allSatisfy(\.isHidden))
        node.prepareForRendering(localToPixels: .identity)
        XCTAssertTrue(node.children.allSatisfy { !$0.isHidden })
    }

    func testChangingPixelDensityRecomputesPaddingWithoutChangingPose() throws {
        let node = try makeMesh()
        node.prepareForRendering(localToPixels: .identity)
        let initialArea = node.submittedQuadArea
        node.prepareForRendering(localToPixels: CGAffineTransform(scaleX: 4, y: 4))
        XCTAssertLessThan(node.submittedQuadArea, initialArea)
        XCTAssertEqual(node.positions, vertices)
    }
}
