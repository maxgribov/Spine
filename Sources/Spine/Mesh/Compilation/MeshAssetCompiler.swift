import SpriteKit

/// Validates every skin/animation before asking the texture provider for resources.
struct MeshAssetCompiler {
    private static let countLock=NSLock()
    private static var compileInvocations=0
    /// Internal resource-regression diagnostic; never affects asset or appearance state.
    static var compilationCount:Int {
        countLock.lock();defer {countLock.unlock()}
        return compileInvocations
    }
    private struct Draft {
        let id:Int,slot:Int
        let name:String,path:String
        let model:AttachmentModel
    }
    let model:SpineModel

    static func wrap(_ error:Error)->SpineRuntimeError {
        if let error=error as? SpineRuntimeError {return error}
        var keys:[CodingKey]=[]
        switch error {
        case DecodingError.keyNotFound(let key,let context):keys=context.codingPath+[key]
        case DecodingError.typeMismatch(_,let context),DecodingError.valueNotFound(_,let context),DecodingError.dataCorrupted(let context):keys=context.codingPath
        default:break
        }
        let path=SpineFeatureIssue.pointer(keys)
        let code:SpineRuntimeError.Code
        if path=="/skeleton/spine" {code = .unsupportedVersion}
        else if keys.first?.stringValue=="animations",keys.contains(where:{$0.stringValue=="curve"}) {code = .invalidTimeline}
        else {code = .invalidData}
        return SpineRuntimeError(code,path:path,message:"Invalid Spine data: \(error.localizedDescription)")
    }
    private func fail(_ code:SpineRuntimeError.Code,_ path:String,_ message:String)throws->Never {
        throw SpineRuntimeError(code,path:path,message:message)
    }
    private func name(_ value:String)->String {SpineRuntimeError.pointerComponent(value)}
    private func finite(_ values:[CGFloat],path:String)throws {
        guard values.allSatisfy({$0.isFinite && Float($0).isFinite}) else {try fail(.invalidGeometry,path,"Geometry contains a nonfinite or unrepresentable component.")}
    }

