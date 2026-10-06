import SpriteKit

struct MeshAttachmentKey:Hashable {let slot:Int;let name:String}
struct CompiledAttachment {
    enum Content {
        case mesh(CompiledMesh)
        case region(RegionAttachmentModel)
        case point(PointAttachmentModel)
        case boundingBox(BoundingBoxAttachmentModel)
    }
    let id:Int
    let slot:Int
    let name:String
    let path:String
    let color:SIMD4<Float>
    let texture:SpineMeshTextureRegion?
    let content:Content
    let sourceKind:SpineSkinAttachmentKind

    init(id:Int,slot:Int,name:String,path:String,color:SIMD4<Float>,texture:SpineMeshTextureRegion?,
         content:Content,sourceKind:SpineSkinAttachmentKind? = nil) {
        self.id=id;self.slot=slot;self.name=name;self.path=path;self.color=color
        self.texture=texture;self.content=content
        if let sourceKind=sourceKind {self.sourceKind=sourceKind}
        else {
            switch content {
            case .mesh:self.sourceKind = .mesh
            case .region:self.sourceKind = .region
            case .point:self.sourceKind = .point
            case .boundingBox:self.sourceKind = .boundingBox
            }
        }
    }
}
