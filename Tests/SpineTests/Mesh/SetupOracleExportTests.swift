#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class SetupOracleExportTests:XCTestCase {
    func testExportAllThreeFixturesForPinnedExternalSetupOracle()throws {
        var snapshots:[[String:Any]]=[]
        let fixtures:[(String,String,[String])]=[("goblins-pro","goblins.atlas",["goblin","goblingirl"]),("weighted-link","authored.atlas",["default","other"]),("deform-resources","authored.atlas",["default"])]
        for (fixture,atlas,skins) in fixtures {
            let asset=try fixture=="goblins-pro" ? goblinAsset():authoredAsset(fixture)
            for skin in skins {
                let skeleton=try Skeleton(meshAsset:asset,skin:skin)
                try skeleton.prepareMeshes(for:validMeshContext)
                let snapshot=skeleton.meshRuntime!.setupRenderer!.snapshot
                var merged=asset.compiled.skinAttachments["default"] ?? [:]
                for (key,value) in asset.compiled.skinAttachments[skin] ?? [:] {merged[key]=value}
                var parts:[[String:Any]]=[]
                for (slot,key) in snapshot.activeAttachments.enumerated() {
                    guard let key=key,let id=merged[.init(slot:slot,name:key)] else {continue}
                    let attachment=asset.compiled.attachments[id]
                    var part:[String:Any]=["slot":asset.compiled.slots[slot].name,"attachment":key]
                    switch attachment.content {
                    case .mesh(let mesh):
                        part["vertices"]=snapshot.vertices[slot].flatMap{[$0.x,$0.y]};part["uvs"]=mesh.uvs.flatMap{[$0.x,$0.y]}
                        let source=asset.compiled.attachments[mesh.deformSourceID]
                        part["deformSourceName"]=source.name
                        part["deformSourceSkin"]=asset.compiled.skinAttachments.first {$0.value.values.contains(mesh.deformSourceID)}!.key
                    case .region(let model):
                        let region=try XCTUnwrap(skeleton.meshRuntime!.setupRenderer!.regionNode(named:key,slot:slot))
                        let uvx=try XCTUnwrap(region.value(forAttributeNamed:"a_uvX")).vectorFloat3Value,uvy=try XCTUnwrap(region.value(forAttributeNamed:"a_uvY")).vectorFloat3Value
                        let metadata=attachment.texture!
                        let unscaled=CGSize(width:model.size.width*metadata.trimRect.width/metadata.originalSize.width,height:model.size.height*metadata.trimRect.height/metadata.originalSize.height)
                        let corners:[CGPoint]=[.zero,CGPoint(x:1,y:0),CGPoint(x:1,y:1),CGPoint(x:0,y:1)]
                        part["vertices"]=corners.flatMap {corner->[Double] in
                            let point=CGPoint(x:(corner.x-region.anchorPoint.x)*unscaled.width,y:(corner.y-region.anchorPoint.y)*unscaled.height)
                            let p=region.convert(point,to:skeleton);return [Double(p.x),Double(p.y)]
                        }
                        part["uvs"]=corners.flatMap {p->[Float] in [uvx.x*Float(p.x)+uvx.y*Float(p.y)+uvx.z,uvy.x*Float(p.x)+uvy.y*Float(p.y)+uvy.z]}
                    default:continue
                    }
                    parts.append(part)
                }
                snapshots.append(["fixture":fixture,"atlas":atlas,"skin":skin,"activeAttachments":snapshot.activeAttachments.map {$0 as Any? ?? NSNull()},"drawOrder":snapshot.drawOrder,"parts":parts])
            }
        }
        let output=URL(fileURLWithPath:ProcessInfo.processInfo.environment["SPINE_MESH_ORACLE_OUTPUT"] ?? "/tmp/spine-phase3-oracle")
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        try JSONSerialization.data(withJSONObject:snapshots,options:[.prettyPrinted,.sortedKeys]).write(to:output.appendingPathComponent("setup-vertices.json"))
        XCTAssertEqual(snapshots.count,5)
    }
}
#endif
