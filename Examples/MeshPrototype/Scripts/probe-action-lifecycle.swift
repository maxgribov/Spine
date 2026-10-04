// Standalone native-SKView investigation, not production runtime or a passing test.
// Run from repository root: swift Examples/MeshPrototype/Scripts/probe-action-lifecycle.swift
// Opens a temporary window and exits after 90 native updates (10-second timeout).
// Prints raw observations; repeated zero-duration callbacks are the issue under study.
import AppKit
import SpriteKit
final class ProbeScene: SKScene {
 var tick = 0
 let slow = SKNode(), changing = SKNode()
 var begins = 0, ends = 0
 override func didMove(to view: SKView) {
  addChild(slow); addChild(changing)
  slow.speed = 0.5
  slow.run(.repeat(.sequence([
   .customAction(withDuration: 0) { [weak self] _,t in guard let s=self else{return};s.begins+=1;print("begin",s.tick,t) },
   .customAction(withDuration: 0.2) { [weak self] _,t in if t>0.19 {print("slow-final",self?.tick ?? -1,t)} },
   .customAction(withDuration: 0) { [weak self] _,t in guard let s=self else{return};s.ends+=1;print("end",s.tick,t) }
  ]),count:2))
  changing.run(.customAction(withDuration: 2) { [weak self] _,t in if let s=self, (s.tick < 5 || (8...24).contains(s.tick)) {print("dynamic",s.tick,t)} })
 }
 override func update(_ currentTime: TimeInterval) {
  tick += 1
  if tick==10 {changing.speed=0.5}
  if tick==20 {changing.speed=1}
  if tick==90 {print("RESULT",begins,ends);exit(0)}
 }
}
let app=NSApplication.shared
app.setActivationPolicy(.regular)
let window=NSWindow(contentRect:CGRect(x:0,y:0,width:256,height:256),styleMask:[.titled,.closable],backing:.buffered,defer:false)
window.title="Spine lifecycle probe"
let view=SKView(frame:window.contentView!.bounds);window.contentView=view
let scene=ProbeScene(size:CGSize(width:256,height:256));view.presentScene(scene)
window.makeKeyAndOrderFront(nil);app.activate(ignoringOtherApps:true)
DispatchQueue.main.asyncAfter(deadline:.now()+10){print("TIMEOUT");exit(2)}
app.run()
