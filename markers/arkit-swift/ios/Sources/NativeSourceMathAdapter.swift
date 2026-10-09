import UIKit
import SceneKit
import ARKit

/// Newly authored native input/tracking adapter for reviewed original source pixels.
final class NativeSourceMathAdapter {
 let kind:NativeSourceMathKind
 var sine=NativeSineBinding(), summation=NativeSummationBinding()
 var onChange:((String)->Void)?
 var inputAllowed:()->Bool = {true}
 private var label:UILabel?
 private var boundDrag:(upper:Bool,initial:Int,y:Double)?
 init(kind:NativeSourceMathKind) {self.kind=kind}
 var description:String {kind == .sine ? sine.equation : summation.equation+" · "+summation.expansion}
 func referenceImage(directory:URL, fullPageWidth:Double=0.21)->ARReferenceImage? {
  guard let cg=UIImage(contentsOfFile:directory.appendingPathComponent(kind.pageFilename).path)?.cgImage,
   let crop=cg.cropping(to:kind.referenceCrop) else{return nil}
  let image=ARReferenceImage(crop,orientation:.up,physicalWidth:kind.mapping(fullPageWidth:fullPageWidth).targetWidth)
  image.name=kind.rawValue
  return image
 }
 func makeNode()->SCNNode {
  let image=UIGraphicsImageRenderer(size:kind.sourceSize).image {ctx in
   let cg=ctx.cgContext,color=UIColor.systemCyan
   func box(_ r:CGRect){cg.setFillColor(color.withAlphaComponent(0.18).cgColor);cg.fill(r);cg.setStrokeColor(color.cgColor);cg.setLineWidth(3);cg.stroke(r)}
   func text(_ t:String,_ r:CGRect,_ font:CGFloat=20){(t as NSString).draw(in:r,withAttributes:[.font:UIFont.boldSystemFont(ofSize:font),.foregroundColor:color])}
   if kind == .sine {
    if sine.selected {box(NativeSineBinding.equationBox);box(NativeSineBinding.coefficientBox);box(NativeSineBinding.graphBox)
     cg.move(to:CGPoint(x:566,y:1091));cg.addLine(to:CGPoint(x:944,y:1205));cg.strokePath()}
    cg.saveGState();cg.clip(to:NativeSineBinding.graphBox);cg.setStrokeColor(color.cgColor);cg.setLineWidth(4)
    for i in 0...600 {let x = -4.0+Double(i)*0.02,p=sine.sourcePixel(x:x);if i==0 {cg.move(to:p)}else{cg.addLine(to:p)}}
    cg.strokePath();cg.restoreGState();text(sine.equation,CGRect(x:726,y:1440,width:500,height:40),18)
   }else{
    if summation.selected {box(NativeSummationBinding.formulaBox);box(NativeSummationBinding.upperBox);box(NativeSummationBinding.lowerBox)}
    // Live replacements and expansion are adjacent, not an asserted erasure of printed ink.
    text("upper \(summation.upper)  lower \(summation.lower)",CGRect(x:700,y:1190,width:420,height:30),22)
    text(summation.expansion,CGRect(x:700,y:1225,width:420,height:310),summation.terms.count > 20 ? 14 : 19)
    cg.setStrokeColor(color.cgColor);cg.setLineWidth(3);cg.move(to:CGPoint(x:665,y:1215));cg.addLine(to:CGPoint(x:695,y:1215));cg.strokePath()
   }
  }
  let plane=SCNPlane(width:5.7,height:5.7*kind.sourceSize.height/kind.sourceSize.width),material=SCNMaterial()
  material.diffuse.contents=image;material.lightingModel = .constant;material.isDoubleSided=true;material.writesToDepthBuffer=false;plane.materials=[material]
  let root=SCNNode();root.name="science-interaction"
  let node=SCNNode(geometry:plane);node.name="original-source-math-page-overlay";node.eulerAngles.x = -.pi/2;node.position.y=0.01;root.addChildNode(node);return root
 }
 /// Call only after the parent has accepted a real UIKit input on the active tracked page.
 func sourcePixel(texture:CGPoint)->CGPoint {CGPoint(x:texture.x*kind.sourceSize.width,y:(1-texture.y)*kind.sourceSize.height)}
 func sourcePixel(localPlane:SCNVector3)->CGPoint {
  let height=5.7*Double(kind.sourceSize.height)/Double(kind.sourceSize.width)
  return CGPoint(x:(Double(localPlane.x)/5.7+0.5)*Double(kind.sourceSize.width),y:(0.5-Double(localPlane.y)/height)*Double(kind.sourceSize.height))
 }
 func tap(pixel:CGPoint) {
  if kind == .sine {guard NativeSineBinding.equationBox.contains(pixel) || NativeSineBinding.graphBox.contains(pixel) else{return};sine.selected.toggle()}
  else{guard NativeSummationBinding.formulaBox.contains(pixel) else{return};summation.selected.toggle()}
  changed("select-printed-binding")
 }
 func beginDrag(pixel:CGPoint) {
  boundDrag=nil
  guard kind == .summation else{return}
  if NativeSummationBinding.upperBox.insetBy(dx:-10,dy:-7).contains(pixel) {boundDrag=(true,summation.upper,Double(pixel.y))}
  else if NativeSummationBinding.lowerBox.insetBy(dx:-10,dy:-7).contains(pixel){boundDrag=(false,summation.lower,Double(pixel.y))}
 }
 func drag(pixel:CGPoint) {guard let d=boundDrag else{return};summation.dragBound(upper:d.upper,initial:d.initial,sourceDeltaY:Double(pixel.y)-d.y);changed("printed-summation-bound-drag")}
 func endDrag(){boundDrag=nil}
 private func changed(_ input:String) {label?.text=description;onChange?(input)}
 func makeControls()->UIView {
  let stack=UIStackView();stack.axis = .vertical;stack.spacing=4
  let info=UILabel();info.textColor = .white;info.numberOfLines=3;info.font = .systemFont(ofSize:12);info.text=description;label=info;stack.addArrangedSubview(info)
  if kind == .sine {
   let slider=UISlider();slider.minimumValue=0.25;slider.maximumValue=5;slider.value=Float(sine.frequency);slider.accessibilityLabel="Printed sine frequency coefficient";slider.accessibilityIdentifier="SourceSineFrequency";slider.addTarget(self,action:#selector(frequencyChanged(_:)),for:.valueChanged);stack.addArrangedSubview(slider)
  }else{
   for upper in [true,false] {let row=UIStackView();row.axis = .horizontal;row.spacing=12;let title=UILabel();title.textColor = .white;title.text=upper ? "Upper bound" : "Lower bound";row.addArrangedSubview(title)
    let step=UIStepper();step.minimumValue=0;step.maximumValue=100;step.value=Double(upper ? summation.upper:summation.lower);step.tag=upper ? 1:0;step.accessibilityLabel=title.text;step.accessibilityIdentifier=upper ? "SourceSumUpper" : "SourceSumLower";step.addTarget(self,action:#selector(boundChanged(_:)),for:.valueChanged);row.addArrangedSubview(step);stack.addArrangedSubview(row)}
  }
  return stack
 }
 @objc private func frequencyChanged(_ sender:UISlider){guard inputAllowed() else{sender.value=Float(sine.frequency);return};sine.setFrequency(Double(sender.value));changed("UIKit-frequency-slider")}
 @objc private func boundChanged(_ sender:UIStepper){guard inputAllowed() else{sender.value=Double(sender.tag==1 ? summation.upper:summation.lower);return};if sender.tag==1 {summation.setUpper(Int(sender.value))}else{summation.setLower(Int(sender.value))};changed("UIKit-summation-bound-stepper")}
}
