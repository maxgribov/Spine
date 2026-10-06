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
            if let index = CommandLine.arguments.firstIndex(of: "--measure"), index + 1 < CommandLine.arguments.count {
                try collectMeasurements(to: URL(fileURLWithPath: CommandLine.arguments[index + 1]))
                NSApp.terminate(nil); return
            }
            let asset = try loadAsset()
            print("Validated \(try Wardrobe.validateAll(asset: asset)) outfits")
            if CommandLine.arguments.contains("--validate-catalog") { NSApp.terminate(nil); return }
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 680, height: 520))
            let window = NSWindow(contentRect: view.frame, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false; window.title = "Skin composition"; window.contentView = view
            let scene = try WardrobeScene(asset: asset)
            view.presentScene(scene); self.window = window
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
            let asset = try loadAsset(); _ = try Wardrobe.validateAll(asset: asset)
            let controller = UIViewController(), view = SKView(frame: UIScreen.main.bounds)
            controller.view = view
            let window = UIWindow(frame: UIScreen.main.bounds); window.rootViewController = controller
            self.window = window; window.makeKeyAndVisible()
            view.presentScene(try WardrobeScene(asset: asset))
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