    func compile(textures:SpineMeshTextureProvider)throws->CompiledMeshSkeleton {
        Self.countLock.lock();Self.compileInvocations += 1;Self.countLock.unlock()
        guard model.skeleton.spine.range(of:"^4\\.1\\.[0-9]+$",options:.regularExpression) != nil else {
            try fail(.unsupportedVersion,"/skeleton/spine","Mesh assets require a declared Spine 4.1.x version.")
        }
        if let issue=model.featureIssues.first {
            try fail(issue.kind == .knownUnsupported ? .unsupportedFeature:.invalidData,issue.path,
                     issue.kind == .knownUnsupported ? "Unsupported Spine feature: \(issue.name).":"Obsolete mesh layout: \(issue.name).")
        }
        if !model.ik.isEmpty {try fail(.unsupportedFeature,"/ik","Spine IK constraints are not supported.")}
        if !model.transform.isEmpty {try fail(.unsupportedFeature,"/transform","Spine transform constraints are not supported.")}
        if !model.path.isEmpty {try fail(.unsupportedFeature,"/path","Spine path constraints are not supported.")}
        var boneNames:[String:Int]=[:]
        for (index,bone) in model.bones.enumerated() {
            let path="/bones/\(index)"
            guard boneNames[bone.name]==nil else {try fail(.invalidData,path+"/name","Duplicate bone name.")}
            if let parent=bone.parent, boneNames[parent]==nil {try fail(.invalidData,path+"/parent","A parent bone must precede its child.")}
            if bone.transform != .normal {try fail(.unsupportedFeature,path+"/transform","Only normal bone inheritance is supported.")}
            if bone.shear.dx != 0 {try fail(.unsupportedFeature,path+"/shearX","Bone shear is not supported.")}
            if bone.shear.dy != 0 {try fail(.unsupportedFeature,path+"/shearY","Bone shear is not supported.")}
            if !bone.inheritScale {try fail(.unsupportedFeature,path+"/inheritScale","Disabled scale inheritance is not supported.")}
            if !bone.inheritRotation {try fail(.unsupportedFeature,path+"/inheritRotation","Disabled rotation inheritance is not supported.")}
            try finite([bone.position.x,bone.position.y,bone.rotation,bone.scale.dx,bone.scale.dy],path:path)
            boneNames[bone.name]=index
        }
        var slotNames:[String:Int]=[:]
        for (index,slot) in model.slots.enumerated() {
            let path="/slots/\(index)"
            guard slotNames[slot.name]==nil else {try fail(.invalidData,path+"/name","Duplicate slot name.")}
            guard boneNames[slot.bone] != nil else {try fail(.invalidData,path+"/bone","Slot bone is missing.")}
            if slot.dark != nil {try fail(.unsupportedFeature,path+"/dark","Dark tint is not supported.")}
            if let blend=slot.blend,blend != .normal {try fail(.unsupportedFeature,path+"/blend","Only normal blending is supported.")}
            slotNames[slot.name]=index
        }
        var drafts:[Draft]=[],skins:[String:[MeshAttachmentKey:Int]]=[:]
        for (skinIndex,skin) in model.skins.enumerated() {
            guard skins[skin.name]==nil else {try fail(.invalidData,"/skins/\(skinIndex)/name","Duplicate skin name.")}
            var entries:[MeshAttachmentKey:Int]=[:]
            for slot in skin.slots {
                let path="/skins/\(skinIndex)/attachments/"+name(slot.name)
                guard let slotIndex=slotNames[slot.name] else {try fail(.invalidData,path,"Skin slot is missing.")}
                for attachment in slot.attachments.sorted(by:{$0.name<$1.name}) {
                    let id=drafts.count
                    entries[.init(slot:slotIndex,name:attachment.name)]=id
                    drafts.append(Draft(id:id,slot:slotIndex,name:attachment.name,path:path+"/"+name(attachment.name),model:attachment))
                }
            }
            skins[skin.name]=entries
        }
        var geometry:[Int:MeshGeometry]=[:],sources:[Int:Int]=[:],visiting=Set<Int>()
        func resolve(_ id:Int)throws->MeshGeometry {
            if let value=geometry[id] {return value}
            let draft=drafts[id]
            guard visiting.insert(id).inserted else {try fail(.linkedMeshCycle,draft.path+"/parent","Linked mesh cycle.")}
            defer {visiting.remove(id)}
            let result:MeshGeometry
            if let mesh=draft.model as? MeshAttachmentModel {
                result=try compileGeometry(mesh,bone:boneNames[model.slots[draft.slot].bone]!,path:draft.path)
                sources[id]=id
            } else if let linked=draft.model as? LinkedMeshAttachmentModel {
                if let error=linked.meshDecodeError {throw Self.wrap(error)}
                guard let parent=skins[linked.skin]?[.init(slot:draft.slot,name:linked.parent)],
                      drafts[parent].model is MeshAttachmentModel || drafts[parent].model is LinkedMeshAttachmentModel else {
                    try fail(.missingAttachment,draft.path+"/parent","Linked parent mesh is missing.")
                }
                result=try resolve(parent)
                // Spine 4.1 uses direct-parent timeline identity; geometry resolves through the chain.
                sources[id]=linked.timelines ? parent:id
            } else {try fail(.invalidGeometry,draft.path,"Attachment is not a mesh.")}
            geometry[id]=result;return result
        }
        for draft in drafts {
            switch draft.model {
            case is MeshAttachmentModel,is LinkedMeshAttachmentModel:_ = try resolve(draft.id)
            case let region as RegionAttachmentModel:
                try finite([region.position.x,region.position.y,region.rotation,region.scale.dx,region.scale.dy,region.size.width,region.size.height],path:draft.path)
                guard region.size.width>0,region.size.height>0 else {try fail(.invalidGeometry,draft.path,"Region dimensions must be positive.")}
            case let point as PointAttachmentModel:try finite([point.position.x,point.position.y,point.rotation],path:draft.path)
            case let box as BoundingBoxAttachmentModel:
                guard let count=Int(exactly:box.vertexCount),count<=Int.max/2,box.vertices.count==count*2 else {
                    try fail(.unsupportedFeature,draft.path+"/vertices","Weighted bounding boxes are not supported.")
                }
                try finite(box.vertices,path:draft.path+"/vertices")
            default:try fail(.unsupportedFeature,draft.path+"/type","This attachment type is not supported.")
            }
        }
        try validateAnimations(boneNames:boneNames,slotNames:slotNames,skins:skins,geometry:geometry)
        // All geometry/capabilities/timeline references are validated before resource resolution.
        var attachments:[CompiledAttachment]=[],deformCounts=Array(repeating:0,count:model.slots.count)
        for draft in drafts {
            var texture:SpineMeshTextureRegion?
            var color=SIMD4<Float>(repeating:1)
            if let textured=draft.model as? AttachmentTexturedModel {
                let path=textured.path ?? textured.fileName ?? textured.name
                do {texture=try textures.region(named:path)}
                catch let error as SpineRuntimeError where error.code == .missingTexture {throw SpineRuntimeError(.missingTexture,path:"/textures/"+name(path),message:error.message)}
                catch {throw SpineRuntimeError(.invalidTextureRegion,path:"/textures/"+name(path),message:"Texture provider failed: \(error.localizedDescription)")}
            }
            let content:CompiledAttachment.Content
            if let mesh=geometry[draft.id],let region=texture {
                let uv=mesh.sourceUVs.map {point->SIMD2<Float> in
                    let value=CGPoint(x:CGFloat(point.x),y:CGFloat(point.y)).applying(region.uvTransform)
                    return SIMD2(Float(value.x),Float(value.y))
                }
                guard uv.allSatisfy({$0.x.isFinite && $0.y.isFinite}) else {try fail(.invalidTextureRegion,"/textures/"+name(draft.name),"Mapped UVs are nonfinite.")}
                content = .mesh(CompiledMesh(geometry:mesh,uvs:uv,deformSourceID:sources[draft.id]!))
                deformCounts[draft.slot]=max(deformCounts[draft.slot],mesh.deformCount)
                if let ordinary=draft.model as? MeshAttachmentModel {color=SIMD4(ordinary.color.channels.map(Float.init))}
                if let linked=draft.model as? LinkedMeshAttachmentModel {color=SIMD4(linked.color.channels.map(Float.init))}
            } else if let region=draft.model as? RegionAttachmentModel {content = .region(region);color=SIMD4(region.color.channels.map(Float.init))}
            else if let point=draft.model as? PointAttachmentModel {content = .point(point)}
            else if let box=draft.model as? BoundingBoxAttachmentModel {content = .boundingBox(box)}
            else {try fail(.invalidData,draft.path,"Unable to compile attachment.")}
            attachments.append(.init(id:draft.id,slot:draft.slot,name:draft.name,path:draft.path,color:color,texture:texture,content:content,
                                     sourceKind:draft.model is LinkedMeshAttachmentModel ? .linkedMesh:nil))
        }
        let clips=try MeshClipCompiler(model:model,skinAttachments:skins,attachments:attachments).compile()
        let skinNames=model.skins.map(\.name)
        return CompiledMeshSkeleton(bones:model.bones,slots:model.slots,deformComponentCounts:deformCounts,clips:clips,
            skinNames:skinNames.isEmpty ? ["default"]:skinNames,attachments:attachments,skinAttachments:skins,sourceAnimations:model.animations)
    }

