#if os(macOS) || os(iOS)
import XCTest
import SpriteKit
@testable import Spine

final class AnimationOracleExportTests:XCTestCase {
    func testExportCompleteKeyMidpointAndSwitchBoundaryGrid()throws {
        var snapshots:[[String:Any]]=[],grids:[[String:Any]]=[]
        let fixtures:[(String,String,[String])]=[("goblins-pro","goblins.atlas",["goblin","goblingirl"]),("weighted-link","authored.atlas",["default","other"]),("deform-resources","authored.atlas",["default"]),("slot-transitions","authored.atlas",["default","compatible","incompatible"])]
        for (fixture,atlas,skins) in fixtures {
            let asset=try fixture=="goblins-pro" ? goblinAsset():authoredAsset(fixture)
            let raw=try JSONSerialization.jsonObject(with:meshResource(fixture+".json")) as! [String:Any]
            for clip in asset.compiled.clips {
                let animation=(raw["animations"] as! [String:Any])[clip.name]!
                var keyTimes=Set<Float>([0]),switchTimes=Set<Float>()
                func visit(_ value:Any,path:[String]=[]) {
                    if let list=value as? [[String:Any]] {
                        for (index,key) in list.enumerated() {
                            let time=Float((key["time"] as? NSNumber)?.doubleValue ?? 0);keyTimes.insert(time)
                            if path.last=="attachment" || path.last=="drawOrder" || (index>0 && list[index-1]["curve"] as? String == "stepped") {switchTimes.insert(time)}
                        }
                    } else if let object=value as? [String:Any] {for (key,value) in object {visit(value,path:path+[key])}}
                }
                visit(animation)
                let ordered=keyTimes.sorted();var grid=keyTimes
                for (a,b) in zip(ordered,ordered.dropFirst()) {grid.insert((a+b)/2)}
                for time in switchTimes {grid.insert(max(0,time-1e-5));grid.insert(time+1e-5)}
                let times=grid.sorted()
                grids.append(["fixture":fixture,"animation":clip.name,"keyTimes":ordered,"switchTimes":switchTimes.sorted(),"times":times])
                for skin in skins {
                    let h=try MeshActionHarness(asset:asset);try h.skeleton.apply(skin:skin)
                    h.start(try h.skeleton.action(animation:clip.name))
                    for requested in times {
                        h.update(Double(requested))
                        try h.skeleton.prepareMeshes(for:validMeshContext)
                        let state=h.skeleton.meshRuntime!,snapshot=state.setupRenderer!.snapshot
                        XCTAssertEqual(state.time,min(Double(requested),clip.duration),accuracy:2e-6)
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
                                part["deformSourceName"]=source.name;part["deformSourceSkin"]=asset.compiled.skinAttachments.first {$0.value.values.contains(mesh.deformSourceID)}!.key
                            case .region(let model):
                                let region=try XCTUnwrap(h.skeleton.meshRuntime!.setupRenderer!.regionNode(named:key,slot:slot)),metadata=attachment.texture!
                                let uvx=try XCTUnwrap(region.value(forAttributeNamed:"a_uvX")).vectorFloat3Value,uvy=try XCTUnwrap(region.value(forAttributeNamed:"a_uvY")).vectorFloat3Value
                                let size=CGSize(width:model.size.width*metadata.trimRect.width/metadata.originalSize.width,height:model.size.height*metadata.trimRect.height/metadata.originalSize.height)
                                let corners=[CGPoint.zero,CGPoint(x:1,y:0),CGPoint(x:1,y:1),CGPoint(x:0,y:1)]
                                part["vertices"]=corners.flatMap {corner->[Double] in
                                    let p=region.convert(CGPoint(x:(corner.x-region.anchorPoint.x)*size.width,y:(corner.y-region.anchorPoint.y)*size.height),to:h.skeleton)
                                    return [Double(p.x),Double(p.y)]
                                }
                                part["uvs"]=corners.flatMap {p->[Float] in [uvx.x*Float(p.x)+uvx.y*Float(p.y)+uvx.z,uvy.x*Float(p.x)+uvy.y*Float(p.y)+uvy.z]}
                            default:continue
                            }
                            parts.append(part)
                        }
                        snapshots.append(["fixture":fixture,"atlas":atlas,"skin":skin,"animation":clip.name,"time":state.time,"requestedTime":requested,
                                          "activeAttachments":snapshot.activeAttachments.map {$0 as Any? ?? NSNull()},"drawOrder":snapshot.drawOrder,
                                          "slotColors":state.slotStates.map {[$0.color.x,$0.color.y,$0.color.z,$0.color.w]},"parts":parts])
                    }
                }
            }
        }
        let output=URL(fileURLWithPath:ProcessInfo.processInfo.environment["SPINE_MESH_ORACLE_OUTPUT"] ?? "/tmp/spine-phase4-oracle")
        try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
        try JSONSerialization.data(withJSONObject:snapshots,options:[.prettyPrinted,.sortedKeys]).write(to:output.appendingPathComponent("animation-vertices.json"))
        try JSONSerialization.data(withJSONObject:grids,options:[.prettyPrinted,.sortedKeys]).write(to:output.appendingPathComponent("animation-grid.json"))
        XCTAssertEqual(grids.count,4);XCTAssertGreaterThan(snapshots.count,50)
    }
}
#endif
