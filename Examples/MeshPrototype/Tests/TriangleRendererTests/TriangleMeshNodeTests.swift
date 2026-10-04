import XCTest
import SpriteKit
@testable import TriangleRenderer

final class TriangleMeshNodeTests: XCTestCase {
    private let vertices: [SIMD2<Float>] = [SIMD2(0,0), SIMD2(1,0), SIMD2(0,1)]
    private func makeMesh(indices: [Int] = [0,1,2]) throws -> TriangleMeshNode {
        try TriangleMeshNode(texture: SKTexture(data: Data([255,255,255,255]), size: CGSize(width: 1, height: 1)),
                             positions: vertices, uvs: vertices, indices: indices, groupSize: .one)
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
        let baseline = try TriangleMeshNode(texture: texture, positions: positions, uvs: positions, indices: indices, boundsMode: .mesh, groupSize: .one)
        let optimized = try TriangleMeshNode(texture: texture, positions: positions, uvs: positions, indices: indices, boundsMode: .triangle, groupSize: .one)
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
    func testSharedMaterialKeepsProjectionAttributesIndependent() throws {
        let texture = SKTexture(data: Data([255,255,255,255]), size: CGSize(width: 1, height: 1))
        let material = TriangleMeshNode.Material(texture: texture)
        let first = try TriangleMeshNode(material: material, positions: vertices, uvs: vertices, indices: [0,1,2])
        let second = try TriangleMeshNode(material: material, positions: vertices, uvs: vertices, indices: [0,1,2])
        first.prepareForRendering(localToPixels: .identity)
        second.prepareForRendering(localToPixels: CGAffineTransform(translationX: 100, y: 50))
        let a = first.children[0].children[0] as! SKSpriteNode, b = second.children[0].children[0] as! SKSpriteNode
        XCTAssertTrue(a.shader === b.shader)
        XCTAssertEqual(a.value(forAttributeNamed: "a_rasterX")!.vectorFloat3Value, SIMD3(1,0,0))
        XCTAssertEqual(b.value(forAttributeNamed: "a_rasterX")!.vectorFloat3Value, SIMD3(1,0,-100))
        second.prepareForRendering(localToPixels: CGAffineTransform(translationX: 200, y: 50))
        XCTAssertEqual(a.value(forAttributeNamed: "a_rasterX")!.vectorFloat3Value, SIMD3(1,0,0))
    }

    func testUVAttributesFollowWindingChangesAndRecovery() throws {
        let node = try makeMesh()
        let sprite = node.children[0] as! SKSpriteNode
        try node.updatePositions([vertices[0], vertices[2], vertices[1]])
        XCTAssertEqual(sprite.value(forAttributeNamed: "a_uv1")!.vectorFloat2Value, vertices[2])
        try node.updatePositions([.zero, .zero, .zero])
        try node.updatePositions(vertices)
        XCTAssertEqual(sprite.value(forAttributeNamed: "a_uv1")!.vectorFloat2Value, vertices[1])
    }

    func testGroupsReuseFewerSpriteNodesAndRecoverCollapsedTriangles() throws {
        let texture = SKTexture(data: Data([255,255,255,255]), size: CGSize(width: 1,height: 1))
        let topology = [0,1,2, 0,2,1, 0,1,2]
        for size in [TriangleMeshNode.GroupSize.two, .four] {
            let node = try TriangleMeshNode(texture: texture, positions: vertices, uvs: vertices, indices: topology, groupSize: size)
            node.prepareForRendering(localToPixels: .identity)
            let sprites = node.children.flatMap { $0.children }.compactMap { $0 as? SKSpriteNode }
            XCTAssertEqual(sprites.count, size == .two ? 2 : 1)
            XCTAssertEqual(node.triangleCount, 3)
            XCTAssertEqual(node.coveredTriangleArea, 1.5, accuracy: 0.0001)
            try node.updatePositions([.zero,.zero,.zero])
            XCTAssertTrue(sprites.allSatisfy(\.isHidden))
            try node.updatePositions(vertices)
            XCTAssertTrue(sprites.allSatisfy { !$0.isHidden })
            XCTAssertEqual(node.coveredTriangleArea, 1.5, accuracy: 0.0001)
            node.prepareForRendering(localToPixels: CGAffineTransform(scaleX: 0,y: 1))
            XCTAssertTrue(sprites.allSatisfy(\.isHidden))
            node.prepareForRendering(localToPixels: .identity)
            XCTAssertTrue(sprites.allSatisfy { !$0.isHidden })
            // The partial group's unused shader slots must stay disabled.
            let unusedSlot = size == .two ? 1 : 3
            XCTAssertEqual(sprites.last!.value(forAttributeNamed: "a_t\(unusedSlot)_4")!.vectorFloat4Value.z, 0)
        }
    }

    func testTriangleDepthBandPreservesOrderAndStaysBelowNextSceneLayer() throws {
        let texture = SKTexture(data: Data([255,255,255,255]),size: CGSize(width: 1,height: 1))
        for size in TriangleMeshNode.GroupSize.allCases {
            let node = try TriangleMeshNode(texture: texture,positions: vertices,uvs: vertices,
                                            indices: [0,1,2,0,1,2,0,1,2,0,1,2,0,1,2],groupSize: size)
            node.setTriangleDepthSpan(0.01)
            let sprites = (node.children + node.children.flatMap(\.children)).compactMap { $0 as? SKSpriteNode }
            XCTAssertFalse(sprites.isEmpty)
            XCTAssertTrue(sprites.allSatisfy { $0.zPosition >= 0 && $0.zPosition < 0.01 })
            XCTAssertTrue(zip(sprites,sprites.dropFirst()).allSatisfy { $0.zPosition < $1.zPosition })
            let order = sprites.map(\.zPosition)
            try node.updatePositions([vertices[0],vertices[2],vertices[1]])
            XCTAssertEqual(sprites.map(\.zPosition),order)
        }
    }

}
