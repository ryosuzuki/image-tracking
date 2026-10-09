import AppKit
import Foundation
let root="/tmp/openclaw/quest-marker-stage"
let app=NSApplication.shared
app.setActivationPolicy(.regular)
let screen=NSScreen.main!
let win=NSWindow(contentRect:screen.frame,styleMask:[.borderless],backing:.buffered,defer:false)
win.title="Quest Marker Optical Targets"
win.backgroundColor = .white
final class TargetView:NSView {
 var state=[String:Any]()
 override func draw(_ rect:NSRect){NSColor.white.setFill();bounds.fill()
  let width=state["width"] as? Double ?? 600.0
  let dx=state["dx"] as? Double ?? 0.0
  let angle=state["angle"] as? Double ?? 0.0
  let file=state["file"] as? String ?? ""
  if !file.isEmpty,let image=NSImage(contentsOfFile:"/tmp/openclaw/quest-marker-stage/"+file){
   NSGraphicsContext.saveGraphicsState();let t=NSAffineTransform();t.translateX(by:bounds.midX+dx,yBy:bounds.midY);t.rotate(byDegrees:angle);t.concat()
   image.draw(in:NSRect(x:-width/2,y:-width/2,width:width,height:width));
   if state["mask"] as? Bool == true {NSColor.white.setFill();NSRect(x:-width/2,y:width * 0.20,width:width * 0.38,height:width * 0.30).fill()}
   NSGraphicsContext.restoreGraphicsState()
  }
  let title=state["label"]as?String ?? "Preparing optical target"
  title.draw(at:NSPoint(x:40,y:40),withAttributes:[.font:NSFont.systemFont(ofSize:25),.foregroundColor:NSColor.darkGray])
 }
}
let view=TargetView(frame:screen.frame)
win.contentView=view
win.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps:true)
var previous=""
Timer.scheduledTimer(withTimeInterval:0.05,repeats:true){_ in
 if let data=try? Data(contentsOf:URL(fileURLWithPath:root+"/state.json")),let s=String(data:data,encoding:.utf8),s != previous {
  previous=s
  if let q=try? JSONSerialization.jsonObject(with:data)as? [String:Any]{view.state=q;view.needsDisplay=true}
 }
}
Timer.scheduledTimer(withTimeInterval:83,repeats:false){_ in win.close();app.terminate(nil)}
app.run()
