import Foundation
import SpriteKit
import Spine
import Darwin

private func residentBytes() -> UInt64? {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)
    let result = withUnsafeMutablePointer(to: &info) { pointer in
        pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }
    return result == KERN_SUCCESS ? info.resident_size : nil
}

/// Diagnostic timing collector. Device/workload budgets are deliberately not inferred.
func collectMeasurements(to output: URL) throws {
    let beforeAsset = residentBytes()
    let started = ProcessInfo.processInfo.systemUptime
    let asset = try loadAsset()
    let loadMs = (ProcessInfo.processInfo.systemUptime - started) * 1000
    let afterAsset = residentBytes()
    let owner = try Skeleton(meshAsset: asset, skin: "base")
    let a = Wardrobe().composition, b = Wardrobe(hat: 1, clothes: 1, team: 3, earring: false).composition
    let context = SpineMeshFrameContext(skeletonToPixels: .identity, pixelSize: CGSize(width: 680, height: 520))
    func sample(_ look: SpineSkinComposition) throws -> [String: Double] {
        let start = ProcessInfo.processInfo.systemUptime
        try owner.apply(skinComposition: look)
        let applied = ProcessInfo.processInfo.systemUptime
        try owner.prepareMeshes(for: context)
        return ["applyMs": (applied - start) * 1000, "prepareMs": (ProcessInfo.processInfo.systemUptime - applied) * 1000]
    }
    let cold = try sample(a)
    for i in 0..<100 { try autoreleasepool { _ = try sample(i.isMultiple(of: 2) ? b : a) } }
    var alternating: [[String: Double]] = [], repeated: [[String: Double]] = [], residentSamples: [UInt64] = []
    for i in 0..<1000 {
        try autoreleasepool { alternating.append(try sample(i.isMultiple(of: 2) ? b : a)) }
        if let bytes = residentBytes() { residentSamples.append(bytes) }
    }
    for _ in 0..<1000 { try autoreleasepool { repeated.append(try sample(a)) } }
    func stats(_ samples: [[String: Double]]) -> [String: Any] {
        Dictionary(uniqueKeysWithValues: ["applyMs", "prepareMs"].map { key in
            let values = samples.compactMap { $0[key] }.sorted()
            return (key, ["median": values[values.count / 2], "p95": values[Int(ceil(Double(values.count) * 0.95)) - 1], "max": values.last!] as Any)
        })
    }
    let build = try JSONSerialization.jsonObject(with: Data(contentsOf: Bundle.main.resourceURL!.appendingPathComponent("build.json")))
    let report: [String: Any] = ["schemaVersion": 1, "releaseGate": "pending", "build": build,
        "os": ProcessInfo.processInfo.operatingSystemVersionString, "processorCount": ProcessInfo.processInfo.processorCount,
        "workload": ["skeletons": 1, "warmup": 100, "alternating": 1000, "repeat": 1000, "catalogSkins": asset.skinNames.count,
                     "states": try asset.skinNames.reduce(0) { try $0 + asset.skinDescription(named: $1).entries.count }],
        "assetLoadMs": loadMs,
        "memory": ["processResidentBeforeAssetBytes": beforeAsset as Any? ?? NSNull(),
                   "processResidentAfterAssetBytes": afterAsset as Any? ?? NSNull(),
                   "postSwitchProcessResidentSamples": residentSamples,
                   "assetResidentBytes": NSNull(), "peakSwitchBytes": NSNull()],
        "memoryNote": "Process resident snapshots are diagnostic, not isolated asset size or a transient staging peak. Use platform allocation tooling for those release metrics.",
        "cold": ["samples": [cold], "statistics": stats([cold])],
        "alternating": ["samples": alternating, "statistics": stats(alternating)],
        "repeat": ["samples": repeated, "statistics": stats(repeated)]]
    try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: output)
}
