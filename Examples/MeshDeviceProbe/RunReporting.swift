import Foundation
import CryptoKit

struct DeviceRunFailure:Error {let message:String;init(_ message:String) {self.message=message}}

/// A caller-selected fresh run directory. No result from a previous launch can
/// satisfy this run, even if startup fails before any report can be written.
final class DeviceRunContext {
    static var current:DeviceRunContext?
    static let requiredStages:Set<String>=["render","physics-stress","parity-export","lifetime","lifecycle","performance"]
    let runID:String,sourceManifestSHA256:String,directory:URL
    private(set) var status="running"
    private var stages=Set<String>()
    private let writeData:(Data,URL)throws->Void
    init(base:URL,runID:String,sourceManifest:Data,write:@escaping(Data,URL)throws->Void = {try $0.write(to:$1,options:.atomic)})throws {
        guard let uuid=UUID(uuidString:runID),uuid.uuidString.lowercased()==runID else {throw DeviceRunFailure("A fresh lowercase UUID run ID is required")}
        self.runID=runID;sourceManifestSHA256=Self.hash(sourceManifest)
        directory=base.appendingPathComponent("runs",isDirectory:true).appendingPathComponent(runID,isDirectory:true);writeData=write
        guard !FileManager.default.fileExists(atPath:directory.path) else {throw DeviceRunFailure("Run directory already exists; generate a new run ID")}
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        try write(sourceManifest,directory.appendingPathComponent("source-sha256.json"))
        try persistManifest()
    }
    static func hash(_ data:Data)->String {SHA256.hash(data:data).map {String(format:"%02x",$0)}.joined()}
    func writeReport(_ name:String,payload:Any,reportStatus:String="completed")throws {
        guard status=="running" else {throw DeviceRunFailure("Cannot write a result after run failure/completion")}
        do {
            let envelope:[String:Any]=["runID":runID,"sourceManifestSHA256":sourceManifestSHA256,"status":reportStatus,"payload":payload]
            let data=try JSONSerialization.data(withJSONObject:envelope,options:[.prettyPrinted,.sortedKeys])
            try writeData(data,directory.appendingPathComponent(name))
        } catch {status="failed";throw error}
    }
    func markCompleted(_ stage:String)throws {
        guard status=="running",Self.requiredStages.contains(stage) else {throw DeviceRunFailure("Invalid stage completion")}
        stages.insert(stage);try persistManifest()
    }
    func complete()throws {
        guard status=="running",stages==Self.requiredStages else {throw DeviceRunFailure("Cannot complete an incomplete or failed run")}
        status="completed"
        do {try persistManifest()} catch {status="failed";throw error}
    }
    func fail(_ error:Error)throws {status="failed";try persistManifest(error:String(describing:error))}
    private func persistManifest(error:String?=nil)throws {
        var artifacts=[String:String]()
        for url in try FileManager.default.contentsOfDirectory(at:directory,includingPropertiesForKeys:nil) where url.lastPathComponent != "run-manifest.json" {
            artifacts[url.lastPathComponent]=Self.hash(try Data(contentsOf:url))
        }
        var record:[String:Any]=["runID":runID,"sourceManifestSHA256":sourceManifestSHA256,"status":status,"completedStages":stages.sorted(),"artifacts":artifacts]
        if let error=error {record["error"]=error}
        try writeData(JSONSerialization.data(withJSONObject:record,options:[.prettyPrinted,.sortedKeys]),directory.appendingPathComponent("run-manifest.json"))
    }
}
var deviceOutput:URL {
    guard let context=DeviceRunContext.current else {preconditionFailure("Device run has not been initialized")}
    return context.directory
}
func deviceReport(_ name:String,payload:Any,status:String="completed")throws {
    guard let context=DeviceRunContext.current else {throw DeviceRunFailure("No active device run")}
    try context.writeReport(name,payload:payload,reportStatus:status)
}
