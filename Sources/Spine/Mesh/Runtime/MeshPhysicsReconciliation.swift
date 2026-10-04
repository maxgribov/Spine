import SpriteKit

/// Per-owner slot provenance. Neither frames nor removal tokens are shared assets.
final class MeshSlotPhysicsState {
    final class Frame {
        weak var slot:SKNode?,parent:SKNode?,space:SKNode?,body:SKPhysicsBody?
        let detached:Bool,world:CGAffineTransform,tolerance:SIMD2<Double>,safe:Bool
        let vertices:[CGFloat]
        init(slot:SKNode,parent:SKNode,space:SKNode,detached:Bool,body:SKPhysicsBody?,world:CGAffineTransform,vertices:[CGFloat])throws {
            self.slot=slot;self.parent=parent;self.space=space;self.detached=detached;self.body=body;self.world=world;self.vertices=vertices
            guard [world.a,world.b,world.c,world.d,world.tx,world.ty].allSatisfy(\.isFinite) else {throw Self.contextError()}
            var sx=max(1,abs(world.tx)),sy=max(1,abs(world.ty))
            for i in stride(from:0,to:vertices.count,by:2) {
                let x=world.a*vertices[i]+world.c*vertices[i+1]+world.tx,y=world.b*vertices[i]+world.d*vertices[i+1]+world.ty
                guard x.isFinite,y.isFinite else {throw Self.contextError()}
                sx=max(sx,abs(x));sy=max(sy,abs(y))
            }
            guard Float(sx).isFinite,Float(sy).isFinite else {throw Self.contextError()}
            tolerance=SIMD2(Double(Float(sx).ulp)*32,Double(Float(sy).ulp)*32)
            let scale=max(abs(world.a),abs(world.b),abs(world.c),abs(world.d))
            if scale==0 {safe=false;return}
            let a=world.a/scale,b=world.b/scale,c=world.c/scale,d=world.d/scale
            let sum=a*a+b*b+c*c+d*d,det=abs(a*d-b*c)
            let largest=sqrt((sum+sqrt(max(0,sum*sum-4*det*det)))/2)
            let smallest=largest>0 ? det/largest:0
            safe=smallest*scale>1e-6 && smallest/largest>1e-6
        }
        static func contextError()->SpineRuntimeError {SpineRuntimeError(.invalidRenderContext,path:"/runtime/frame",message:"Physics-world transform or coordinates are not representable.")}
        func sameSpace(_ other:Frame)->Bool {space != nil && space === other.space && detached==other.detached}
        func matches(_ other:Frame)->Bool {slot === other.slot && parent === other.parent && body != nil && body === other.body && sameSpace(other)}
        func accepts(position:CGPoint,angle:CGFloat)->Bool {
            guard safe,Self.localCaps(position,angle) else {return false}
            let x=world.a*position.x+world.c*position.y,y=world.b*position.x+world.d*position.y
            let magnitude=Float(max(1,abs(angle),abs(atan2(world.b,world.a))))
            guard magnitude.isFinite else {return false}
            let angular=min(CGFloat(1e-5),CGFloat(magnitude.ulp)*32)
            return abs(x)<=tolerance.x && abs(y)<=tolerance.y && abs(angle.remainder(dividingBy:2*CGFloat.pi))<=angular
        }
        static func localCaps(_ position:CGPoint,_ angle:CGFloat)->Bool {
            position.x.isFinite && position.y.isFinite && angle.isFinite && max(abs(position.x),abs(position.y))<=0.01 && abs(angle.remainder(dividingBy:2*CGFloat.pi))<=1e-5
        }
    }
    private struct Removal {
        let frame:Frame,position:CGPoint,angle:CGFloat
    }
    private(set) var expectedBody:SKPhysicsBody?
    private var vertices:[CGFloat]=[]
    private var previous:Frame?
    private var removal:Removal?
    var hasProvenance:Bool {expectedBody != nil || previous != nil || removal != nil}

