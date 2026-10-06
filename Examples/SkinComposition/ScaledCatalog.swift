import Foundation
import SpriteKit
import Spine
import os

/// Synthetic catalog: 8 hats + 8 clothes + 4 earrings, with 4 separate team layers.
/// The 256x256 textures are a stated stress fixture, not inferred production artwork.
final class ScaledTextures: SpineMeshTextureProvider {
    private var regions: [String: SpineMeshTextureRegion] = [:]
    func region(named path: String) throws -> SpineMeshTextureRegion {
        if let value = regions[path] { return value }
        let texture = SKTexture(data: Data(repeating: 255, count: 256 * 256 * 4), size: CGSize(width: 256, height: 256))
        texture.filteringMode = .nearest
        let region = try SpineMeshTextureRegion(texture: texture, pixelSize: CGSize(width: 256, height: 256), originalSize: CGSize(width: 256, height: 256), trimRect: CGRect(x: 0, y: 0, width: 256, height: 256), uvTransform: .identity)
        regions[path] = region; return region
    }
}

func scaledAsset(pirate: Bool, fixtureURL: URL? = nil) throws -> SpineMeshAsset {
    let data = try Data(contentsOf: fixtureURL ?? Bundle.main.resourceURL!.appendingPathComponent("wardrobe.json"))
    guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any], let skins = json["skins"] as? [[String: Any]],
          let base = skins.first(where: { $0["name"] as? String == "base" }), let entries = base["attachments"] as? [String: Any] else { throw EvidenceError.unavailable("fixture") }
    func item(_ name: String, slots: [String], color: String) throws -> [String: Any] {
        var own: [String: Any] = [:]
        for slot in slots {
            guard let states = entries[slot] as? [String: [String: Any]] else { throw EvidenceError.unavailable(slot) }
            own[slot] = states.mapValues { original -> [String: Any] in
                var value = original; value["path"] = name; value["color"] = color; return value
            }
        }
        return ["name": name, "attachments": own]
    }
    var catalog = [try item("base", slots: entries.keys.sorted(), color: "ffffffff")]
    if pirate {
        for i in 0..<8 { catalog.append(try item("hat/\(i)", slots: ["hat-front", "hat-back"], color: i.isMultiple(of: 2) ? "ff6666ff" : "66ff66ff")) }
        for i in 0..<8 { catalog.append(try item("clothes/\(i)", slots: ["torso", "sleeves"], color: i.isMultiple(of: 2) ? "6666ffff" : "ffff66ff")) }
        for i in 0..<4 { catalog.append(try item("earring/\(i)", slots: ["earring"], color: "ffff00ff")) }
        for (i, color) in ["3366ffff", "ff8800ff", "8833ffff", "ff66aaff"].enumerated() { catalog.append(try item("team/\(i)", slots: ["team"], color: color)) }
    }
    json["skins"] = catalog
    return try SpineMeshAsset(json: JSONSerialization.data(withJSONObject: json), textures: ScaledTextures())
}

func scaledLook(_ index: Int, team: Int = 0) -> SpineSkinComposition {
    .init(baseSkin: "base", layers: [.replace(skin: "hat/\(index % 8)", slots: ["hat-front", "hat-back"]),
        .replace(skin: "clothes/\((index / 8) % 8)", slots: ["torso", "sleeves"]),
        .replace(skin: "earring/\((index / 64) % 4)", slots: ["earring"]), .hide(slots: ["bandana"]), .overlay(skin: "team/\(team)")])
}
