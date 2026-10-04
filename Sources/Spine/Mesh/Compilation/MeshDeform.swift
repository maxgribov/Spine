import Foundation

/// Converts scalar sparse offsets, including odd offsets, into input-space deltas.
func meshDeformDeltas(_ frame:DeformKeyframeModel,scalarCount:Int,path:String)throws->[SIMD2<Float>] {
    guard scalarCount>=0,scalarCount.isMultiple(of:2),frame.offset>=0,frame.offset<=scalarCount,
          frame.vertices.count<=scalarCount-frame.offset,frame.vertices.allSatisfy({$0.isFinite && Float($0).isFinite}) else {
        throw SpineRuntimeError(.invalidTimeline,path:path,message:"Invalid sparse deform range or component.")
    }
    var deltas=Array(repeating:SIMD2<Float>.zero,count:scalarCount/2)
    for (index,value) in frame.vertices.enumerated() {
        let scalar=frame.offset+index
        deltas[scalar/2][scalar%2]=Float(value)
    }
    return deltas
}