    private func compileGeometry(_ mesh:MeshAttachmentModel,bone:Int,path:String)throws->MeshGeometry {
        try finite(mesh.uvs,path:path+"/uvs");try finite(mesh.vertices,path:path+"/vertices")
        guard mesh.uvs.count.isMultiple(of:2) else {try fail(.invalidGeometry,path+"/uvs","UV coordinates must be pairs.")}
        let count=mesh.uvs.count/2
        guard mesh.triangles.count.isMultiple(of:3) else {try fail(.invalidGeometry,path+"/triangles","Triangle indices must be triples.")}
        for (i,index) in mesh.triangles.enumerated() where index<0 || index>=count {try fail(.invalidGeometry,path+"/triangles/\(i)","Triangle index is outside the vertex array.")}
        let uvs=stride(from:0,to:mesh.uvs.count,by:2).map {SIMD2(Float(mesh.uvs[$0]),1-Float(mesh.uvs[$0+1]))}
        if mesh.vertices.count==mesh.uvs.count {
            let positions=stride(from:0,to:mesh.vertices.count,by:2).map {SIMD2(Float(mesh.vertices[$0]),Float(mesh.vertices[$0+1]))}
            return MeshGeometry(vertices:.unweighted(boneIndex:bone,positions:positions),indices:mesh.triangles,sourceUVs:uvs,deformCount:positions.count*2)
        }
        var cursor=0,offsets=[0],influences:[MeshInfluence]=[]
        for _ in 0..<count {
            guard cursor<mesh.vertices.count,let n=Int(exactly:mesh.vertices[cursor]),n>=0,n<=(mesh.vertices.count-cursor-1)/4 else {
                try fail(.invalidGeometry,path+"/vertices/\(cursor)","Invalid weighted vertex influence count.")
            }
            cursor+=1
            for _ in 0..<n {
                guard let bone=Int(exactly:mesh.vertices[cursor]),model.bones.indices.contains(bone) else {try fail(.invalidGeometry,path+"/vertices/\(cursor)","Invalid influence bone index.")}
                let weight=Float(mesh.vertices[cursor+3])
                guard weight>=0 else {try fail(.invalidGeometry,path+"/vertices/\(cursor+3)","Negative influence weight.")}
                influences.append(.init(boneIndex:bone,position:SIMD2(Float(mesh.vertices[cursor+1]),Float(mesh.vertices[cursor+2])),weight:weight))
                cursor+=4
            }
            offsets.append(influences.count)
        }
        guard cursor==mesh.vertices.count else {try fail(.invalidGeometry,path+"/vertices/\(cursor)","Trailing influence components.")}
        return MeshGeometry(vertices:.weighted(offsets:offsets,influences:influences),indices:mesh.triangles,sourceUVs:uvs,deformCount:influences.count*2)
    }

