import Foundation
import AppKit
import SpriteKit

func require(_ condition:@autoclosure()->Bool,_ message:String)throws {
    guard condition() else {throw DeviceRunFailure(message)}
}
func rejected(_ body:()throws->Void)throws {
    var didThrow=false;do {try body()} catch {didThrow=true}
    try require(didThrow,"Expected rejection")
}
let base=URL(fileURLWithPath:CommandLine.arguments[1]),manifest=Data("{}\n".utf8)
let id=UUID().uuidString.lowercased()
let run=try DeviceRunContext(base:base,runID:id,sourceManifest:manifest)
try require(run.status=="running","Initial running state")
try rejected {try run.complete()}
try rejected {_=try DeviceRunContext(base:base,runID:id,sourceManifest:manifest)}
try run.writeReport("proof.json",payload:["ok":true])
for stage in DeviceRunContext.requiredStages {try run.markCompleted(stage)}
try run.complete();try require(run.status=="completed","Complete state")
let record=try JSONSerialization.jsonObject(with:Data(contentsOf:run.directory.appendingPathComponent("proof.json"))) as! [String:Any]
try require(record["runID"] as? String==id,"Report run identity")
try require(record["sourceManifestSHA256"] as? String==DeviceRunContext.hash(manifest),"Report source identity")
let broken=try DeviceRunContext(base:base,runID:UUID().uuidString.lowercased(),sourceManifest:manifest) {data,url in
    if url.lastPathComponent=="release-gate.json" {throw DeviceRunFailure("Injected report write failure")}
    try data.write(to:url,options:.atomic)
}
try rejected {try broken.writeReport("release-gate.json",payload:["ok":true])}
try require(broken.status=="failed","Write failure must fail run")
try rejected {try broken.complete()}
try broken.fail(DeviceRunFailure("Expected write error"))
let failed=try JSONSerialization.jsonObject(with:Data(contentsOf:broken.directory.appendingPathComponent("run-manifest.json"))) as! [String:Any]
try require(failed["status"] as? String=="failed","Persist failed state")
try rejected {_=try DeviceRunContext(base:base,runID:UUID().uuidString.lowercased(),sourceManifest:manifest,write:{_,_ in throw DeviceRunFailure("Startup write failure")})}
_ = NSApplication.shared
let lifecycle=DeviceLifecycleGate(view:SKView(frame:CGRect(x:0,y:0,width:256,height:256)))
let result=try lifecycle.reentrantAndConflict()
try require(result["harnessReleasedBeforePerformance"] as? Bool==true,"Actual reentrant harness release")
let asset=try authoredAsset("slot-transitions")
try rejected {
    try withReleasedDeviceHarness(asset:asset) {h in
        // Deliberately create the reviewed cycle, then force failure. The real
        // unconditional cleanup must break it before propagating this error.
        h.skeleton.eventTriggered={_ in _=h.skeleton}
        throw DeviceRunFailure("Injected lifecycle failure")
    } as Void
}
print("PASS: fresh IDs, duplicate rejection, source binding, required stages, report/startup failures, real reentrant release, failure cleanup")
