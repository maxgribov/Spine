import Foundation

/// Compiles validated shared-model timelines once. No JSON or curve compilation in frame callbacks.
struct MeshClipCompiler {
    let model:SpineModel
    let skinAttachments:[String:[MeshAttachmentKey:Int]]
    let attachments:[CompiledAttachment]

    func compile()throws->[MeshClip] {
        try model.animations.sorted {$0.name<$1.name}.map { animation in
            var channels:[MeshClip.Channel]=[],attachmentTimelines:[MeshClip.AttachmentTimeline]=[]
            var drawOrders:[MeshClip.DrawOrderKey]=[],deforms:[MeshClip.DeformTimeline]=[],events:[MeshClip.Event]=[]
            for group in animation.groups {
                switch group {
                case .bones(let bones):
                    for bone in bones {
                        let index=model.bones.firstIndex {$0.name==bone.bone}!
                        for timeline in bone.numericTimelines {
                            let targets:[MeshClip.Target]
                            switch timeline.name {
                            case "rotate":targets=[.boneRotation(index)]
                            case "translate":targets=[.boneX(index),.boneY(index)]
                            case "translatex":targets=[.boneX(index)]
                            case "translatey":targets=[.boneY(index)]
                            case "scale":targets=[.boneScaleX(index),.boneScaleY(index)]
                            case "scalex":targets=[.boneScaleX(index)]
                            case "scaley":targets=[.boneScaleY(index)]
                            default:continue
                            }
                            for (component,target) in targets.enumerated() {channels.append(.init(target:target,timeline:try scalar(timeline,component:component)))}
                        }
                    }
                case .slots(let slots):
                    for slot in slots {
                        let index=model.slots.firstIndex {$0.name==slot.slot}!
                        for timeline in slot.numericTimelines {
                            let components=timeline.name=="alpha" ? [3]:(timeline.name=="rgb" ? [0,1,2]:[0,1,2,3])
                            for (column,component) in components.enumerated() {channels.append(.init(target:.slotColor(slot:index,component:component),timeline:try scalar(timeline,component:column)))}
                        }
                        for timeline in slot.timelines {
                            if case .attachment(let keys)=timeline {
                                attachmentTimelines.append(.init(slot:index,keys:keys.map {.init(time:Float($0.time),name:$0.name)}))
                            }
                        }
                    }
                case .drawOrder(let keys):
                    for key in keys {
                        var order=Array(repeating:-1,count:model.slots.count),unchanged:[Int]=[],original=0
                        for offset in key.offsets ?? [] {
                            let slot=model.slots.firstIndex {$0.name==offset.slot}!
                            while original<slot {unchanged.append(original);original+=1}
                            order[original+offset.offset]=original;original+=1
                        }
                        while original<order.count {unchanged.append(original);original+=1}
                        for index in order.indices.reversed() where order[index]<0 {order[index]=unchanged.removeLast()}
                        drawOrders.append(.init(time:Float(key.time),order:order))
                    }
                case .events(let keys):
                    events=keys.map { key in
                        let setup=model.events.first {$0.name==key.event}!
                        let event=EventModel(name:key.event,int:key.int ?? setup.int,float:Float(key.float ?? CGFloat(setup.float)),
                            string:key.string ?? setup.string,audio:setup.audio,volume:key.volume ?? setup.volume,balance:key.balance ?? setup.balance)
                        return .init(time:Double(Float(key.time)),value:event)
                    }
                default:break
                }
            }
            for timeline in animation.attachmentTimelines {
                let slot=model.slots.firstIndex {$0.name==timeline.slot}!
                let id=skinAttachments[timeline.skin]![.init(slot:slot,name:timeline.attachment)]!
                guard case .mesh(let mesh)=attachments[id].content else {continue}
                let keys=try timeline.deform.enumerated().map {index,key->MeshClip.DeformTimeline.Key in
                    let progress:MeshScalarTimeline?
                    if index+1<timeline.deform.count {
                        progress=try MeshScalarTimeline(keys:[.init(Float(key.time),0,curve:curve([key.curve],component:0)),.init(Float(timeline.deform[index+1].time),1)],path:timeline.path)
                    } else {progress=nil}
                    return .init(time:Float(key.time),deltas:try meshDeformDeltas(key,scalarCount:mesh.geometry.deformCount,path:timeline.path),progress:progress)
                }
                deforms.append(.init(slot:slot,attachmentID:id,keys:keys))
            }
            return try MeshClip(name:animation.name,channels:channels,events:events,attachments:attachmentTimelines,drawOrders:drawOrders,deforms:deforms)
        }
    }
    private func scalar(_ timeline:NumericTimelineModel,component:Int)throws->MeshScalarTimeline {
        try MeshScalarTimeline(keys:timeline.keys.map {.init(Float($0.time),$0.values[component],curve:curve($0.curves,component:component))})
    }
    private func curve(_ curves:[CurveModel],component:Int)->MeshScalarTimeline.Curve {
        let value=curves.count==1 ? curves[0]:curves[component]
        let bezier:BezierCurveModel
        switch value {
        case .linear:return .linear
        case .stepped:return .stepped
        case .bezier(let b):bezier=b
        case .bezier2(let a,let b):bezier=component==0 ? a:b
        }
        return .bezier(SIMD2(bezier.p0,bezier.p1),SIMD2(bezier.p2,bezier.p3))
    }
}
