import Foundation

/// Test-only diagnostics remain internal to Spine. This CLI invokes their XCTest
/// host from the same checkout, instead of exposing a public geometry/debug API.
func verifyLibraryMesh(output:URL)throws {
    let root=URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    // Reuse the same immutable-baseline output guard as legacy characterization.
    try validateLegacyOutput(output,baseline:root.appendingPathComponent("features/mesh-support/validation/legacy-baseline"))
    try FileManager.default.createDirectory(at:output,withIntermediateDirectories:true)
    let logURL=output.appendingPathComponent("gpu-tests.log")
    FileManager.default.createFile(atPath:logURL.path,contents:nil)
    let log=try FileHandle(forWritingTo:logURL)
    defer {try? log.close()}
    let process=Process();process.executableURL=URL(fileURLWithPath:"/usr/bin/xcrun")
    process.arguments=["swift","test","--package-path",root.path,"--filter","GPUSetupTests|SetupOracleExportTests"]
    var environment=ProcessInfo.processInfo.environment
    environment["SPINE_MESH_VALIDATION_OUTPUT"]=output.path;environment["SPINE_MESH_ORACLE_OUTPUT"]=output.path
    process.environment=environment;process.standardOutput=log;process.standardError=log
    try process.run();process.waitUntilExit()
    guard process.terminationStatus==0 else {throw PrototypeError("Library setup GPU checks failed; inspect \(logURL.path)")}
    guard FileManager.default.fileExists(atPath:output.appendingPathComponent("gpu-validation.json").path),
          FileManager.default.fileExists(atPath:output.appendingPathComponent("setup-vertices.json").path) else {throw PrototypeError("Library setup checks did not produce required diagnostics")}
    print("Library mesh setup: production GPU checks passed. Run Scripts/compare-library-setup.mjs with pinned spine-core 4.1.56 for the external oracle. Artifacts: \(output.path)")
}
