import UIKit
import SceneKit

/// Transparent page-normal overlay on actual printed pixels; no inferred general physics parser.
final class SourceDiagramPhysicsAdapter {
 let root=SCNNode(),kind:String,spec:SourceDiagramProvenance,size:CGSize,sprite:UIImage?
 let material=SCNMaterial()
 var lens=SourceThinLens(),circuit=SourceSeriesCircuit(),pendulum=SourceNonlinearPendulum(),time=0.0
 var history:[CGPoint]=[]
 var overlayVisible=true
 func compareReference(){overlayVisible.toggle();root.childNodes.forEach{$0.isHidden = !overlayVisible};evidence("SOURCE_DIAGRAM_REFERENCE_COMPARE overlay=\(overlayVisible) original_page_immutable=true")}
 init?(kind:String,directory:URL){
  guard let d=try? Data(contentsOf:directory.appendingPathComponent("original-physics-\(kind)-provenance.json")),let spec=try? JSONDecoder().decode(SourceDiagramProvenance.self,from:d),spec.validate(directory:directory),let page=spec.verifiedData(spec.page,directory:directory),let image=UIImage(data:page),image.size.width==spec.sourceSize[0],image.size.height==spec.sourceSize[1] else{evidence("SOURCE_DIAGRAM_LINEAGE_REJECT kind=\(kind)");return nil}
  self.kind=kind;self.spec=spec;size=image.size
  if let cutout=spec.cutout,let data=spec.verifiedData(cutout,directory:directory) {sprite=UIImage(data:data)}else{sprite=nil}
  let plane=SCNPlane(width:5.7,height:5.7*size.height/size.width);material.lightingModel = .constant;material.isDoubleSided=true;material.writesToDepthBuffer=false;plane.materials=[material]
  let node=SCNNode(geometry:plane);node.name="original-source-physics-overlay";node.eulerAngles.x = -.pi/2;node.position.y=0.025;root.name="science-interaction";root.addChildNode(node);draw()
  evidence("SOURCE_DIAGRAM_LOADED kind=\(kind) sourceSHA=\(spec.page.sha256) alpha=official_SAM2_sourceRGB pageNormal=+Y authored_fixture=true calibrated=false generalMNA=false OCR=false")
 }
 var titles:[String] {switch kind {case "optics":return ["Object left 25 px","Focal +10 px","Reset printed fixture","Original / overlay"];case "circuit":return ["Voltage +25 V","R1 +100 Ω","R2 +100 Ω","Original / overlay"];default:return ["Amplitude +10°","Length +0.25 m","Reset paper angle","Original / overlay"]}}
 var description:String {switch kind {case "optics":let s=lens.solution;return s.atFocus ? "Thin lens: object at focus · image at infinity" : String(format:"Thin lens f %.0f px · object %.0f px · %@ · m %.2f",lens.focal,lens.objectX,s.magnification!<0 ? "real inverted":"virtual upright",s.magnification!);case "circuit":return String(format:"Prepared series: %.0f V · %.0f + %.0f Ω · I %.3f A · drops %.1f + %.1f V",circuit.voltage,circuit.r1,circuit.r2,circuit.current,circuit.drops[0],circuit.drops[1]);default:return String(format:"Nonlinear pendulum: L %.2f m · θ %.1f° · t %.2f s · authored SI scale",pendulum.length,pendulum.angle*180 / .pi,pendulum.time)}}
 func primaryControl(){switch kind {case "optics":lens.setObjectX(lens.objectX-25);case "circuit":circuit.setVoltage(circuit.voltage>=200 ? 0:circuit.voltage+25);default:pendulum.setAmplitude(abs(pendulum.initialAngle)*180 / .pi+10);history=[]};draw()}
 func secondaryControl(){switch kind {case "optics":lens.setFocal(lens.focal>=220 ? 30:lens.focal+10);case "circuit":circuit.setR1(circuit.r1>=1000 ? 100:circuit.r1+100);default:pendulum.setLength(pendulum.length>=3 ? 0.5:pendulum.length+0.25);pendulum.reset();history=[]};draw()}
 func tertiaryControl(){if kind=="circuit" {circuit.setR2(circuit.r2>=1000 ? 100:circuit.r2+100);draw()}else{reset()}}
 var interactionInstructions:String {kind=="circuit" ? "Prepared series only · change V / R1 / R2 · drag resistors or battery · reset / pause · not OCR or general MNA" : kind=="optics" ? "Exact source tree · drag object / change focal length · source-pixel thin lens · original / overlay" : "Exact source bob · drag amplitude / change SI length · nonlinear RK4 + θ(t) · authored scale"}
 func reset(){lens=SourceThinLens();circuit=SourceSeriesCircuit();pendulum=SourceNonlinearPendulum();time=0;history=[];draw()}
 func update(_ dt:Double){guard !root.isPaused,dt.isFinite,dt>0 else{return};time += min(dt,0.1);if kind=="pendulum" {pendulum.advance(dt);history.append(CGPoint(x:pendulum.time,y:pendulum.angle));history=history.filter{pendulum.time-Double($0.x)<6}};draw()}
 func sourcePixel(_ local:SCNVector3)->CGPoint {CGPoint(x:(Double(local.x)/5.7+0.5)*size.width,y:(0.5-Double(local.y)/(5.7*size.height/size.width))*size.height)}
 func drag(pixel:CGPoint){switch kind {case "optics":guard (450...690).contains(pixel.y) else{return};lens.setObjectX(Double(pixel.x));case "circuit":if (260...355).contains(pixel.y) {if pixel.x>320 {circuit.setR2((Double(pixel.x)-320)/190*1000)}else{circuit.setR1((Double(pixel.x)-125)/195*1000)}}else{circuit.setVoltage(Double(pixel.x)/size.width*200)};default:let a=atan2(Double(pixel.x)-259,Double(pixel.y)-61)*180 / .pi;pendulum.setSignedAmplitude(a);history=[]};draw()}
 private func draw(){
  let format=UIGraphicsImageRendererFormat();format.scale=1;format.opaque=false
  material.diffuse.contents=UIGraphicsImageRenderer(size:size,format:format).image {ctx in
   let cg=ctx.cgContext
   func line(_ pts:[CGPoint],_ color:UIColor,_ dash:Bool=false,_ width:CGFloat=2){guard let first=pts.first else{return};cg.saveGState();cg.setStrokeColor(color.cgColor);cg.setLineWidth(width);if dash{cg.setLineDash(phase:0,lengths:[6,5])};cg.move(to:first);for p in pts.dropFirst(){cg.addLine(to:p)};cg.strokePath();cg.restoreGState()}
   func text(_ s:String,_ p:CGPoint,_ font:CGFloat=14){(s as NSString).draw(at:p,withAttributes:[.font:UIFont.monospacedSystemFont(ofSize:font,weight:.medium),.foregroundColor:UIColor.systemBlue])}
   func dot(_ p:CGPoint,_ color:UIColor,_ r:CGFloat=4){cg.setFillColor(color.cgColor);cg.fillEllipse(in:CGRect(x:p.x-r,y:p.y-r,width:r*2,height:r*2))}
   if kind=="optics" {
    let x=lens.objectX,y=lens.axisY-lens.objectHeight,s=lens.solution
    // Derived white silhouette cover only: this is not erasure of physical ink.
    if let sprite,let crop=spec.crop {let rect=CGRect(x:crop[0],y:crop[1],width:crop[2],height:crop[3]);cg.saveGState();sprite.draw(in:rect);cg.setBlendMode(.sourceIn);cg.setFillColor(UIColor.white.cgColor);cg.fill(rect);cg.restoreGState();sprite.draw(in:CGRect(x:x+crop[0]-350,y:crop[1],width:crop[2],height:crop[3]))
     if let m=s.magnification,let ix=s.imageX,abs(m)<10 {cg.saveGState();cg.translateBy(x:ix,y:567);cg.scaleBy(x:abs(m),y:m);sprite.draw(in:CGRect(x:crop[0]-350,y:crop[1]-567,width:crop[2],height:crop[3]));cg.restoreGState()}
    }
    line([CGPoint(x:x,y:y),CGPoint(x:653,y:y),CGPoint(x:1000,y:y+347*80/lens.focal)],.systemGreen)
    line([CGPoint(x:x,y:y),CGPoint(x:653,y:567),CGPoint(x:1000,y:567+347*80/(653-x))],.systemBlue)
    if let m=s.magnification,m>0,let ix=s.imageX,let iy=s.imageY {line([CGPoint(x:653,y:y),CGPoint(x:ix,y:iy)],.systemGreen,true);line([CGPoint(x:653,y:567),CGPoint(x:ix,y:iy)],.systemBlue,true)}
    for f in [653-lens.focal,653+lens.focal] {dot(CGPoint(x:f,y:567),.systemRed)};text(description,CGPoint(x:290,y:685),16)
   }else if kind=="circuit" {
    for (p,s) in [(CGPoint(x:170,y:306),"\(Int(circuit.r1)) Ω"),(CGPoint(x:380,y:306),"\(Int(circuit.r2)) Ω"),(CGPoint(x:206,y:405),"\(Int(circuit.voltage)) V")] {cg.setFillColor(UIColor.white.cgColor);cg.fill(CGRect(x:p.x-2,y:p.y-2,width:110,height:30));text(s,p,23)}
    let path=[CGPoint(x:147,y:388),CGPoint(x:147,y:294),CGPoint(x:475,y:294),CGPoint(x:475,y:388),CGPoint(x:147,y:388)],lengths=[94.0,328,94,328]
    for i in 0..<12 {var d=(time*circuit.current*100+Double(i)*844/12).truncatingRemainder(dividingBy:844);for j in 0..<4 {if d<=lengths[j] {let u=d/lengths[j];dot(CGPoint(x:path[j].x+u*(path[j+1].x-path[j].x),y:path[j].y+u*(path[j+1].y-path[j].y)),.systemCyan);break};d-=lengths[j]}}
    text(String(format:"I %.3f A · %.1f + %.1f V",circuit.current,circuit.drops[0],circuit.drops[1]),CGPoint(x:100,y:450),18);text("Authored charge markers · not electron speed",CGPoint(x:80,y:482),14)
   }else {
    let bob=CGPoint(x:pendulum.bobPixel[0],y:pendulum.bobPixel[1]),pivot=CGPoint(x:259,y:61)
    // Explicit derived white cover along the original rod/bob. Original source image remains immutable.
    line([pivot,CGPoint(x:157,y:254)],.white,false,5)
    if let sprite,let crop=spec.crop {cg.setFillColor(UIColor.white.cgColor);cg.fill(CGRect(x:crop[0]-1,y:crop[1]-1,width:crop[2]+2,height:crop[3]+2));sprite.draw(in:CGRect(x:bob.x+crop[0]-157,y:bob.y+crop[1]-254,width:crop[2],height:crop[3]))}
    line([pivot,bob],.systemBlue)
    let plot=CGRect(x:15,y:75,width:105,height:100);line([CGPoint(x:plot.minX,y:plot.minY),CGPoint(x:plot.minX,y:plot.maxY),CGPoint(x:plot.maxX,y:plot.maxY)],.systemGray)
    let pts=history.map{CGPoint(x:plot.minX+(Double($0.x)-max(0,pendulum.time-6))/6*plot.width,y:plot.midY-Double($0.y)/(Double.pi/2)*45)};line(pts,.systemOrange);text("θ(t), 6 s",CGPoint(x:15,y:180),11);text(String(format:"L %.2f m · θ %.1f°",pendulum.length,pendulum.angle*180 / .pi),CGPoint(x:15,y:315),12)
   }
  }
 }
}
