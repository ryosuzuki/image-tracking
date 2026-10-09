import UIKit
import SceneKit
import ARKit

/// Shared input bridge keeps existing sine/sum input and tracking gates intact.
protocol NativeBoundMath:AnyObject {
 var pageID:String {get}
 var description:String {get}
 var interactionInstructions:String {get}
 var onChange:((String)->Void)? {get set}
 var inputAllowed:(()->Bool) {get set}
 func makeNode()->SCNNode
 func makeControls()->UIView
 func sourcePixel(localPlane:SCNVector3)->CGPoint
 func tap(pixel:CGPoint)
 func beginDrag(pixel:CGPoint)
 func drag(pixel:CGPoint)
 func endDrag()
}
extension NativeSourceMathAdapter:NativeBoundMath {
 var pageID:String {kind.rawValue}
 var interactionInstructions:String {kind == .sine ? "Original printed sine · frequency slider changes cyan curve / period" : "Original Σ · edit upper/lower bounds or drag printed bounds · concrete terms follow"}
}
/// Newly authored Pythagorean relationships over the exact original Figure 0.2.
final class NativeTriangleAdapter:NativeBoundMath {
 let pageID=NativeTriangleBinding.pageID
 var model=NativeTriangleBinding()
 var onChange:((String)->Void)?
 var inputAllowed:()->Bool = {true}
 private var dragHorizontal:Bool?
 private var sliders:[UISlider]=[]
 private var label:UILabel?
 var description:String {model.equation+" · normalized illustrative units"}
 var interactionInstructions:String {"Original Figure 0.2 · drag a/b vertices or edit legs / angle · c follows Pythagoras · black print remains reference"}
 func referenceImage(directory:URL,fullPageWidth:Double=0.21)->ARReferenceImage? {
  guard let cg=UIImage(contentsOfFile:directory.appendingPathComponent("original-math-triangle.jpg").path)?.cgImage,let crop=cg.cropping(to:NativeTriangleBinding.referenceCrop) else{return nil}
  let ref=ARReferenceImage(crop,orientation:.up,physicalWidth:NativeTriangleBinding.mapping(fullPageWidth:fullPageWidth).targetWidth);ref.name=pageID;return ref
 }
 func makeNode()->SCNNode {
  let size=NativeTriangleBinding.sourceSize
  let image=UIGraphicsImageRenderer(size:size).image {ctx in
   let cg=ctx.cgContext,color=UIColor.systemCyan,p=model.left,q=model.upper,r=NativeTriangleBinding.corner
   cg.setStrokeColor(color.cgColor);cg.setLineWidth(4)
   cg.move(to:p);cg.addLine(to:r);cg.addLine(to:q);cg.closePath();cg.strokePath()
   cg.move(to:CGPoint(x:r.x-16,y:r.y));cg.addLine(to:CGPoint(x:r.x-16,y:r.y-16));cg.addLine(to:CGPoint(x:r.x,y:r.y-16));cg.strokePath()
   cg.setFillColor(color.cgColor);for v in [p,q] {cg.fillEllipse(in:CGRect(x:v.x-9,y:v.y-9,width:18,height:18))}
   if model.selected {cg.setFillColor(color.withAlphaComponent(0.18).cgColor);cg.fill(NativeTriangleBinding.formulaBox);cg.stroke(NativeTriangleBinding.formulaBox)}
   func text(_ t:String,_ p:CGPoint){(t as NSString).draw(at:p,withAttributes:[.font:UIFont.boldSystemFont(ofSize:18),.foregroundColor:color])}
   text(String(format:"a %.3f",model.a),CGPoint(x:(p.x+r.x)/2-30,y:r.y+12))
   text(String(format:"b %.3f",model.b),CGPoint(x:r.x+12,y:(q.y+r.y)/2))
   text(String(format:"c %.3f",model.c),CGPoint(x:(p.x+q.x)/2-65,y:(p.y+q.y)/2-30))
   text(String(format:"θ %.1f°",model.angleDegrees),CGPoint(x:p.x+20,y:p.y-28))
   text("Normalized units · cyan controlled / black printed",CGPoint(x:530,y:1270))
  }
  let plane=SCNPlane(width:5.7,height:5.7*size.height/size.width),m=SCNMaterial();m.diffuse.contents=image;m.lightingModel = .constant;m.isDoubleSided=true;m.writesToDepthBuffer=false;plane.materials=[m]
  let root=SCNNode();root.name="science-interaction";let node=SCNNode(geometry:plane);node.name="original-source-math-page-overlay";node.eulerAngles.x = -.pi/2;node.position.y=0.01;root.addChildNode(node);return root
 }
 func sourcePixel(localPlane p:SCNVector3)->CGPoint {let s=NativeTriangleBinding.sourceSize;return CGPoint(x:(Double(p.x)/5.7+0.5)*Double(s.width),y:(0.5-Double(p.y)/(5.7*Double(s.height)/Double(s.width)))*Double(s.height))}
 func tap(pixel:CGPoint){guard NativeTriangleBinding.formulaBox.contains(pixel) else{return};model.selected.toggle();changed("select-printed-Pythagoras")}
 func beginDrag(pixel:CGPoint){dragHorizontal=nil;if hypot(pixel.x-model.left.x,pixel.y-model.left.y)<35 {dragHorizontal=true}else if hypot(pixel.x-model.upper.x,pixel.y-model.upper.y)<35 {dragHorizontal=false}}
 func drag(pixel:CGPoint){guard let horizontal=dragHorizontal else{return};model.drag(horizontal:horizontal,pixel:pixel);changed(horizontal ? "printed-a-vertex-drag":"printed-b-vertex-drag")}
 func endDrag(){dragHorizontal=nil}
 func makeControls()->UIView {
  sliders=[];let stack=UIStackView();stack.axis = .vertical;stack.spacing=4
  let info=UILabel();info.textColor = .white;info.numberOfLines=3;info.font = .systemFont(ofSize:12);label=info;stack.addArrangedSubview(info)
  for (i,title) in ["Leg a (normalized)","Leg b (normalized)","Angle θ (degrees)"].enumerated(){let slider=UISlider();slider.tag=i;slider.minimumValue=i==2 ? 1:0.2;slider.maximumValue=i==2 ? 89:2.2;slider.accessibilityLabel=title;slider.accessibilityIdentifier=["SourceTriangleA","SourceTriangleB","SourceTriangleAngle"][i];slider.addTarget(self,action:#selector(input(_:)),for:.valueChanged);stack.addArrangedSubview(slider);sliders.append(slider)}
  sync();return stack
 }
 private func sync(){label?.text=description;if sliders.count==3 {sliders[2].minimumValue=Float(atan2(0.2,model.a)*180 / .pi);sliders[2].maximumValue=Float(atan2(2.2,model.a)*180 / .pi)};let values=[model.a,model.b,model.angleDegrees];for (slider,value) in zip(sliders,values){slider.value=Float(value)}}
 private func changed(_ input:String){sync();onChange?(input)}
 @objc private func input(_ slider:UISlider){guard inputAllowed() else{sync();return};switch slider.tag {case 0:model.setA(Double(slider.value));case 1:model.setB(Double(slider.value));default:model.setAngle(Double(slider.value))};changed("UIKit-triangle-"+["a","b","angle"][slider.tag]+"-slider")}
}
