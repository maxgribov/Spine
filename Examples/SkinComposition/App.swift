import Foundation
import SpriteKit
import Spine
#if os(macOS)
import AppKit
#else
import UIKit
#endif

func loadAsset() throws -> SpineMeshAsset {
    let resources = Bundle.main.resourceURL!
    let provider = try SpineAtlasTextureProvider(atlasText: String(contentsOf: resources.appendingPathComponent("swatch.atlas")),
        pageData: ["swatch.png": Data(contentsOf: resources.appendingPathComponent("swatch.png"))])
    return try SpineMeshAsset(json: Data(contentsOf: resources.appendingPathComponent("wardrobe.json")), textures: provider)
}

#if os(macOS)
final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    func applicationDidFinishLaunching(_ notification: Notification) {
        do {
            if let index = CommandLine.arguments.firstIndex(of: "--capture"), index + 1 < CommandLine.arguments.count {
                try captureCompositionEvidence(to: URL(fileURLWithPath: CommandLine.arguments[index + 1]))
                NSApp.terminate(nil); return
            }
            if let index = CommandLine.arguments.firstIndex(of: "--measure"), index + 1 < CommandLine.arguments.count {
                try collectMeasurements(to: URL(fileURLWithPath: CommandLine.arguments[index + 1]))
                NSApp.terminate(nil); return
            }
            if let index = CommandLine.arguments.firstIndex(of: "--workload"), index + 1 < CommandLine.arguments.count {
                let view = SKView(frame: CGRect(x: 0, y: 0, width: 680, height: 520)); view.preferredFramesPerSecond = 60
                let window = NSWindow(contentRect: view.frame, styleMask: [.titled], backing: .buffered, defer: false)
                window.isReleasedWhenClosed = false; window.contentView = view; self.window = window
                let scene = try ScaledWorkloadScene(output: URL(fileURLWithPath: CommandLine.arguments[index + 1]))
                scene.completion = { error in if let error = error { fputs("\(error)\n", stderr); exit(1) }; NSApp.terminate(nil) }
                view.presentScene(scene); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 60) { fputs("Workload timeout\n", stderr); exit(1) }
                return
            }
            let asset = try loadAsset()
            print("Validated \(try Wardrobe.validateAll(asset: asset)) outfits")
            if CommandLine.arguments.contains("--validate-catalog") { NSApp.terminate(nil); return }
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 680, height: 520))
            let window = NSWindow(contentRect: view.frame, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false; window.title = "Skin composition"; window.contentView = view
            let scene = try WardrobeScene(asset: asset)
            if let index = CommandLine.arguments.firstIndex(of: "--native-evidence"), index + 1 < CommandLine.arguments.count {
                let evidence = try NativeEvidenceScene(output: URL(fileURLWithPath: CommandLine.arguments[index + 1]))
                evidence.completion = { error in
                    if let error = error { fputs("\(error)\n", stderr); exit(1) }
                    NSApp.terminate(nil)
                }
                view.presentScene(evidence)
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) { fputs("Native evidence timeout; unlock the desktop and keep window visible\n", stderr); exit(1) }
            } else { view.presentScene(scene) }
            self.window = window
            window.center(); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
            if CommandLine.arguments.contains("--smoke") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    guard scene.preparedFrames > 0 else {
                        fputs("No prepared native frames; active=\(NSApp.isActive), visible=\(window.isVisible), occluded=\(!window.occlusionState.contains(.visible)). Native SKView smoke requires an unlocked desktop and a visible window.\n", stderr)
                        exit(1)
                    }
                    print("Native frames prepared: \(scene.preparedFrames)")
                    NSApp.terminate(nil)
                }
            }
        } catch { fputs("\(error)\n", stderr); exit(1) }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
#else
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        do {
            let asset = CommandLine.arguments.contains("--workload") ? nil : try loadAsset()
            if let asset = asset { _ = try Wardrobe.validateAll(asset: asset) }
            let controller = UIViewController(), view = SKView(frame: UIScreen.main.bounds)
            controller.view = view
            let window = UIWindow(frame: UIScreen.main.bounds); window.rootViewController = controller
            self.window = window; window.makeKeyAndVisible()
            if CommandLine.arguments.contains("--workload") {
                view.preferredFramesPerSecond = 60
                let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("skin-workload.json")
                let status = output.deletingLastPathComponent().appendingPathComponent("skin-workload-status.json")
                let runID = UUID().uuidString
                let build = try JSONSerialization.jsonObject(with: Data(contentsOf: Bundle.main.resourceURL!.appendingPathComponent("build.json")))
                var completed = false
                func record(_ state: String, error: Error? = nil) throws {
                    var value: [String: Any] = ["runID": runID, "state": state, "build": build, "timestamp": Date().timeIntervalSince1970]
                    if let error = error { value["error"] = String(describing: error) }
                    if state == "passed" { value["resultSHA256"] = try evidenceSHA256(output) }
                    try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]).write(to: status, options: .atomic)
                }
                if FileManager.default.fileExists(atPath: output.path) { try FileManager.default.removeItem(at: output) }
                try record("pending")
                do {
                    let scene = try ScaledWorkloadScene(output: output, runID: runID)
                    scene.completion = { error in
                        guard !completed else { return }; completed = true
                        do { try record(error == nil ? "passed" : "failed", error: error) } catch { print(error) }
                    }
                    view.presentScene(scene)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
                        guard !completed else { return }; completed = true
                        do { try record("failed", error: EvidenceError.unavailable("Native workload timeout; keep app visible and device unlocked")) }
                        catch { print(error) }
                    }
                } catch { completed = true; try record("failed", error: error) }
            } else if CommandLine.arguments.contains("--evidence") {
                let output = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("skin-composition")
                try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
                do {
                    try collectMeasurements(to: output.appendingPathComponent("measurements.json"))
                    try captureCompositionEvidence(to: output.appendingPathComponent("paired"))
                    let evidence = try NativeEvidenceScene(output: output.appendingPathComponent("native"))
                    var completed = false
                    evidence.completion = { error in
                        completed = true
                        let result: [String: Any] = ["passed": error == nil, "error": error.map(String.init(describing:)) as Any? ?? NSNull()]
                        do { try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted]).write(to: output.appendingPathComponent("result.json")) }
                        catch { print(error) }
                    }
                    view.presentScene(evidence)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        guard !completed else { return }
                        let result: [String: Any] = ["passed": false, "error": "Native frame timeout; keep the device unlocked and the app visible"]
                        do { try JSONSerialization.data(withJSONObject: result).write(to: output.appendingPathComponent("result.json")) }
                        catch { print(error) }
                    }
                } catch {
                    try JSONSerialization.data(withJSONObject: ["passed": false, "error": String(describing: error)]).write(to: output.appendingPathComponent("result.json"))
                }
            } else if let asset = asset { view.presentScene(try WardrobeScene(asset: asset)) }
        } catch { fatalError("Unable to load fixture: \(error)") }
        return true
    }
}
#endif

@main struct SkinCompositionApp {
    static func main() {
        #if os(macOS)
        let app = NSApplication.shared, delegate = AppDelegate()
        app.setActivationPolicy(.regular); app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
        #else
        UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(AppDelegate.self))
        #endif
    }
}