    private func validateAnimations(boneNames:[String:Int],slotNames:[String:Int],skins:[String:[MeshAttachmentKey:Int]],geometry:[Int:MeshGeometry])throws {
        for animation in model.animations {
            let root="/animations/"+name(animation.name)
            if let error=animation.meshDecodeError {throw Self.wrap(error)}
            for group in animation.groups {
                switch group {
                case .bones(let bones):
                    for bone in bones {
                        let path=root+"/bones/"+name(bone.bone)
                        guard boneNames[bone.bone] != nil else {try fail(.invalidData,path,"Animation bone is missing.")}
                        if let error=bone.meshDecodeErrors.first {throw Self.wrap(error)}
                        for timeline in bone.numericTimelines {try validateNumeric(timeline,path:path+"/"+timeline.name)}
                    }
                case .slots(let slots):
                    for slot in slots {
                        let path=root+"/slots/"+name(slot.slot)
                        guard let slotIndex=slotNames[slot.slot] else {try fail(.invalidData,path,"Animation slot is missing.")}
                        if let error=slot.meshDecodeErrors.first {throw Self.wrap(error)}
                        for timeline in slot.numericTimelines {try validateNumeric(timeline,path:path+"/"+timeline.name)}
                        for timeline in slot.timelines {
                            if case .attachment(let frames)=timeline {
                                try validateTimes(frames.map(\.time),path:path+"/attachment")
                                for (index,frame) in frames.enumerated() {
                                    if let key=frame.name,!skins.values.contains(where:{$0[.init(slot:slotIndex,name:key)] != nil}) {
                                        try fail(.missingAttachment,path+"/attachment/\(index)/name","Attachment timeline references a missing attachment.")
                                    }
                                }
                            }
                        }
                    }
                case .events(let frames):
                    try validateTimes(frames.map(\.time),path:root+"/events",allowEqual:true)
                    for (index,frame) in frames.enumerated() {
                        guard model.events.contains(where:{$0.name==frame.event}) else {try fail(.invalidData,root+"/events/\(index)/name","Animation event is missing.")}
                        let values=[Double(frame.float ?? 0),Double(frame.volume ?? 1),Double(frame.balance ?? 0)]
                        guard values.allSatisfy(\.isFinite) else {try fail(.invalidTimeline,root+"/events/\(index)","Event contains a nonfinite value.")}
                    }
                case .drawOrder(let frames):
                    try validateTimes(frames.map(\.time),path:root+"/drawOrder")
                    for (index,frame) in frames.enumerated() {
                        var previous = -1,occupied=Set<Int>()
                        for (offsetIndex,offset) in (frame.offsets ?? []).enumerated() {
                            let path=root+"/drawOrder/\(index)/offsets/\(offsetIndex)"
                            guard let source=slotNames[offset.slot],source>previous else {try fail(.invalidTimeline,path+"/slot","Draw-order slots must exist and increase in setup order.")}
                            let (destination,overflow)=source.addingReportingOverflow(offset.offset)
                            guard !overflow,model.slots.indices.contains(destination),occupied.insert(destination).inserted else {try fail(.invalidTimeline,path+"/offset","Invalid draw-order destination.")}
                            previous=source
                        }
                    }
                default:break
                }
            }
            for timeline in animation.attachmentTimelines {
                guard let slot=slotNames[timeline.slot],let attachment=skins[timeline.skin]?[.init(slot:slot,name:timeline.attachment)],let mesh=geometry[attachment] else {
                    try fail(.missingAttachment,timeline.path,"Deform timeline mesh is missing.")
                }
                try validateTimes(timeline.deform.map(\.time),path:timeline.path)
                for (index,frame) in timeline.deform.enumerated() {
                    let path=timeline.path+"/\(index)"
                    _ = try meshDeformDeltas(frame,scalarCount:mesh.deformCount,path:path)
                    let end=index+1<timeline.deform.count ? timeline.deform[index+1].time:nil
                    try validateCurves([frame.curve],channels:1,time:frame.time,end:end,path:path+"/curve")
                }
            }
        }
    }

