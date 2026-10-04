import UIKit
import SpriteKit

final class DeviceReleaseCoordinator {
    private let view:SKView,label:UILabel
    private var lifecycle:DeviceLifecycleGate?,performance:DevicePerformanceGate?
    private var report:[String:Any]=["phase":5,"status":"running","parity":"requires external pinned4.1.56 comparison of exported snapshots","build":"Release -O whole-module-optimization","nativeWarmupFrames":30,"nativeMeasuredFrames":120,"offscreenWarmupFrames":30,"offscreenMeasuredFrames":60,"callbackFPSIsPresentedFPS":false]
    init(view:SKView,label:UILabel) {self.view=view;self.label=label}
    func start() {
        report["os"]=UIDevice.current.systemVersion;report["device"]=UIDevice.current.model
        do {
            label.text="Checking 9000 corrected physics updates…"
            try DevicePhysicsStress().run()
            try DeviceRunContext.current!.markCompleted("physics-stress")
            report["physicsStressFrames"]=9000
            label.text="Exporting all223 animation poses…"
            try DeviceAnimationOracle().run();report["oracleSnapshotsExported"]=223
            try DeviceRunContext.current!.markCompleted("parity-export")
            let asset=try authoredAsset("slot-transitions")
            var released=0
            for _ in 0..<100 {
                weak var weakOwner:Skeleton?
                try autoreleasepool {
                    let owner=try Skeleton(meshAsset:asset);weakOwner=owner
                    try owner.apply(skin:"compatible");try owner.apply(skin:"incompatible")
                    owner.run(try owner.action(animation:"switches"));owner.stopMeshAnimation();owner.removeAllActions()
                }
                if weakOwner==nil {released+=1}
            }
            guard released==100 else {throw DeviceValidationFailure("Device owner lifetime leak")}
            report["releasedOwnersAfter100SkinCycles"]=released
            try DeviceRunContext.current!.markCompleted("lifetime")
            label.text="Native pause / speed / repeat / skins…"
            let lifecycle=DeviceLifecycleGate(view:view);self.lifecycle=lifecycle
            lifecycle.run {result in
                switch result {
                case .failure(let error):self.finish(error)
                case .success(let results):
                    self.report["lifecycle"]=results
                    do {
                        try DeviceRunContext.current!.markCompleted("lifecycle")
                        let performance=try DevicePerformanceGate(view:self.view);self.performance=performance
                        performance.run(progress:{self.label.text=$0}) {result in
                            switch result {
                            case .failure(let error):self.finish(error)
                            case .success(let results):self.report["performance"]=results;self.finish(nil)
                            }
                        }
                    } catch {self.finish(error)}
                }
            }
        } catch {finish(error)}
    }
    private func finish(_ error:Error?) {
        view.presentScene(nil)
        let context=DeviceRunContext.current!
        do {
            if let error=error {
                report["status"]="failed";report["error"]=String(describing:error)
                if let details=(error as? DeviceValidationFailure)?.details {report["diagnostics"]=details}
                try deviceReport("release-gate.json",payload:report,status:"failed")
                try context.fail(error);label.text="FAIL: \(error)"
            } else {
                try context.markCompleted("performance")
                report["status"]="device checks passed; external oracle pending"
                try deviceReport("release-gate.json",payload:report)
                try context.complete();label.text="Device checks passed. Oracle export ready."
            }
        } catch {
            label.text="REPORT FAILURE: \(error)";print("Device validation/report failed",error)
            do {try context.fail(error)} catch {print("Could not persist failed run",error)}
        }
        UIApplication.shared.isIdleTimerDisabled=false
        lifecycle=nil;performance=nil
    }
}
