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
        var pendingPositions:[SIMD2<Float>]
        var pendingGeometry:MeshTriangleNode.ValidatedGeometry?
        var deform:[SIMD2<Float>]
        let pixelSizeAttribute:SKAttributeValue?
        let nearestAttribute:SKAttributeValue?
        init(_ attachment:CompiledAttachment,node:SKNode,mesh:MeshTriangleNode?=nil,count:Int=0,deformCount:Int=0) {
            self.attachment=attachment;self.node=node;self.mesh=mesh
            positions=Array(repeating:.zero,count:count);pendingPositions=Array(repeating:.zero,count:count);deform=Array(repeating:.zero,count:deformCount/2)
            tintAttribute=(node as? SKSpriteNode)?.value(forAttributeNamed:"a_tint")
            pixelSizeAttribute=(node as? SKSpriteNode)?.value(forAttributeNamed:"a_pixelSize")
            nearestAttribute=(node as? SKSpriteNode)?.value(forAttributeNamed:"a_nearest")
        }
    }
    private let compiled:CompiledMeshSkeleton
    private let bones:[Bone]
    private let slots:[Slot]
    private let root:SKNode
    private var proxyBones:[SKNode?]
    private var records:[Record]=[]
    private var contracts:[(SKNode,SKNode,CGFloat)]=[]
    private var matrices:[CGAffineTransform]
    private var opacity:[CGFloat]
    private var hidden:[Bool]
    private var ranks:[Int]
    private var boneValid:[Bool]
    private var corrections:[Bool]
    private var lastDrawOrder:[Int]
    private var logicalPoints:[(id:Int,slot:Int,node:PointAttachment)]=[]
    private var physicsBodies:[Int:SKPhysicsBody]=[:]
    private(set) var activeAttachments:[String?]

    init(compiled:CompiledMeshSkeleton,resources:MeshRendererResources,bones:[Bone],slots:[Slot],root:SKNode,skin:String,
         resolvedLookup:[MeshAttachmentKey:Int]?=nil,stageCheck:((SKNode)throws->Void)?=nil)throws {
        self.compiled=compiled;self.bones=bones;self.slots=slots;self.root=root
        matrices=Array(repeating:.identity,count:bones.count);opacity=Array(repeating:1,count:bones.count);hidden=Array(repeating:false,count:bones.count)
        boneValid=Array(repeating:true,count:bones.count);corrections=Array(repeating:false,count:slots.count)
        activeAttachments=[]
        ranks=Array(slots.indices);lastDrawOrder=Array(slots.indices)
        let merged:[MeshAttachmentKey:Int]
        if let resolvedLookup=resolvedLookup {merged=resolvedLookup}
        else {
            var single=compiled.skinAttachments["default"] ?? [:]
            for (key,value) in compiled.skinAttachments[skin] ?? [:] {single[key]=value}
            merged=single
        }
        // Meshes already contain forward-transformed skeleton-local vertices.
        // Only real region sprites need a mirrored bone chain. Include every
        // possible region in the merged skin, not merely the active setup pose.
        var regionBones=Set<Int>()
        for id in merged.values {
            if case .region=compiled.attachments[id].content {
                var index:Int?=compiled.slotBones[compiled.attachments[id].slot]
                while let bone=index {regionBones.insert(bone);index=compiled.boneParents[bone]}
            }
        }
        proxyBones=bones.indices.map {regionBones.contains($0) ? SKNode():nil}
        for i in proxyBones.indices {
            guard let node=proxyBones[i] else {continue}
            node.name="_spine_render_bone_\(i)"
            let parent=compiled.boneParents[i].flatMap {proxyBones[$0]} ?? root
            parent.addChild(node)
        }
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
                proxyBones[compiled.slotBones[slot]]!.addChild(node)
                records.append(Record(attachment,node:node))
                try stageCheck?(node)
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

    func stageRegions(lookup:[MeshAttachmentKey:Int],slots changed:Set<Int>,resources:MeshRendererResources,
                      check:((SKNode)throws->Void)?)throws->MeshSetupRenderer {
        try MeshSetupRenderer(compiled:compiled,resources:resources,bones:bones,slots:slots,root:SKNode(),skin:"",
                              resolvedLookup:lookup.filter {changed.contains($0.key.slot)},stageCheck:check)
    }

    func commitRegions(_ staged:MeshSetupRenderer,slots changed:Set<Int>) {
        var removed=Set<ObjectIdentifier>()
        for record in records where changed.contains(record.attachment.slot) {
            removed.insert(ObjectIdentifier(record.node));record.node.removeFromParent()
        }
        records.removeAll {changed.contains($0.attachment.slot)}
        // Reuse existing proxy chains; only newly needed ancestors are transferred.
        for i in proxyBones.indices where proxyBones[i] == nil {
            guard let node=staged.proxyBones[i] else {continue}
            node.removeFromParent()
            let parent=compiled.boneParents[i].flatMap {proxyBones[$0]} ?? root
            parent.addChild(node);proxyBones[i]=node
            contracts.append((node,parent,node.zPosition))
        }
        for record in staged.records {
            record.node.removeFromParent()
            let parent=proxyBones[compiled.slotBones[record.attachment.slot]]!
            parent.addChild(record.node)
            records.append(record);contracts.append((record.node,parent,record.node.zPosition))
        }
        var needed=Set<Int>()
        for record in records where record.mesh == nil {
            var index:Int?=compiled.slotBones[record.attachment.slot]
            while let i=index {needed.insert(i);index=compiled.boneParents[i]}
        }
        for i in proxyBones.indices.reversed() where !needed.contains(i) {
            if let node=proxyBones[i] {removed.insert(ObjectIdentifier(node));node.removeFromParent();proxyBones[i]=nil}
        }
        contracts.removeAll {removed.contains(ObjectIdentifier($0.0))}
        for record in records {record.contractIndex=contracts.firstIndex {$0.0 === record.node}!}
        staged.records=[];staged.contracts=[];staged.proxyBones=Array(repeating:nil,count:proxyBones.count)
    }

    func removeLogicalAttachments(states:[MeshSlotState]) {
        for point in logicalPoints {point.node.removeFromParent()}
        for i in slots.indices {states[i].physics.transition(to:nil,vertices:[],slot:slots[i],chainValid:chainIsValid(i));slots[i].physicsBody=nil}
    }
    func installLogicalAttachments(states:[MeshSlotState]) {
        for point in logicalPoints {slots[point.slot].addChild(point.node)}
        updateLogicalActivity(states:states)
    }
    func updateLogicalActivity(states:[MeshSlotState]) {
        for slot in slots.indices {
            let body=states[slot].attachmentID.flatMap {physicsBodies[$0]}
            let actual=slots[slot].physicsBody
            if actual === body && states[slot].physics.expectedBody === body {continue}
            if states[slot].physics.expectedBody !== body {
                var vertices:[CGFloat]=[]
                if let id=states[slot].attachmentID,case .boundingBox(let model)=compiled.attachments[id].content {vertices=model.vertices}
                // Ancestry is needed only to authorize an actual body transition.
                // Every prepare still performs the independent full node validation.
                states[slot].physics.transition(to:body,vertices:vertices,slot:slots[slot],chainValid:chainIsValid(slot))
            }
            if actual !== body {slots[slot].physicsBody=body}
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

    private func chainIsValid(_ slot:Int)->Bool {
        guard slots[slot].parent === bones[compiled.slotBones[slot]] else {return false}
        var index:Int?=compiled.slotBones[slot]
        while let i=index {
            let node=bones[i],expected=compiled.boneParents[i].map {bones[$0] as SKNode} ?? root.parent
            guard node.parent === expected,node.zPosition==0,[node.position.x,node.position.y,node.zRotation,node.xScale,node.yScale,node.alpha].allSatisfy(\.isFinite) else {return false}
            index=compiled.boneParents[i]
        }
        return true
    }
    private func mutation(_ name:String)->SpineRuntimeError {
        SpineRuntimeError(.mutatedNodeContract,path:"/runtime/nodes/"+SpineRuntimeError.pointerComponent(name),message:"Managed node hierarchy, slot transform or internal depth was changed.")
    }
    /// Scratch matrices and plans only until all slots have been examined.
    /// An invalid sibling never prevents an independently valid physics cleanup.
    func reconcile(owner:Skeleton,states:[MeshSlotState])->SpineRuntimeError? {
        var nodeError:SpineRuntimeError?,contextError:SpineRuntimeError?
        let (external,space,detached)=MeshSlotPhysicsState.world(from:owner)
        for i in bones.indices {
            let bone=bones[i],parent=compiled.boneParents[i]
            let expected=parent.map {bones[$0] as SKNode} ?? owner
            let local=MeshSlotPhysicsState.local(bone)
            boneValid[i]=bone.parent === expected && bone.zPosition==0 && (parent.map {boneValid[$0]} ?? true)
            if !boneValid[i],nodeError==nil {nodeError=mutation(compiled.bones[i].name)}
            matrices[i]=parent.map {MeshSlotPhysicsState.concatenate(matrices[$0],local)} ?? local
            let m=matrices[i]
            if ![m.a,m.b,m.c,m.d,m.tx,m.ty,bone.alpha].allSatisfy({$0.isFinite && Float($0).isFinite}) {
                boneValid[i]=false
                if nodeError==nil {nodeError=SpineRuntimeError(.invalidGeometry,path:"/runtime/nodes/"+SpineRuntimeError.pointerComponent(compiled.bones[i].name),message:"Bone transform or opacity is nonfinite.")}
            }
            opacity[i]=(parent.map {opacity[$0]} ?? 1)*bone.alpha;hidden[i]=(parent.map {hidden[$0]} ?? false) || bone.isHidden
        }
        for i in slots.indices {
            let slot=slots[i],bone=compiled.slotBones[i]
            corrections[i]=false
            let valid=boneValid[bone] && slot.parent === bones[bone] && slot.xScale==1 && slot.yScale==1 && slot.zPosition==0
            if !states[i].physics.hasProvenance {
                // Region/mesh-only slots never have a physics authorization.
                // Keep their exact identity check ahead of world/context errors.
                if !valid || slot.position != .zero || slot.zRotation != 0 {
                    if nodeError==nil {nodeError=mutation(compiled.slots[i].name)}
                } else {
                    let world=MeshSlotPhysicsState.concatenate(external,matrices[bone])
                    if !world.a.isFinite || !world.b.isFinite || !world.c.isFinite || !world.d.isFinite || !Float(world.tx).isFinite || !Float(world.ty).isFinite {
                        if contextError==nil {contextError=MeshSlotPhysicsState.Frame.contextError()}
                    }
                }
                continue
            }
            do {
                let permitted=try states[i].physics.plan(slot:slot,parent:bones[bone],world:MeshSlotPhysicsState.concatenate(external,matrices[bone]),space:space,detached:detached,chainValid:valid)
                if valid && permitted {corrections[i]=slot.position != .zero || slot.zRotation != 0}
                else if nodeError==nil {nodeError=mutation(compiled.slots[i].name)}
            } catch let error as SpineRuntimeError {if contextError==nil {contextError=error}}
            catch {if contextError==nil {contextError=MeshSlotPhysicsState.Frame.contextError()}}
        }
        if root.parent !== owner || root.position != .zero || root.zRotation != 0 || root.xScale != 1 || root.yScale != 1 || root.zPosition != 0 || root.alpha != 1 {
            if nodeError==nil {nodeError=mutation("renderer")}
        }
        for (node,parent,z) in contracts where node.parent !== parent || node.zPosition != z {if nodeError==nil {nodeError=mutation(node.name ?? "renderer")}}
        for i in slots.indices where corrections[i] {
            if slots[i].zRotation != 0 {slots[i].zRotation=0}
            if slots[i].position != .zero {slots[i].position = .zero}
        }
        return nodeError ?? contextError
    }

    func prepare(owner:Skeleton,context:SpineMeshFrameContext,states:[MeshSlotState],drawOrder:[Int])throws {
        defer {for record in records {record.pendingGeometry=nil}}
        for record in records {record.pendingGeometry=nil}
        for record in records where states[record.attachment.slot].attachmentID==record.attachment.id {
            if let node=record.mesh,case .mesh(let mesh)=record.attachment.content {
                let slot=record.attachment.slot
                for vertex in record.deform.indices {record.deform[vertex]=SIMD2(states[slot].deform[vertex*2],states[slot].deform[vertex*2+1])}
                try computeMeshPositions(mesh,boneMatrices:matrices,deform:record.deform,into:&record.pendingPositions)
                record.pendingGeometry=try node.validateForRendering(localToPixels:context.skeletonToPixels,positions:record.pendingPositions)
            }
        }
        for (rank,slot) in drawOrder.enumerated() {ranks[slot]=rank}
        for slot in slots.indices {activeAttachments[slot]=states[slot].activeName}
        lastDrawOrder=drawOrder
        // Validate every logical transform before changing any mesh buffer or proxy pose.
        for i in bones.indices {
            guard let node=proxyBones[i] else {continue}
            let bone=bones[i]
            let position=bone.position,rotation=bone.zRotation,xScale=bone.xScale,yScale=bone.yScale,alpha=bone.alpha,isHidden=bone.isHidden
            if node.position != position {node.position=position}
            if node.zRotation != rotation {node.zRotation=rotation}
            if node.xScale != xScale {node.xScale=xScale}
            if node.yScale != yScale {node.yScale=yScale}
            if node.alpha != alpha {node.alpha=alpha}
            if node.isHidden != isHidden {node.isHidden=isHidden}
        }
        for record in records {
            let slot=record.attachment.slot,bone=compiled.slotBones[slot]
            let active=states[slot].attachmentID==record.attachment.id
            let depth=CGFloat(ranks[slot])/CGFloat(max(1,slots.count))
            let existingDepth=record.node.zPosition
            if existingDepth != CGFloat(Float(depth)) {record.node.zPosition=depth;contracts[record.contractIndex].2=record.node.zPosition}
            else {contracts[record.contractIndex].2=existingDepth}
            let shouldHide = !active || slots[slot].isHidden || hidden[bone]
            if record.node.isHidden != shouldHide {record.node.isHidden=shouldHide}
            guard active else {continue}
            let tint=states[slot].color*record.attachment.color
            if let node=record.mesh {
                swap(&record.positions,&record.pendingPositions)
                node.setTint(tint)
                node.commit(record.pendingGeometry!)
                record.pendingGeometry=nil
                let alpha=opacity[bone]*slots[slot].alpha
                if node.alpha != CGFloat(Float(alpha)) {node.alpha=alpha}
            } else {
                let alpha=slots[slot].alpha
                if record.node.alpha != alpha {record.node.alpha=alpha}
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