    static func concatenate(_ p:CGAffineTransform,_ m:CGAffineTransform)->CGAffineTransform {
        CGAffineTransform(a:p.a*m.a+p.c*m.b,b:p.b*m.a+p.d*m.b,c:p.a*m.c+p.c*m.d,d:p.b*m.c+p.d*m.d,tx:p.a*m.tx+p.c*m.ty+p.tx,ty:p.b*m.tx+p.d*m.ty+p.ty)
    }
    static func local(_ node:SKNode)->CGAffineTransform {
        let c=cos(node.zRotation),s=sin(node.zRotation)
        return CGAffineTransform(a:c*node.xScale,b:s*node.xScale,c:-s*node.yScale,d:c*node.yScale,tx:node.position.x,ty:node.position.y)
    }
    static func world(from node:SKNode)->(CGAffineTransform,SKNode,Bool) {
        var result=CGAffineTransform.identity,current:SKNode?=node,last=node
        while let n=current {
            if n is SKScene {return(result,n,false)}
            result=concatenate(local(n),result);last=n;current=n.parent
        }
        return(result,last,true)
    }
    func transition(to body:SKPhysicsBody?,vertices next:[CGFloat],slot:SKNode,chainValid:Bool) {
        guard expectedBody !== body else {return}
        // Skin replacement detaches then installs in one library transaction;
        // retain its exact removal proof only across that nil->owned handover.
        let handover=expectedBody==nil && slot.physicsBody==nil && removal != nil && body != nil
        if !handover {
            removal=nil
            if chainValid,let old=expectedBody,slot.physicsBody === old,old.node === slot,!old.isDynamic,
               let parent=slot.parent,slot.xScale==1,slot.yScale==1,slot.zPosition==0 {
                let (world,space,detached)=Self.world(from:parent)
                if let frame=try? Frame(slot:slot,parent:parent,space:space,detached:detached,body:old,world:world,vertices:vertices),
                   frame.accepts(position:slot.position,angle:slot.zRotation) || (slot.position == .zero && slot.zRotation==0) {
                    removal=Removal(frame:frame,position:slot.position,angle:slot.zRotation)
                }
            }
        }
        previous=nil;expectedBody=body;vertices=next
    }
    /// Preflight only; caller performs every accepted write after all slot plans.
    func plan(slot:SKNode,parent:SKNode,world:CGAffineTransform,space:SKNode,detached:Bool,chainValid:Bool)throws->Bool {
        let old=previous;previous=nil // expire on every attempted numeric stage
        let token=removal
        if let token=token,
           !(token.frame.slot === slot && slot.parent === parent && token.frame.parent === parent && token.frame.space === space && token.frame.detached==detached && token.position==slot.position && token.angle==slot.zRotation && (slot.physicsBody==nil || (slot.physicsBody === expectedBody && slot.physicsBody?.node === slot && slot.physicsBody?.isDynamic==false))) {removal=nil}
        guard chainValid else {return false}
        guard Frame.localCaps(slot.position,slot.zRotation) else {removal=nil;return false}
        let owned=expectedBody != nil && slot.physicsBody === expectedBody && expectedBody?.node === slot && expectedBody?.isDynamic==false
        if !owned,removal==nil {
            // Authority is known without a world budget, including an invalidated
            // removal token. Unauthorized nonidentity wins over context errors.
            guard slot.position == .zero,slot.zRotation==0 else {return false}
            guard world.a.isFinite,world.b.isFinite,world.c.isFinite,world.d.isFinite,world.tx.isFinite,world.ty.isFinite,Float(world.tx).isFinite,Float(world.ty).isFinite else {throw Frame.contextError()}
            return true
        }
        let frame=try Frame(slot:slot,parent:parent,space:space,detached:detached,body:owned ? expectedBody:nil,world:world,vertices:owned ? vertices:(removal?.frame.vertices ?? []))
        previous=owned && frame.safe ? frame:nil
        let canonical=slot.position == .zero && slot.zRotation==0
        let eligible=owned && (frame.accepts(position:slot.position,angle:slot.zRotation) || (old?.matches(frame)==true && old!.accepts(position:slot.position,angle:slot.zRotation)))
        let removed=removal != nil && Frame.localCaps(slot.position,slot.zRotation)
        removal=nil // locally valid attempt consumes exact one-shot permission
        return canonical || eligible || removed
    }
    func invalidateAttempt() {previous=nil}
}
