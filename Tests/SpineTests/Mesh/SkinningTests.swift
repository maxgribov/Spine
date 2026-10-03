#if os(macOS) || os(iOS)
import XCTest
@testable import Spine

final class SkinningTests:XCTestCase {
    func testUnweightedDeformAndForwardNonuniformReflectedMatrix()throws {
        let geometry=MeshGeometry(vertices:.unweighted(boneIndex:0,positions:[SIMD2(2,3)]),indices:[],sourceUVs:[.zero],deformCount:2)
        let mesh=CompiledMesh(geometry:geometry,uvs:[.zero],deformSourceID:0)
        var output=[SIMD2<Float>.zero]
        try computeMeshPositions(mesh,boneMatrices:[CGAffineTransform(a:-2,b:0,c:0,d:3,tx:5,ty:7)],deform:[SIMD2(1,-1)],into:&output)
        XCTAssertEqual(output[0],SIMD2(-1,13))
        try computeMeshPositions(mesh,boneMatrices:[CGAffineTransform(a:0,b:0,c:0,d:0,tx:5,ty:7)],deform:[.zero],into:&output)
        XCTAssertEqual(output[0],SIMD2(5,7))
    }
    func testMoreThanFourInfluencesAreNotNormalizedAndDeformIsPerInfluence()throws {
        let influences=(0..<6).map {MeshInfluence(boneIndex:$0,position:SIMD2(1,2),weight:0.5)}
        let geometry=MeshGeometry(vertices:.weighted(offsets:[0,6],influences:influences),indices:[],sourceUVs:[.zero],deformCount:12)
        let mesh=CompiledMesh(geometry:geometry,uvs:[.zero],deformSourceID:0)
        let matrices=(0..<6).map {CGAffineTransform(translationX:CGFloat($0),y:0)}
        var deform=Array(repeating:SIMD2<Float>.zero,count:6),output=[SIMD2<Float>.zero]
        deform[0]=SIMD2(0,4)
        try computeMeshPositions(mesh,boneMatrices:matrices,deform:deform,into:&output)
        XCTAssertEqual(output[0],SIMD2(10.5,8))
        let storage=output.withUnsafeBufferPointer {$0.baseAddress}
        for _ in 0..<100 {try computeMeshPositions(mesh,boneMatrices:matrices,deform:deform,into:&output)}
        XCTAssertEqual(output.withUnsafeBufferPointer {$0.baseAddress},storage)
    }
    func testOddSparseAndEmptyDeformProduceInputSpaceDeltas()throws {
        let odd=DeformKeyframeModel(time:0,offset:1,vertices:[4,5,6],curve:.linear)
        XCTAssertEqual(try meshDeformDeltas(odd,scalarCount:6,path:"test"),[SIMD2(0,4),SIMD2(5,6),.zero])
        let empty=DeformKeyframeModel(time:1,offset:0,vertices:[],curve:.linear)
        XCTAssertEqual(try meshDeformDeltas(empty,scalarCount:12,path:"test"),Array(repeating:SIMD2<Float>.zero,count:6))
    }
    func testInvalidMatrixNeverWritesNonfiniteOutput()throws {
        let geometry=MeshGeometry(vertices:.unweighted(boneIndex:0,positions:[SIMD2(1,2)]),indices:[],sourceUVs:[.zero],deformCount:2)
        let mesh=CompiledMesh(geometry:geometry,uvs:[.zero],deformSourceID:0)
        var output=[SIMD2<Float>(3,4)]
        assertMeshError(try computeMeshPositions(mesh,boneMatrices:[CGAffineTransform(a:.nan,b:0,c:0,d:1,tx:0,ty:0)],deform:[.zero],into:&output),.invalidGeometry)
        XCTAssertEqual(output,[SIMD2(3,4)])
    }
}
#endif
