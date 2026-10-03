import SpriteKit

struct MeshSnapshot {
    let activeAttachments:[String?]
    let drawOrder:[Int]
    let vertices:[[SIMD2<Float>]]
    let uvs:[[SIMD2<Float>]]
}

/// Reads logical nodes once per prepare and owns all dynamic renderer buffers.
final class MeshSetupRenderer {
    private final class Record {
        let attachment:CompiledAttachment
        let node:SKNode
        let mesh:MeshTriangleNode?
        var contractIndex=0
        let tintAttribute:SKAttributeValue?
        var positions:[SIMD2<Float>]
        var deform:[SIMD2<Float>]
        let pixelSizeAttribute:SKAttributeValue?
        let nearestAttribute:SKAttributeValue?
        init(_ attachment:CompiledAttachment,node:SKNode,mesh:MeshTriangleNode?=nil,count:Int=0,deformCount:Int=0) {
            self.attachment=attachment;self.node=node;self.mesh=mesh
            positions=Array(repeating:.zero,count:count);deform=Array(repeating:.zero,count:deformCount/2)
            tintAttribute=(node as? SKSpriteNode)?.value(forAttributeNamed:"a_tint")
            pixelSizeAttribute=(node as? SKSpriteNode)?.value(forAttributeNamed:"a_pixelSize")
            nearestAttribute=(node as? SKSpriteNode)?.value(forAttributeNamed:"a_nearest")
        }
    }
    private let compiled:CompiledMeshSkeleton
    private let bones:[Bone]
    private let slots:[Slot]
    private let root:SKNode
    private let proxyBones:[SKNode]
    private var records:[Record]=[]
    private var contracts:[(SKNode,SKNode,CGFloat)]=[]
    private var matrices:[CGAffineTransform]
    private var opacity:[CGFloat]
    private var hidden:[Bool]
    private var ranks:[Int]
    private var lastDrawOrder:[Int]
    private var logicalPoints:[(id:Int,slot:Int,node:PointAttachment)]=[]
    private var physicsBodies:[Int:SKPhysicsBody]=[:]
    private(set) var activeAttachments:[String?]

    init(compiled:CompiledMeshSkeleton,resources:MeshRendererResources,bones:[Bone],slots:[Slot],root:SKNode,skin:String)throws {
        self.compiled=compiled;self.bones=bones;self.slots=slots;self.root=root
        matrices=Array(repeating:.identity,count:bones.count);opacity=Array(repeating:1,count:bones.count);hidden=Array(repeating:false,count:bones.count)
        activeAttachments=[]
        ranks=Array(slots.indices);lastDrawOrder=Array(slots.indices)
        proxyBones=bones.map {_ in SKNode()}
        for i in proxyBones.indices {
            proxyBones[i].name="_spine_render_bone_\(i)"
            (compiled.boneParents[i].map {proxyBones[$0]} ?? root).addChild(proxyBones[i])
        }
        var merged=compiled.skinAttachments["default"] ?? [:]
        for (key,value) in compiled.skinAttachments[skin] ?? [:] {merged[key]=value}
        activeAttachments=compiled.slots.enumerated().map {index,slot in
            slot.attachment.flatMap {merged[.init(slot:index,name:$0)] != nil ? $0:nil}
        }
        for id in merged.values.sorted() {
            let attachment=compiled.attachments[id],slot=attachment.slot
            let depth=CGFloat(slot)/CGFloat(max(1,slots.count))
            switch attachment.content {
            case .mesh(let mesh):
                let node=try MeshTriangleNode(material:resources.material(for:attachment.texture!.texture),positions:Array(repeating:.zero,count:mesh.geometry.vertexCount),uvs:mesh.uvs,indices:mesh.indices)
                node.name="_spine_mesh_\(slot)_\(attachment.name)";node.zPosition=depth
                node.setTriangleDepthSpan(0.9/CGFloat(max(1,slots.count)))
                let slotColor=compiled.slots[slot].color
                node.setTint(attachment.color*SIMD4(slotColor.channels.map(Float.init)))
                root.addChild(node)
                records.append(Record(attachment,node:node,mesh:node,count:mesh.geometry.vertexCount,deformCount:mesh.geometry.deformCount))
            case .region(let model):
                let region=attachment.texture!,trim=region.trimRect,original=region.originalSize
                let node=SKSpriteNode(texture:region.texture)
                node.name=RegionAttachment.generateName(attachment.name)
                node.size=CGSize(width:model.size.width*trim.width/original.width,height:model.size.height*trim.height/original.height)
                node.anchorPoint=CGPoint(x:(original.width/2-trim.minX)/trim.width,y:(original.height/2-trim.minY)/trim.height)
                node.position=model.position;node.zRotation=model.rotation*degreeToRadiansFactor
                node.xScale=model.scale.dx;node.yScale=model.scale.dy;node.zPosition=depth;node.shader=resources.regionShader
                let t=region.uvTransform,sx=trim.width/original.width,sy=trim.height/original.height,bx=trim.minX/original.width,by=trim.minY/original.height
                node.setValue(SKAttributeValue(vectorFloat3:SIMD3(Float(t.a*sx),Float(t.c*sy),Float(t.a*bx+t.c*by+t.tx))),forAttribute:"a_uvX")
                node.setValue(SKAttributeValue(vectorFloat3:SIMD3(Float(t.b*sx),Float(t.d*sy),Float(t.b*bx+t.d*by+t.ty))),forAttribute:"a_uvY")
                node.setValue(SKAttributeValue(vectorFloat4:attachment.color*SIMD4(compiled.slots[slot].color.channels.map(Float.init))),forAttribute:"a_tint")
                node.setValue(SKAttributeValue(vectorFloat2:SIMD2(Float(region.pixelSize.width),Float(region.pixelSize.height))),forAttribute:"a_pixelSize")
                node.setValue(SKAttributeValue(float:region.texture.filteringMode == .nearest ? 1:0),forAttribute:"a_nearest")
                proxyBones[compiled.slotBones[slot]].addChild(node)
                records.append(Record(attachment,node:node))
            case .point(let model):
                let node=PointAttachment(model);node.name=PointAttachment.generateName(model.name);node.isHidden=true
                logicalPoints.append((attachment.id,slot,node))
            case .boundingBox(let model):
                if let body=BoundingBoxAttachment(model).physicsBody {physicsBodies[attachment.id]=body}
            }
        }
        func remember(_ node:SKNode) {
            for child in node.children {contracts.append((child,node,child.zPosition));remember(child)}
        }
        remember(root)
        for record in records {record.contractIndex=contracts.firstIndex {$0.0 === record.node}!}
        for record in records {record.node.isHidden=activeAttachments[record.attachment.slot] != record.attachment.name}
    }

