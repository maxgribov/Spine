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
}
