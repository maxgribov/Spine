import Foundation

/// One mutable attachment/color/deform state per slot, owned only by its Skeleton.
final class MeshSlotState {
    var activeName:String?
    var requestedName:String?
    var attachmentID:Int?
    var deformSourceID:Int?
    let setupColor:SIMD4<Float>
    var color:SIMD4<Float>
    var deform:[Float]
    var physics=MeshSlotPhysicsState()
    init(color:SIMD4<Float>,deformCount:Int,setupColor:SIMD4<Float>?=nil) {
        self.setupColor=setupColor ?? color;self.color=color;deform=Array(repeating:0,count:deformCount)
    }
    func select(_ name:String?,id:Int?,source:Int?) {
        if deformSourceID != source {for i in deform.indices {deform[i]=0}}
        activeName=name;attachmentID=id;deformSourceID=source
    }
    func copied()->MeshSlotState {
        let result=MeshSlotState(color:color,deformCount:deform.count,setupColor:setupColor)
        result.activeName=activeName;result.requestedName=requestedName;result.attachmentID=attachmentID;result.deformSourceID=deformSourceID;result.deform=deform;result.physics=physics
        return result
    }
}