    func removeLogicalAttachments() {
        for point in logicalPoints {point.node.removeFromParent()}
        for slot in slots {slot.physicsBody=nil}
    }
    func installLogicalAttachments(states:[MeshSlotState]) {
        for point in logicalPoints {slots[point.slot].addChild(point.node)}
        updateLogicalActivity(states:states)
    }
    func updateLogicalActivity(states:[MeshSlotState]) {
        for slot in slots.indices {
            let body=states[slot].attachmentID.flatMap {physicsBodies[$0]}
            if let body=body,!body.isDynamic {states[slot].hadStaticPhysicsBody=true}
            if slots[slot].physicsBody !== body {slots[slot].physicsBody=body}
        }
    }
    func activePoints(states:[MeshSlotState])->[SKNode] {
        logicalPoints.filter {states[$0.slot].attachmentID==$0.id}.map(\.node)
    }
    func meshNode(named:String,slot:String)->SKNode? {
        guard let index=compiled.slots.firstIndex(where:{$0.name==slot}) else {return nil}
        return records.first {$0.attachment.slot==index && $0.attachment.name==named && $0.mesh != nil}?.node
    }
    func regionNode(named:String,slot:Int?=nil)->SKSpriteNode? {
        records.first {record in record.attachment.name==named && record.mesh==nil && (slot.map {$0==record.attachment.slot} ?? true)}?.node as? SKSpriteNode
    }
    var snapshot:MeshSnapshot {
        var positions=Array(repeating:[SIMD2<Float>](),count:slots.count),uvs=positions
        for record in records where activeAttachments[record.attachment.slot]==record.attachment.name {
            if case .mesh(let mesh)=record.attachment.content {positions[record.attachment.slot]=record.positions;uvs[record.attachment.slot]=mesh.uvs}
        }
        return MeshSnapshot(activeAttachments:activeAttachments,drawOrder:lastDrawOrder,vertices:positions,uvs:uvs)
    }

