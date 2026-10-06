import Foundation
import SpriteKit
import Darwin
@testable import Spine

// A separate diagnostic executable, never linked into the public example or library.
enum EvidenceError: Error { case unavailable(String) }
struct MemorySample {
    let taskInfoValid: Bool
    let footprint: UInt64
    let resident: UInt64
    let liveHeap: Int
    let cumulativeHeapHighWater: Int
    init() {
        var info = mach_task_basic_info(), count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { p in p.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count) } }
        resident = result == KERN_SUCCESS ? info.resident_size : 0
        var vm = task_vm_info_data_t(), vmCount = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let vmResult = withUnsafeMutablePointer(to: &vm) { p in p.withMemoryRebound(to: integer_t.self, capacity: Int(vmCount)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &vmCount) } }
        footprint = vmResult == KERN_SUCCESS ? vm.phys_footprint : 0
        taskInfoValid = result == KERN_SUCCESS && vmResult == KERN_SUCCESS
        var statistics = malloc_statistics_t(); malloc_zone_statistics(nil, &statistics)
        liveHeap = statistics.size_in_use; cumulativeHeapHighWater = statistics.max_size_in_use
    }
    var json: [String: Any] { ["taskInfoValid": taskInfoValid, "physicalFootprintBytes": footprint, "residentBytes": resident, "liveHeapBytes": liveHeap, "processCumulativeHeapHighWaterBytes": cumulativeHeapHighWater] }
}

func runMemoryProbe(distinct: Bool, fixtureURL: URL? = nil) throws -> [String: Any] {
        #if os(macOS)
        _ = NSApplication.shared
        #endif
        let count = distinct ? 12 : 3
        func makeAsset(_ pirate: Bool) throws -> SpineMeshAsset { try scaledAsset(pirate: pirate, fixtureURL: fixtureURL) }
        func preload(_ values: [SpineMeshAsset]) throws {
            var seen = Set<ObjectIdentifier>()
            let textures = values.flatMap { $0.compiled.attachments.compactMap { $0.texture?.texture } }.filter { seen.insert(ObjectIdentifier($0)).inserted }
            var complete = false
            SKTexture.preload(textures) { complete = true }
            let deadline = Date().addingTimeInterval(10)
            while !complete, Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.01)) }
            guard complete else { throw EvidenceError.unavailable("texture preload timeout") }
        }
        try autoreleasepool {
            let warm = try makeAsset(false); try preload([warm])
            let owner = try Skeleton(meshAsset: warm, skin: "base")
            try owner.prepareMeshes(for: SpineMeshFrameContext(skeletonToPixels: .identity, pixelSize: CGSize(width: 256, height: 256)))
        }
        var samples = Array(repeating: MemorySample(), count: 4096)
        var sampleCount = 0
        func recordStaging() { samples[sampleCount] = MemorySample(); sampleCount += 1 }
        let before = MemorySample()
        var assets: [SpineMeshAsset] = []
        try autoreleasepool { assets = try (0..<count).map { _ in try makeAsset(true) } + [makeAsset(false), makeAsset(false)] }
        try preload(assets)
        let afterAssets = MemorySample()
        var owner: Skeleton? = try Skeleton(meshAsset: assets[0], skin: "base")
        let context = SpineMeshFrameContext(skeletonToPixels: .identity, pixelSize: CGSize(width: 256, height: 256))
        for i in 0..<100 { try autoreleasepool { try owner!.apply(skinComposition: scaledLook(i)); try owner!.prepareMeshes(for: context) } }
        let beforeSwitch = MemorySample()
        owner!.meshRuntime!.compositionStageCheck = { _ in recordStaging() }
        owner!.meshRuntime!.compositionStagingCompleted = { recordStaging() }
        for i in 100..<200 { try autoreleasepool { try owner!.apply(skinComposition: scaledLook(i)); try owner!.prepareMeshes(for: context) } }
        owner!.meshRuntime!.compositionStageCheck = nil
        owner!.meshRuntime!.compositionStagingCompleted = nil
        let afterSwitch = MemorySample()
        weak var releasedOwner = owner
        autoreleasepool { owner = nil; assets = [] }
        let afterRelease = MemorySample()
        guard [before, afterAssets, beforeSwitch, afterSwitch, afterRelease].allSatisfy(\.taskInfoValid),
              samples.prefix(sampleCount).allSatisfy(\.taskInfoValid) else {
            throw EvidenceError.unavailable("task_info failed; physical-memory deltas are unavailable")
        }
        let result: [String: Any] = ["mode": count == 12 ? "distinct" : "shared", "pirateAssets": count,
            "decodedCatalogTextureBytes": (count*25+2)*256*256*4,
            "assetIncrementalPhysicalFootprintBytes": Int64(afterAssets.footprint)-Int64(before.footprint),
            "assetIncrementalLiveHeapBytes": afterAssets.liveHeap-before.liveHeap,
            "peakObservedStagingPhysicalFootprintDeltaBytes": max(Int64(0),Int64(samples.prefix(sampleCount).map(\.footprint).max() ?? beforeSwitch.footprint)-Int64(beforeSwitch.footprint)),
            "beforeAssetLoad": before.json, "afterAssetLoadAndDrain": afterAssets.json,
            "beforeSwitch": beforeSwitch.json, "stagingSamples": samples.prefix(sampleCount).map(\.json), "afterSwitchAndDrain": afterSwitch.json,
            "afterOwnerAndAssetsRelease": afterRelease.json, "ownerReleased": releasedOwner == nil,
            "peakObservedStagingHeapDeltaBytes": max(0,(samples.prefix(sampleCount).map(\.liveHeap).max() ?? beforeSwitch.liveHeap)-beforeSwitch.liveHeap),
            "peakObservedStagingResidentDeltaBytes": max(Int64(0),Int64(samples.prefix(sampleCount).map(\.resident).max() ?? beforeSwitch.resident)-Int64(beforeSwitch.resident)),
            "limitations": ["Heap/resident point samples at every detached region creation and before commit with the complete staged tree are observed staging peaks, not a guarantee of all transient allocation/GPU residency maxima.", "Asset load delta follows framework prewarm and synchronous catalog texture preload; released references do not force system caches to return resident pages.", "No absolute memory ceiling was requested by the owner; existing lifetime tests enforce no retained region growth."]]
        return result
}
