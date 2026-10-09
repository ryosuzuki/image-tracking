import AppKit
import Foundation
guard CommandLine.arguments.count==2 else{fputs("Usage: WorksheetPresenter /absolute/task-owned/target-directory\n",stderr);exit(2)}
let root=CommandLine.arguments[1]
let app=NSApplication.shared
app.setActivationPolicy(.regular)
let menu=NSMenu(),appItem=NSMenuItem();menu.addItem(appItem);let appMenu=NSMenu();appMenu.addItem(NSMenuItem(title:"Quit Worksheet Presenter",action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q"));appItem.submenu=appMenu;app.mainMenu=menu
let screen=NSScreen.main!
let win=NSWindow(contentRect:screen.frame,styleMask:[.borderless],backing:.buffered,defer:false)
win.title="Interactive Paper Lesson Targets"
win.backgroundColor = .white
win.level = .floating
win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
print("SCREENS "+NSScreen.screens.map{String(describing:$0.frame)}.joined(separator:";"));fflush(stdout)
final class TargetView:NSView {
 var state=[String:Any]()
 override func draw(_ rect:NSRect){NSColor.white.setFill();bounds.fill()
  let width=state["width"] as? Double ?? 600.0
  let dx=state["dx"] as? Double ?? 0.0
  let dy=state["dy"] as? Double ?? 0.0
  let angle=state["angle"] as? Double ?? 0.0
  let file=state["file"] as? String ?? ""
  guard width.isFinite,dx.isFinite,dy.isFinite,angle.isFinite,width>=0 else{return}
  if !file.isEmpty,let image=NSImage(contentsOfFile:root+"/"+file){
   NSGraphicsContext.saveGraphicsState();let t=NSAffineTransform();t.translateX(by:bounds.midX+dx,yBy:bounds.midY+dy);t.rotate(byDegrees:angle);t.concat()
   image.draw(in:NSRect(x:-width/2,y:-width/2,width:width,height:width));
   let lesson=state["lesson"] as? String ?? ""; if !lesson.isEmpty {let attrs:[NSAttributedString.Key:Any]=[.font:NSFont.boldSystemFont(ofSize:width/28),.foregroundColor:NSColor.black]; lesson.draw(in:NSRect(x:-width*0.31,y:-width*0.14,width:width*0.62,height:width*0.3),withAttributes:attrs)}
   if state["mask"] as? Bool == true || (state["maskMode"] as? Int ?? 0)>0 {NSColor.white.setFill();NSRect(x:-width/2,y:width * 0.20,width:width * 0.38,height:width * 0.30).fill()}
   if (state["maskMode"] as? Int ?? 0)>1 {NSColor.white.setFill();NSRect(x:width * 0.12,y:width * 0.20,width:width * 0.38,height:width * 0.30).fill()}
   NSGraphicsContext.restoreGraphicsState()
  }
  let title=state["label"]as?String ?? "Preparing optical target"
  title.draw(at:NSPoint(x:40,y:40),withAttributes:[.font:NSFont.systemFont(ofSize:25),.foregroundColor:NSColor.darkGray])
 }
}
let view=TargetView(frame:screen.frame)
win.contentView=view
win.makeKeyAndOrderFront(nil)
win.orderFrontRegardless()
app.activate(ignoringOtherApps:true)
var previous=""
Timer.scheduledTimer(withTimeInterval:0.05,repeats:true){_ in
 if let data=try? Data(contentsOf:URL(fileURLWithPath:root+"/state.json")),let s=String(data:data,encoding:.utf8),s != previous {
  previous=s
  if let q=try? JSONSerialization.jsonObject(with:data)as? [String:Any]{view.state=q;view.needsDisplay=true
   let event:[String:Any] = ["state":q,"appliedWallUnix":Date().timeIntervalSince1970]
   if let b=try? JSONSerialization.data(withJSONObject:event),let text=String(data:b,encoding:.utf8){print(text);fflush(stdout)}}
 }
}
Timer.scheduledTimer(withTimeInterval:14400,repeats:false){_ in win.close();app.terminate(nil)}
app.run()