    private func validateTimes(_ times:[TimeInterval],path:String,allowEqual:Bool=false)throws {
        var previous:TimeInterval = -1
        for (index,time) in times.enumerated() {
            guard time.isFinite,Float(time).isFinite,time>=0,(allowEqual ? time>=previous:time>previous) else {
                try fail(.invalidTimeline,path+"/\(index)/time",allowEqual ? "Event times must be finite, nonnegative and nondecreasing.":"Timeline times must be finite, nonnegative and strictly increasing.")
            }
            previous=time
        }
    }
    private func validateNumeric(_ timeline:NumericTimelineModel,path:String)throws {
        try validateTimes(timeline.keys.map(\.time),path:path)
        for (index,key) in timeline.keys.enumerated() {
            guard key.values.allSatisfy(\.isFinite) else {try fail(.invalidTimeline,path+"/\(index)","Nonfinite timeline value.")}
            let end=index+1<timeline.keys.count ? timeline.keys[index+1].time:nil
            try validateCurves(key.curves,channels:key.values.count,time:key.time,end:end,path:path+"/\(index)/curve")
        }
    }
    private func validateCurves(_ curves:[CurveModel],channels:Int,time:TimeInterval,end:TimeInterval?,path:String)throws {
        var beziers:[BezierCurveModel]=[]
        for curve in curves {
            switch curve {
            case .bezier(let value):beziers.append(value)
            case .bezier2(let a,let b):beziers.append(contentsOf:[a,b])
            default:break
            }
        }
        guard beziers.isEmpty || beziers.count==channels else {try fail(.invalidTimeline,path,"Curve must provide controls for each animated channel.")}
        for curve in beziers {
            guard [curve.p0,curve.p1,curve.p2,curve.p3].allSatisfy(\.isFinite) else {try fail(.invalidTimeline,path,"Nonfinite curve controls.")}

        }
    }
}
