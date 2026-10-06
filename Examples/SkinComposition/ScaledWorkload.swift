import Foundation
import SpriteKit
import Spine
import os

final class ScaledWorkloadScene: SKScene {
    private let output: URL
    private let runID: String
    private var owners: [Skeleton] = []
    private var phase = 0, count = 0
    private var now: Double = 0, previous: Double?
    private var match: [[String: Double]] = [], distinctMatch: [[String: Double]] = [], preview: [[String: Double]] = []
    private var assets: [SpineMeshAsset]
    var completion: ((Error?) -> Void)?
    init(output: URL, runID: String = UUID().uuidString) throws {
        self.output = output
        self.runID = runID
        let log = OSLog(subsystem: "dev.spine.skincomposition", category: .pointsOfInterest)
        os_signpost(.begin, log: log, name: "FullCatalogLoad")
        assets = try [scaledAsset(pirate: true), scaledAsset(pirate: true), scaledAsset(pirate: true), scaledAsset(pirate: false), scaledAsset(pirate: false)]
        os_signpost(.end, log: log, name: "FullCatalogLoad")
        super.init(size: CGSize(width: 680, height: 520)); scaleMode = .aspectFit; backgroundColor = .darkGray
        try installOwners(distinct: false)
    }
    private func installOwners(distinct: Bool) throws {
        for i in 0..<28 {
            let asset = i < 12 ? assets[distinct ? i : i % 3] : assets[i < 18 ? assets.count - 2 : assets.count - 1]
            let owner = try Skeleton(meshAsset: asset, skin: "base")
            owner.position = CGPoint(x: 55 + (i % 7) * 92, y: 80 + (i / 7) * 110); owner.setScale(0.7)
            if i < 12 { try owner.apply(skinComposition: scaledLook(i, team: i / 3)) }
            owner.run(.repeatForever(try owner.action(animation: "walk")))
            owners.append(owner); addChild(owner)
        }
    }
    required init?(coder: NSCoder) { fatalError("Use init(output:)") }
    override func update(_ currentTime: TimeInterval) { now = currentTime }
    override func didFinishUpdate() {
        guard phase < 3, let view = view else { return }
        do {
            let start = ProcessInfo.processInfo.systemUptime
            if phase == 2 { try owners[0].apply(skinComposition: scaledLook(count % 256, team: count % 4)) }
            let applied = ProcessInfo.processInfo.systemUptime
            for owner in owners { try owner.prepareMeshes(in: view) }
            let end = ProcessInfo.processInfo.systemUptime
            if count >= 100, let previous = previous {
                let sample = ["applyMs": (applied-start)*1000, "prepareMs": (end-applied)*1000, "combinedMs": (end-start)*1000, "nativeFrameMs": (now-previous)*1000]
                if phase == 0 { match.append(sample) } else if phase == 1 { distinctMatch.append(sample) } else { preview.append(sample) }
            }
            previous = now; count += 1
            if count == 220 {
                if phase == 0 {
                    for owner in owners { owner.removeFromParent() }; owners = []; assets = []
                    assets = try (0..<12).map { _ in try scaledAsset(pirate: true) } + [scaledAsset(pirate: false), scaledAsset(pirate: false)]
                    try installOwners(distinct: true); phase = 1; count = 0; previous = nil
                } else if phase == 1 {
                    for owner in owners.dropFirst() { owner.removeFromParent() }
                    owners = [owners[0]]; phase = 2; count = 0; previous = nil
                } else {
                    phase = 3
                    let build = try JSONSerialization.jsonObject(with: Data(contentsOf: Bundle.main.resourceURL!.appendingPathComponent("build.json")))
                    let report: [String: Any] = ["runID": runID, "build": build, "os": ProcessInfo.processInfo.operatingSystemVersionString,
                        "catalog": ["pirateItems": 20, "pirateAssets": 3, "teams": 4, "teamSkinsPerPirate": 4, "baseSkinsPerAsset": 1,
                                    "sharedAssetCount": 5, "distinctAssetCount": 14, "sharedTextureCount": 77, "distinctTextureCount": 302, "textureWidth": 256, "textureHeight": 256, "sharedDecodedRGBABytes": 77*256*256*4, "distinctDecodedRGBABytes": 302*256*256*4,
                                    "entriesPerPirate": 94, "entriesPerNeutralOrProp": 14],
                        "assetSharing": "First: three pirate assets across four teams. Second: twelve distinct pirate assets. Both: six owners share one neutral asset; ten share one prop asset. The fourteen second-scenario assets remain resident during preview.",
                        "matchDistinct": ["owners": 28, "warmupFrames": 100, "samples": distinctMatch, "wardrobeChanges": 0],
                        "matchShared": ["owners": 28, "warmupFrames": 100, "samples": match, "wardrobeChanges": 0],
                        "preview": ["owners": 1, "warmupFrames": 100, "samples": preview],
                        "criterion": ["warmPreviewCombinedP95Ms": 1000.0/60.0, "memoryAbsoluteCeiling": NSNull()],
                        "limitations": ["Synthetic 256x256 per-item textures and simple authored rig, not production art", "Native frame intervals measure callbacks, not presented-frame GPU latency"]]
                    try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: output)
                    completion?(nil)
                }
            }
        } catch { phase = 3; completion?(error) }
    }
}