    func prepare(owner:Skeleton,context:SpineMeshFrameContext,states:[MeshSlotState],drawOrder:[Int])throws {
        func mutation(_ name:String)throws->Never {throw SpineRuntimeError(.mutatedNodeContract,path:"/runtime/nodes/"+SpineRuntimeError.pointerComponent(name),message:"Managed node hierarchy, slot transform or internal depth was changed.")}
        guard root.parent === owner,root.position == .zero,root.zRotation==0,root.xScale==1,root.yScale==1,root.zPosition==0,root.alpha==1 else {try mutation("renderer")}
        for (node,parent,z) in contracts where node.parent !== parent || node.zPosition != z {try mutation(node.name ?? "renderer")}
        for i in bones.indices {
            let bone=bones[i],expected=compiled.boneParents[i].map {bones[$0] as SKNode} ?? owner
            guard bone.parent === expected,bone.zPosition==0 else {try mutation(compiled.bones[i].name)}
            let values=[bone.position.x,bone.position.y,bone.zRotation,bone.xScale,bone.yScale,bone.alpha]
            guard values.allSatisfy(\.isFinite) else {throw SpineRuntimeError(.invalidGeometry,path:"/runtime/nodes/"+SpineRuntimeError.pointerComponent(compiled.bones[i].name),message:"Bone transform or opacity is nonfinite.")}
            let cosine=cos(bone.zRotation),sine=sin(bone.zRotation)
            let local=CGAffineTransform(a:cosine*bone.xScale,b:sine*bone.xScale,c:-sine*bone.yScale,d:cosine*bone.yScale,tx:bone.position.x,ty:bone.position.y)
            if let parent=compiled.boneParents[i] {
                let p=matrices[parent]
                matrices[i]=CGAffineTransform(a:p.a*local.a+p.c*local.b,b:p.b*local.a+p.d*local.b,c:p.a*local.c+p.c*local.d,d:p.b*local.c+p.d*local.d,
                    tx:p.a*local.tx+p.c*local.ty+p.tx,ty:p.b*local.tx+p.d*local.ty+p.ty)
                opacity[i]=opacity[parent]*bone.alpha;hidden[i]=hidden[parent] || bone.isHidden
            } else {matrices[i]=local;opacity[i]=bone.alpha;hidden[i]=bone.isHidden}
            let m=matrices[i]
            guard [m.a,m.b,m.c,m.d,m.tx,m.ty].allSatisfy({$0.isFinite && Float($0).isFinite}) else {throw SpineRuntimeError(.invalidGeometry,path:"/runtime/nodes/"+SpineRuntimeError.pointerComponent(compiled.bones[i].name),message:"Bone matrix is nonfinite.")}
        }
        for i in slots.indices {
            let slot=slots[i]
            // SpriteKit's static-body solver can round a mathematically identity local
            // rotation to a few Float ULPs when the parent bone rotates. Do not write
            // the physical node back; allow only that narrow owned-body residue.
            let ownedStatic=slot.physicsBody.map {body in !body.isDynamic && physicsBodies.values.contains {$0 === body}} ?? states[i].hadStaticPhysicsBody
            let rotationTolerance:CGFloat=ownedStatic ? CGFloat(Float.ulpOfOne)*8:0
            guard slot.parent === bones[compiled.slotBones[i]],slot.position == .zero,abs(slot.zRotation)<=rotationTolerance,slot.xScale==1,slot.yScale==1,slot.zPosition==0 else {try mutation(compiled.slots[i].name)}
        }
        for (rank,slot) in drawOrder.enumerated() {ranks[slot]=rank}
        for slot in slots.indices {activeAttachments[slot]=states[slot].activeName}
        lastDrawOrder=drawOrder
        // Validate every logical transform before changing any mesh buffer or proxy pose.
        for i in bones.indices {
            let node=proxyBones[i],bone=bones[i]
            node.position=bone.position;node.zRotation=bone.zRotation;node.xScale=bone.xScale;node.yScale=bone.yScale;node.alpha=bone.alpha;node.isHidden=bone.isHidden
        }
        for record in records {
            let slot=record.attachment.slot,bone=compiled.slotBones[slot]
            let active=states[slot].attachmentID==record.attachment.id
            let depth=CGFloat(ranks[slot])/CGFloat(max(1,slots.count))
            record.node.zPosition=depth;contracts[record.contractIndex].2=record.node.zPosition
            record.node.isHidden = !active || slots[slot].isHidden || hidden[bone]
            guard active else {continue}
            let tint=states[slot].color*record.attachment.color
            if let node=record.mesh,case .mesh(let mesh)=record.attachment.content {
                for vertex in record.deform.indices {record.deform[vertex]=SIMD2(states[slot].deform[vertex*2],states[slot].deform[vertex*2+1])}
                node.setTint(tint)
                try computeMeshPositions(mesh,boneMatrices:matrices,deform:record.deform,into:&record.positions)
                try node.prepareForRendering(localToPixels:context.skeletonToPixels,positions:record.positions)
                node.alpha=opacity[bone]*slots[slot].alpha
            } else {
                record.node.alpha=slots[slot].alpha
                if let value=record.tintAttribute {value.vectorFloat4Value=tint;(record.node as? SKSpriteNode)?.setValue(value,forAttribute:"a_tint")}
                if let sprite=record.node as? SKSpriteNode,let texture=sprite.texture,
                   let pixels=record.pixelSizeAttribute,let nearest=record.nearestAttribute {
                    let size=texture.size()
                    pixels.vectorFloat2Value=SIMD2(Float(size.width),Float(size.height))
                    nearest.floatValue=texture.filteringMode == .nearest ? 1:0
                    sprite.setValue(pixels,forAttribute:"a_pixelSize");sprite.setValue(nearest,forAttribute:"a_nearest")
                }
            }
        }
    }
}
