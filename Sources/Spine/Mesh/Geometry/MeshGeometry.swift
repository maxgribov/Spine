import CoreGraphics

struct MeshInfluence {
    let boneIndex:Int
    let position:SIMD2<Float>
    let weight:Float
}
enum MeshVertices {
    case unweighted(boneIndex:Int,positions:[SIMD2<Float>])
    case weighted(offsets:[Int],influences:[MeshInfluence])
}

/// Linked attachments share this immutable geometry, with their own page UVs and tint.
final class MeshGeometry {
    let vertices:MeshVertices
    let indices:[Int]
    let sourceUVs:[SIMD2<Float>]
    let deformCount:Int
    var vertexCount:Int {sourceUVs.count}
    init(vertices:MeshVertices,indices:[Int],sourceUVs:[SIMD2<Float>],deformCount:Int) {
        self.vertices=vertices;self.indices=indices;self.sourceUVs=sourceUVs;self.deformCount=deformCount
    }
}
struct CompiledMesh {
    let geometry:MeshGeometry
    let uvs:[SIMD2<Float>]
    let deformSourceID:Int
    var vertices:MeshVertices {geometry.vertices}
    var indices:[Int] {geometry.indices}
}

/// No SKNode, SKAction, shader or texture access. Output storage is supplied by the owner.
func computeMeshPositions(_ mesh:CompiledMesh,boneMatrices:[CGAffineTransform],deform:[SIMD2<Float>],into output:inout [SIMD2<Float>]) throws {
    guard output.count==mesh.geometry.vertexCount,deform.count==mesh.geometry.deformCount/2 else {
        throw SpineRuntimeError(.invalidGeometry,path:"/runtime/geometry",message:"Geometry output/deform buffer sizes do not match the compiled mesh.")
    }
    func transform(_ position:SIMD2<Float>,_ bone:Int)throws->SIMD2<Float> {
        guard boneMatrices.indices.contains(bone),position.x.isFinite,position.y.isFinite else {
            throw SpineRuntimeError(.invalidGeometry,path:"/runtime/geometry",message:"Invalid input bone or deform component.")
        }
        let m=boneMatrices[bone]
        let result=SIMD2(Float(m.a)*position.x+Float(m.c)*position.y+Float(m.tx),Float(m.b)*position.x+Float(m.d)*position.y+Float(m.ty))
        guard result.x.isFinite,result.y.isFinite else {throw SpineRuntimeError(.invalidGeometry,path:"/runtime/geometry",message:"Nonfinite transformed mesh vertex.")}
        return result
    }
    switch mesh.vertices {
    case let .unweighted(bone,positions):
        for i in positions.indices {output[i]=try transform(positions[i]+deform[i],bone)}
    case let .weighted(offsets,influences):
        for i in output.indices {
            var position=SIMD2<Float>.zero
            for influenceIndex in offsets[i]..<offsets[i+1] {
                let influence=influences[influenceIndex]
                position += try transform(influence.position+deform[influenceIndex],influence.boneIndex)*influence.weight
            }
            guard position.x.isFinite,position.y.isFinite else {throw SpineRuntimeError(.invalidGeometry,path:"/runtime/geometry",message:"Nonfinite weighted mesh vertex.")}
            output[i]=position
        }
    }
}
