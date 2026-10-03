#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

func meshResource(_ name:String)throws->Data {
    try Data(contentsOf:XCTUnwrap(Bundle.module.resourceURL).appendingPathComponent("Mesh41/"+name))
}
func goblinAsset()throws->SpineMeshAsset {
    let provider=try SpineAtlasTextureProvider(atlasText:String(decoding:meshResource("goblins.atlas"),as:UTF8.self),pageData:["goblins.png":meshResource("goblins.png")])
    return try SpineMeshAsset(json:meshResource("goblins-pro.json"),textures:provider)
}
func simpleMeshJSON() -> [String:Any] {
    ["skeleton":["hash":"authored","spine":"4.1.17","x":0,"y":0,"width":100,"height":100],
     "bones":[["name":"root"]],"slots":[["name":"slot","bone":"root","attachment":"mesh"]],
     "skins":[["name":"default","attachments":["slot":["mesh":["type":"mesh","uvs":[0,1,1,1,1,0,0,0],"vertices":[0,0,64,0,64,64,0,64],"triangles":[0,1,2,0,2,3]]]]]]]
}
func jsonData(_ object:[String:Any])throws->Data {try JSONSerialization.data(withJSONObject:object,options:.sortedKeys)}
final class TestMeshTextures:SpineMeshTextureProvider {
    let texture:SKTexture
    var requests:[String]=[]
    init(rgba:[UInt8]=[128,64,32,128]) {texture=SKTexture(data:Data(Array(repeating:rgba,count:16).flatMap{$0}),size:CGSize(width:4,height:4));texture.filteringMode = .nearest}
    func region(named path:String)throws->SpineMeshTextureRegion {
        requests.append(path)
        return try SpineMeshTextureRegion(texture:texture,pixelSize:CGSize(width:4,height:4),originalSize:CGSize(width:4,height:4),trimRect:CGRect(x:0,y:0,width:4,height:4),uvTransform:.identity)
    }
}
#endif

#if os(macOS) || os(iOS)
func editMeshAttachment(_ json:inout [String:Any],skin:Int=0,slot:String="slot",name:String="mesh",_ edit:(inout [String:Any])->Void) {
    var skins=json["skins"] as! [[String:Any]],attachments=skins[skin]["attachments"] as! [String:[String:[String:Any]]]
    var attachment=attachments[slot]![name] ?? [:];edit(&attachment);attachments[slot]![name]=attachment;skins[skin]["attachments"]=attachments;json["skins"]=skins
}
func expectMeshLoadError(_ json:[String:Any],_ code:SpineRuntimeError.Code,path:String?=nil,file:StaticString=#filePath,line:UInt=#line) throws {
    let textures=TestMeshTextures()
    XCTAssertThrowsError(try SpineMeshAsset(json:jsonData(json),textures:textures),file:file,line:line) { error in
        guard let error=error as? SpineRuntimeError else {return XCTFail("Wrong error type",file:file,line:line)}
        XCTAssertEqual(error.code,code,file:file,line:line)
        if let path=path {XCTAssertEqual(error.path,path,file:file,line:line)}
    }
    XCTAssertTrue(textures.requests.isEmpty,"Validation must precede resource resolution",file:file,line:line)
}
#endif

#if os(macOS) || os(iOS)
func authoredTextures()throws->SpineAtlasTextureProvider {
    try SpineAtlasTextureProvider(atlasText:String(decoding:meshResource("authored.atlas"),as:UTF8.self),pageData:["authored-straight.png":meshResource("authored-straight.png"),"authored-pma.png":meshResource("authored-pma.png")])
}
func authoredAsset(_ name:String)throws->SpineMeshAsset {try SpineMeshAsset(json:meshResource(name+".json"),textures:authoredTextures())}
#endif
