import SpriteKit

/// Resource lifetime is bounded by the immutable asset; no global material cache.
final class MeshRendererResources {
    private var materials:[ObjectIdentifier:MeshTriangleNode.Material]=[:]
    let regionShader:SKShader?

    init(attachments:[CompiledAttachment]) {
        var needsRegions=false
        for attachment in attachments {
            guard let region=attachment.texture else {continue}
            switch attachment.content {
            case .mesh:
                let key=ObjectIdentifier(region.texture)
                if materials[key]==nil {materials[key]=MeshTriangleNode.Material(texture:region.texture,pixelSize:region.pixelSize)}
            case .region:needsRegions=true
            default:break
            }
        }
        if needsRegions {
            let shader=SKShader(source:"""
            void main() {
                vec3 p=vec3(v_tex_coord,1.0);
                vec2 uv=vec2(dot(a_uvX,p),dot(a_uvY,p));
                if (a_nearest>0.5) uv=(floor(uv*a_pixelSize)+vec2(0.5))/a_pixelSize;
                gl_FragColor=texture2D(u_texture,uv)*vec4(a_tint.rgb*a_tint.a,a_tint.a)*v_color_mix.a;
            }
            """)
            shader.attributes=[SKAttribute(name:"a_uvX",type:.vectorFloat3),SKAttribute(name:"a_uvY",type:.vectorFloat3),SKAttribute(name:"a_tint",type:.vectorFloat4),SKAttribute(name:"a_pixelSize",type:.vectorFloat2),SKAttribute(name:"a_nearest",type:.float)]
            regionShader=shader
        } else {regionShader=nil}
    }
    func material(for texture:SKTexture)->MeshTriangleNode.Material {materials[ObjectIdentifier(texture)]!}
}
