#if os(iOS)
import UIKit
#else
import AppKit
#endif
import SpriteKit

private final class DeviceLifecycleScene:SKScene {
    var finishFrame:((Double)->Void)?
    var beforePhysics:(()->Void)?,afterPhysics:(()->Void)?
    private var now=0.0
    override func update(_ currentTime:TimeInterval) {now=currentTime}
    override func didEvaluateActions() {beforePhysics?()}
    override func didSimulatePhysics() {afterPhysics?()}
    override func didFinishUpdate() {finishFrame?(now)}
}
final class DeviceLifecycleGate {
    let view:SKView
    var results=[[String:Any]]()
    init(view:SKView) {self.view=view}
    func run(completion:@escaping(Result<[[String:Any]],Error>)->Void) {
        runNative(actionSpeed:false) {result in
            switch result {
            case .failure(let error):completion(.failure(error))
            case .success(let record):
                self.results.append(record)
                self.runNative(actionSpeed:true) {result in
                    switch result {
                    case .failure(let error):completion(.failure(error))
                    case .success(let record):
                        self.results.append(record)
                        do {self.results.append(try self.reentrantAndConflict());completion(.success(self.results))}
                        catch {completion(.failure(error))}
                    }
                }
            }
        }
    }
    private func runNative(actionSpeed:Bool,completion:@escaping(Result<[String:Any],Error>)->Void) {
        do {
            let asset=try authoredAsset("slot-transitions"),skeleton=try Skeleton(meshAsset:asset)
            let initialBox=skeleton.slotNode(named:"box")!.position
            weak var expectedBody:SKPhysicsBody?=skeleton.slotNode(named:"box")!.physicsBody
            func boxState()->[String:Any] {
                let slot=skeleton.slotNode(named:"box")!,bone=skeleton.boneNode(named:"root")!
                return ["position":[Double(slot.position.x),Double(slot.position.y)],"rotation":Double(slot.zRotation),"scale":[Double(slot.xScale),Double(slot.yScale)],"z":Double(slot.zPosition),"parentIsRoot":slot.parent === bone,"bodyIsExpected":slot.physicsBody != nil && slot.physicsBody === expectedBody,"isDynamic":slot.physicsBody?.isDynamic as Any? ?? NSNull(),"rootPosition":[Double(bone.position.x),Double(bone.position.y)],"rootRotation":Double(bone.zRotation),"ownerPosition":[Double(skeleton.position.x),Double(skeleton.position.y)],"ownerScale":[Double(skeleton.xScale),Double(skeleton.yScale)]]
            }
            let scene=DeviceLifecycleScene(size:CGSize(width:256,height:256));scene.scaleMode = .aspectFit;scene.backgroundColor = .darkGray;scene.addChild(skeleton)
            skeleton.position=CGPoint(x:80,y:80);skeleton.setScale(2)
            let afterPlacement=boxState()
            var beforePhysics=[String:Any](),afterPhysics=[String:Any]()
            scene.beforePhysics={beforePhysics=boxState()};scene.afterPhysics={afterPhysics=boxState()}
            var events=[Int](),phase=0,since=0.0,started:Double?,frozenTime=0.0,frozenDeform=[[Float]]()
            let clip=asset.compiled.clips.first {$0.name=="switches"}!,expected=clip.events.map {$0.value.int}
            skeleton.eventTriggered={events.append($0.int)}
            let action=SKAction.repeat(try skeleton.action(animation:"switches"),count:2)
            if actionSpeed {action.speed=0.5} else {skeleton.speed=0.5}
            skeleton.run(action.copy() as! SKAction,withKey:"clip")
            func done(_ result:Result<[String:Any],Error>) {scene.finishFrame=nil;scene.beforePhysics=nil;scene.afterPhysics=nil;self.view.presentScene(nil);completion(result)}
            scene.finishFrame={now in
                do {
                    if started==nil {started=now}
                    guard now-started!<12 else {throw DeviceValidationFailure("Native lifecycle timed out")}
                    let state=skeleton.meshRuntime!.snapshot
                    switch phase {
                    case 0 where state.time>0.06:
                        try skeleton.apply(skin:"compatible")
                        expectedBody=skeleton.slotNode(named:"box")!.physicsBody
                        frozenDeform=skeleton.meshRuntime!.snapshot.deform;frozenTime=state.time
                        skeleton.isPaused=true;phase=1;since=now
                    case 1:
                        guard state.time==frozenTime,state.deform==frozenDeform else {throw DeviceValidationFailure("Paused pose advanced")}
                        if now-since>0.12 {
                            skeleton.isPaused=false
                            if actionSpeed {skeleton.action(forKey:"clip")!.speed=0} else {skeleton.speed=0}
                            phase=2;since=now
                        }
                    case 2:
                        guard state.time==frozenTime,state.deform==frozenDeform else {throw DeviceValidationFailure("Zero-speed pose advanced")}
                        if now-since>0.12 {
                            if actionSpeed {skeleton.action(forKey:"clip")!.speed=1.5} else {skeleton.speed=1.5}
                            phase=3
                        }
                    case 3 where !skeleton.hasActions():
                        guard state.beginCount==2,state.endCount==2,state.executionID==nil,events==expected+expected,skeleton.meshPlaybackError==nil else {throw DeviceValidationFailure("Repeat boundaries/events/lease differ")}
                        let old=try skeleton.action(animation:"switches");skeleton.stopMeshAnimation(resetToSetupPose:true)
                        skeleton.run(old,withKey:"stale");phase=4;since=now
                    case 4 where now-since>0.08:
                        guard skeleton.meshRuntime!.snapshot.executionID==nil else {throw DeviceValidationFailure("Old epoch action activated")}
                        done(.success(["kind":actionSpeed ? "native-action-speed":"native-node-speed","initialSpeed":0.5,"dynamicSpeeds":[0,1.5],"pausedAndResumed":true,"beginCount":2,"endCount":2,"events":events,"copiedRepeatedAction":true,"compatibleSkinWhilePaused":true,"staleActionInvalidated":true]));return
                    default:break
                    }
                    // Actual native frame preparation, including a moving camera.
                    if scene.camera==nil {let camera=SKCameraNode();scene.addChild(camera);scene.camera=camera}
                    scene.camera!.position=CGPoint(x:128+sin(now)*4,y:128);scene.camera!.zRotation=CGFloat(sin(now)*0.015)
                    try skeleton.prepareMeshes(in:self.view)
                } catch {
                    done(.failure(DeviceValidationFailure(String(describing:error),details:["initialBoxPosition":[Double(initialBox.x),Double(initialBox.y)],"afterPlacement":afterPlacement,"beforePhysics":beforePhysics,"afterPhysics":afterPhysics,"atFailure":boxState(),"phase":phase,"time":skeleton.meshRuntime!.snapshot.time])))
                }
            }
            view.presentScene(scene)
        } catch {completion(.failure(error))}
    }
    func reentrantAndConflict()throws->[String:Any] {
        let result:[String:Any]=try withReleasedDeviceHarness(asset:authoredAsset("slot-transitions")) {h in
        var events=[Int](),restarted=false
        h.skeleton.eventTriggered={ [weak h] event in
            guard let h=h else {return}
            events.append(event.int)
            if !restarted {
                restarted=true;h.skeleton.stopMeshAnimation();h.skeleton.removeAllActions()
                if let action=try? h.skeleton.action(animation:"switches") {h.skeleton.run(action)}
            }
        }
        h.start(try h.skeleton.action(animation:"switches"));h.update(0.05);h.update(0.5)
        guard restarted,h.skeleton.meshRuntime!.snapshot.beginCount==2,h.skeleton.meshPlaybackError==nil else {throw DeviceValidationFailure("Reentrant restart failed")}
        h.skeleton.stopMeshAnimation();h.skeleton.removeAllActions()
        let a=try h.skeleton.action(animation:"switches")
        h.skeleton.run(.group([a,a.copy() as! SKAction]));h.update(0.6)
        guard h.skeleton.meshPlaybackError?.code == .concurrentClip,h.skeleton.meshRuntime!.managedVisuals.isHidden else {throw DeviceValidationFailure("Concurrent owner copies did not fault")}
        h.skeleton.stopMeshAnimation(resetToSetupPose:true);h.skeleton.removeAllActions()
        try h.skeleton.prepareMeshes(for:validMeshContext)
        guard h.skeleton.meshPlaybackError==nil,!h.skeleton.meshRuntime!.managedVisuals.isHidden else {throw DeviceValidationFailure("Conflict recovery failed")}
        return ["kind":"physical-SKRenderer-reentrant-conflict","reentrantRestart":true,"copyConflict":true,"stopRecovery":true,"events":events,"harnessReleasedBeforePerformance":true]
        }
        return result
    }
}

/// Cleanup and release are checked on both success and failure before entering
/// the next stage. The fixture callback itself additionally captures weakly.
func withReleasedDeviceHarness<T>(asset:SpineMeshAsset,_ body:(DeviceActionHarness)throws->T)throws->T {
    weak var observed:DeviceActionHarness?
    let outcome:Result<T,Error>=autoreleasepool {
        do {
            let h=try DeviceActionHarness(asset:asset);observed=h
            defer {h.skeleton.eventTriggered=nil;h.skeleton.removeAllActions();h.renderer.scene=nil}
            return .success(try body(h))
        } catch {return .failure(error)}
    }
    guard observed==nil else {throw DeviceValidationFailure("Reentrant harness retained before performance stage")}
    return try outcome.get()
}
