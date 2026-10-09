import UIKit
import SceneKit

/// Companion parts are authored parametric teaching geometry, never claimed as segmented/rigged mesh parts.
final class DomainInteractionAdapter {
 let root:SCNNode,appearance:SCNNode,mechanism=SCNNode()
 let action:String
 var state:DomainInteractionState
 var parts:[SCNNode]=[]
 let sourceAnimator:SourcePartAnimator?
 init(root:SCNNode,appearance:SCNNode,id:String,action:String,directory:URL) {
  self.root=root;self.appearance=appearance;self.action=action
  sourceAnimator=SourcePartAnimator.make(pageID:id,directory:directory)
  if let sourceAnimator {root.addChildNode(sourceAnimator.root)}
  state=DomainInteractionState(id:(id=="original-oct2-printed-car" ? "car" : id).replacingOccurrences(of:"rx-",with:"").replacingOccurrences(of:"primary9-",with:""))
  mechanism.name="authored-companion-mechanism-not-inferred-rig";mechanism.position.y=1.7;root.addChildNode(mechanism)
  let count:Int
  switch action {case "orbit":count=4;case "explode","unzip","bond":count=6;case "count":count=5;case "divide":count=4;case "flow","cycle","pulse","release":count=8;case "field","load":count=5;case "drive","walk","swim":count=4;case "fold":count=state.id=="geometry-net" ? 6 : 2;case "flap","gears","spin":count=2;case "grow","expand":count=6;case "reciprocate","lift","swing","tilt","breathe","story":count=3;default:count=2}
  for i in 0..<count {
   let geometry:SCNGeometry
   switch action {case "fold","flap","count","divide","story":geometry=SCNBox(width:0.45,height:0.06,length:0.45,chamferRadius:0.015)
   case "gears","spin","drive","walk":geometry=SCNCylinder(radius:0.28,height:0.08)
   default:geometry=SCNSphere(radius:0.12)}
   let material=SCNMaterial();material.diffuse.contents=UIColor(hue:(CGFloat(i)*0.17).truncatingRemainder(dividingBy:1),saturation:0.65,brightness:0.95,alpha:0.92);material.lightingModel = .lambert;geometry.materials=[material]
   let node=SCNNode(geometry:geometry);node.name="authored-companion-part-\(i)";mechanism.addChildNode(node);parts.append(node)
  }
  mechanism.isHidden=true // opt-in teaching parts, never default source-object replacement
  update(0)
  evidence("DOMAIN_RUNTIME_CREATED id=\(state.id) action=\(action) parts=\(parts.count) provenance=inferred_unrigged_appearance_plus_explicit_authored_companion_geometry")
 }
 func update(_ dt:Double) {
  if !root.isPaused {state.advance(dt)}
  let p=Float(state.parameter),t=Float(state.phase),s=sin(t)
  mechanism.isHidden=sourceAnimator != nil || state.stage==0 || ["drive","walk","swim"].contains(action)
  appearance.isHidden=sourceAnimator != nil && state.stage != 0
  sourceAnimator?.update(state:state)
  // Rigid-body teaching motion affects the actual inferred appearance too.
  // This is authored kinematics, NOT a learned articulated rig or hidden geometry.
  if ["drive","walk","swim"].contains(action) {
   appearance.position.x=sin(t)*0.7;appearance.position.z=cos(t)*0.25
   appearance.eulerAngles.y=(p-0.5) * .pi/2
  }
  for (i,node) in parts.enumerated() {
   let f=Float(i);node.position=SCNVector3Zero;node.eulerAngles=SCNVector3Zero;node.scale=SCNVector3(1,1,1);node.opacity=1
   switch action {
   case "orbit":let phase=t/(f+1)+f*1.5,r:Float=0.65+f*0.32;node.position=SCNVector3(cos(phase)*r,0,sin(phase)*r)
   case "gears","spin":node.position.x=i==0 ? -0.43 : 0.43;node.scale=SCNVector3(i==0 ? 1 : 2,1,i==0 ? 1 : 2);node.eulerAngles.y=Float(i==0 ? state.gearAngles.0 : state.gearAngles.1)
   case "explode","unzip","bond":
    let a=f * .pi/3,r:Float=0.35+p*0.8;node.position=SCNVector3(cos(a)*r,Float(state.stage)*0.2,sin(a)*r)
    if action=="unzip" {node.position=SCNVector3((i%2==0 ? -1:1)*(0.18+p*0.8),f*0.15-0.4,sin(f)*0.2)}
    node.opacity=state.stage==0 && action=="explode" ? 0.15 : 1
   case "fold","flap":
    let side:Float=i%2==0 ? -1:1;node.position.x=side*0.23;node.position.z=Float(i/2)*0.5;node.eulerAngles.z=side*(Float(state.foldAngle)+(action=="flap" ? s*0.3 : 0))
   case "count":
    let split=state.stage != 0
    node.position=SCNVector3((f-2)*0.3+(split ? (i<2 ? -0.3 : 0.3) : 0),0,0)
   case "divide":node.position=SCNVector3(Float(i%2*2-1)*(state.stage==0 ? 0.23 : 0.23+p),0,Float(i/2*2-1)*(state.stage==0 ? 0.23 : 0.23+p))
   case "flow","cycle","pulse","release":
    let v=(t*0.15+f/8).truncatingRemainder(dividingBy:1);node.position=SCNVector3((v-0.5)*2.7,action=="cycle" ? sin(v*2 * .pi)*0.6 : (action=="release" ? v*0.6 : 0),0)
    if state.id=="heart" {node.scale=SCNVector3(1+0.3*s,1+0.3*s,1+0.3*s)}
   case "field","load":node.position=SCNVector3((f-2)*0.45,-p*0.45,0);node.scale=SCNVector3(0.3,0.3,1+3*p);node.opacity=state.stage==0 ? 0.15 : 1
   case "drive","walk","swim":node.position=SCNVector3(i<2 ? -0.9 : 0.9,0,i%2==0 ? -0.45 : 0.45);node.eulerAngles.x=t;mechanism.position.x=sin(t)*0.7;mechanism.eulerAngles.y=(p-0.5) * .pi/2
   case "grow","expand":node.position=SCNVector3(cos(f * .pi/3)*p,0.25*f*p,sin(f * .pi/3)*p);node.scale=SCNVector3(0.15+p,0.15+p,0.15+p)
   case "reciprocate":node.position=SCNVector3((f-1)*0.4,s*0.7,0)
   case "lift":node.position=SCNVector3((f-1)*0.3,p*1.2,0)
   case "swing","tilt":node.position=SCNVector3(sin(s*p)*(f+1)*0.4,-cos(s*p)*(f+1)*0.4,0);if action=="tilt" {node.position.y=(p-0.5)*(f-1)}
   case "breathe":node.position.x=(f-1)*0.5;node.scale=SCNVector3(0.5+p,0.5+p,0.5+p)
   case "story":node.opacity=i==state.stage ? 1 : 0.15;node.position=SCNVector3((f-1)*0.9,Float(state.stage)*0.2,0)
   default:node.position=SCNVector3((f-0.5)*0.6,0,0)
   }
  }
 }
 func parameter(_ delta:Double) {state.setParameter(state.parameter+delta);update(0);evidence("DOMAIN_INPUT id=\(state.id) parameter=\(state.parameter) input=UIKit")}
 func event() {if ["drive","walk","swim"].contains(action) {state.reset()}else{state.event()};update(0);evidence("DOMAIN_INPUT id=\(state.id) stage=\(state.stage) input=UIKit")}
 func reset() {state.reset();update(0)}
 var description:String {
  if let sourceAnimator {return sourceAnimator.parameterDescription(state:state)+" · "+sourceAnimator.modeDescription(state:state)}
  return state.label+" · authored mechanism, not inferred rig"
 }
}
