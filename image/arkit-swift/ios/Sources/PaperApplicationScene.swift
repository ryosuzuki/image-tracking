import Foundation
/// Authored graph coordinates; anisotropic scales deliberately fit a120mm teaching card.
struct PaperGraphPlot {
 let coefficient:Double
 let xScale=0.018
 var yRange:Double{max(abs(coefficient),0.25)*4}
 var yScale:Double{min(0.018,0.048/yRange)}
 func point(_ x:Double)->SIMD2<Double>{SIMD2(x*xScale,-coefficient*x*x*yScale)}
 func tangent(_ x:Double)->(SIMD2<Double>,SIMD2<Double>)? {
  let y=coefficient*x*x,slope=2*coefficient*x
  return clip(SIMD2(x-0.55,y-slope*0.55),SIMD2(x+0.55,y+slope*0.55))
 }
 /// Liang-Barsky segment clipping in mathematical coordinates, not point suppression.
 func clip(_ a:SIMD2<Double>,_ b:SIMD2<Double>)->(SIMD2<Double>,SIMD2<Double>)? {
  guard [a.x,a.y,b.x,b.y,coefficient].allSatisfy({$0.isFinite}) else{return nil}
  let d=b-a;var low=0.0,high=1.0
  for (p,q) in [(-d.x,a.x+2),(d.x,2-a.x),(-d.y,a.y+yRange),(d.y,yRange-a.y)] {
   if abs(p)<1e-15{if q<0{return nil}}else{let r=q/p;if p<0{low=max(low,r)}else{high=min(high,r)};if low>high{return nil}}
  }
  func mapped(_ p:SIMD2<Double>)->SIMD2<Double>{SIMD2(p.x*xScale,-p.y*yScale)}
  return (mapped(a+low*d),mapped(a+high*d))
 }
}
#if canImport(UIKit)
import UIKit
import SceneKit

/// Marker page frame: x-right, y-down, negative-z out of the paper.
final class PaperApplicationScene {
 let node=SCNNode();var state=PaperApplicationState();private var animated:SCNNode?
 init(){rebuild()}
 func material(_ color:UIColor,_ opacity:CGFloat=1)->SCNMaterial{let m=SCNMaterial();m.diffuse.contents=color;m.isDoubleSided=true;m.transparency=opacity;return m}
 @discardableResult func sphere(_ radius:CGFloat,_ position:SCNVector3,_ color:UIColor,parent:SCNNode?=nil)->SCNNode{let n=SCNNode(geometry:SCNSphere(radius:radius));n.geometry?.materials=[material(color)];n.position=position;(parent ?? node).addChildNode(n);return n}
 @discardableResult func line(_ a:SCNVector3,_ b:SCNVector3,_ color:UIColor,_ radius:CGFloat=0.0005,parent:SCNNode?=nil)->SCNNode{let delta=SIMD3<Float>(b.x-a.x,b.y-a.y,b.z-a.z),length=simd_length(delta);let n=SCNNode(geometry:SCNCylinder(radius:radius,height:CGFloat(length)));n.geometry?.materials=[material(color)];n.position=SCNVector3((a.x+b.x)/2,(a.y+b.y)/2,(a.z+b.z)/2);if length>0{n.simdOrientation=simd_quatf(from:SIMD3<Float>(0,1,0),to:delta/length)};(parent ?? node).addChildNode(n);return n}
 func label(_ text:String,_ p:SCNVector3,_ color:UIColor = .darkGray,fontSize:CGFloat=4){let g=SCNText(string:text,extrusionDepth:0.03);g.font = .systemFont(ofSize:fontSize,weight:.semibold);g.flatness=0.2;g.materials=[material(color)];let n=SCNNode(geometry:g);n.scale=SCNVector3(0.0012,0.0012,0.0012);n.eulerAngles.x = .pi;n.position=p;node.addChildNode(n)}
 func rebuild(){node.childNodes.forEach{$0.removeFromParentNode()};animated=nil
  switch state.topic {
  case .solar:
   sphere(0.009,SCNVector3(0,0,-0.022),.systemYellow)
   for i in 0..<3{let orbit=SCNNode();orbit.name="orbit-\(i)";orbit.position.z = -0.022;node.addChildNode(orbit);let r:Float=0.022+Float(i)*0.013;for j in 0..<64{let a=Float(j)*2 * .pi/64,b=Float(j+1)*2 * .pi/64;line(SCNVector3(r*cos(a),r*sin(a),0),SCNVector3(r*cos(b),r*sin(b),0),.lightGray,0.0003,parent:orbit)};sphere(i==state.selectedPlanet ? 0.006:0.004,SCNVector3(r,0,0),[UIColor.systemBlue,.systemRed,.systemGreen][i],parent:orbit)}
  case .cubeNet:makeCubeNet()
  case .crossSection:
   let side:CGFloat=0.05;let body=state.shapeSphere ? SCNNode(geometry:SCNSphere(radius:side/2)):SCNNode(geometry:SCNBox(width:side,height:side,length:side,chamferRadius:0));body.position.z = -Float(side/2);body.geometry?.materials=[material(.systemCyan,0.2)];node.addChildNode(body)
   let z = -Float(state.slice)*Float(side),radius=Float(side/2)*sqrt(max(0,1-pow(Float(2*state.slice-1),2)))
   if state.shapeSphere{for j in 0..<80{let a=Float(j)*2 * .pi/80,b=Float(j+1)*2 * .pi/80;line(SCNVector3(radius*cos(a),radius*sin(a),z),SCNVector3(radius*cos(b),radius*sin(b),z),.systemPink,0.0008)}}else{let h=Float(side/2);let pts=[SCNVector3(-h,-h,z),SCNVector3(h,-h,z),SCNVector3(h,h,z),SCNVector3(-h,h,z)];for i in 0..<4{line(pts[i],pts[(i+1)%4],.systemPink,0.0008)}}
   let plane=SCNNode(geometry:SCNPlane(width:0.065,height:0.065));plane.position.z=z;plane.geometry?.materials=[material(.systemPink,0.12)];node.addChildNode(plane)
  case .function:
   let plot=PaperGraphPlot(coefficient:state.coefficient),range=Float(plot.yRange*plot.yScale)
   line(SCNVector3(-0.036,0,-0.002),SCNVector3(0.036,0,-0.002),.darkGray);line(SCNVector3(0,-range,-0.002),SCNVector3(0,range,-0.002),.darkGray)
   func p(_ x:Double)->SCNVector3{let xy=plot.point(x);return SCNVector3(Float(xy.x),Float(xy.y),-0.012)}
   for i in 0..<100{let x = -2+Double(i)*0.04;line(p(x),p(x+0.04),.systemCyan,0.00065)}
   if let tangent=plot.tangent(state.tangentX){line(SCNVector3(Float(tangent.0.x),Float(tangent.0.y),-0.014),SCNVector3(Float(tangent.1.x),Float(tangent.1.y),-0.014),.systemOrange,0.0008)}
   sphere(0.0025,p(state.tangentX),.systemYellow)
   for x:Float in [-0.036,0.036]{line(SCNVector3(x,-0.0015,-0.003),SCNVector3(x,0.0015,-0.003),.darkGray,0.0003)}
   for y in [-range,range]{line(SCNVector3(-0.0015,y,-0.003),SCNVector3(0.0015,y,-0.003),.darkGray,0.0003)}
   label("−2",SCNVector3(-0.043,0.009,-0.008));label("2",SCNVector3(0.034,0.009,-0.008))
   label(String(format:"%.1f",plot.yRange),SCNVector3(0.004,-range+0.001,-0.008));label(String(format:"−%.1f",plot.yRange),SCNVector3(0.004,range,-0.008))
   label("y=ax²",SCNVector3(-0.026,-0.052,-0.008),.systemCyan)
   label("x/y scales independent",SCNVector3(-0.025,0.058,-0.018),.darkGray,fontSize:3.2)
  case .spring:
   line(SCNVector3(-0.022,0,-0.001),SCNVector3(0.022,0,-0.001),.darkGray,0.001)
   let spring=SCNNode();spring.name="spring-wire";node.addChildNode(spring);for _ in 0..<100{line(SCNVector3Zero,SCNVector3(0,0,-0.001),.systemCyan,0.0005,parent:spring)};animated=sphere(0.009,SCNVector3(0,0,-0.05),.systemOrange)
   label("E = ½mv² + ½kx²",SCNVector3(-0.044,-0.035,-0.006),.systemOrange)
  case .circuit:makeCircuit()
  case .fractions:makeFractions()
  case .vectors:makeVectors()
  case .binomial:makeBinomial()
  case .surface:makeSurface()
  case .revolution:makeRevolution()
  case .incline:makeIncline()
  case .pendulum:makePendulum()
  }
  updateAnimated()
 }
 func makeIncline(){let a=Float(state.incline.angle),length:Float=0.08
  let start=SCNVector3(-0.04,0,-0.008-length*sin(a)),end=SCNVector3(-0.04+length*cos(a),0,-0.008)
  line(start,end,.darkGray,0.002);line(SCNVector3(-0.04,0,-0.008),start,.lightGray);line(SCNVector3(-0.04,0,-0.008),end,.lightGray)
  let block=SCNNode(geometry:SCNBox(width:0.010,height:0.012,length:0.010,chamferRadius:0.001));block.name="incline-block";block.geometry?.materials=[material(.systemOrange)];node.addChildNode(block)
  let origin=SCNVector3(-0.02,-0.025,-0.025)
  arrow(origin,SCNVector3(origin.x,origin.y,origin.z+0.018),.systemRed)
  arrow(origin,SCNVector3(origin.x-Float(sin(state.incline.angle))*0.016,origin.y,origin.z-Float(cos(state.incline.angle))*0.016),.systemCyan)
  let forceOrigin=SCNVector3(-0.020,0.025,-0.025),forceLength=Float(min(state.incline.frictionLimit,state.incline.downhillGravity)/9.81)*0.025
  arrow(forceOrigin,SCNVector3(forceOrigin.x+cos(a)*0.02,forceOrigin.y,forceOrigin.z+sin(a)*0.02),.systemBlue)
  arrow(forceOrigin,SCNVector3(forceOrigin.x-cos(a)*forceLength,forceOrigin.y,forceOrigin.z-sin(a)*forceLength),.systemPurple)
  label("mg red · N cyan · friction purple",SCNVector3(-0.046,0.042,-0.030),.darkGray,fontSize:2.7)
  label(String(format:"a=%.2f m/s²",state.incline.acceleration),SCNVector3(-0.045,0.049,-0.030),.systemOrange,fontSize:3.2)
 }
 func makePendulum(){line(SCNVector3(-0.015,0,-0.060),SCNVector3(0.015,0,-0.060),.darkGray,0.001)
  let wire=line(SCNVector3Zero,SCNVector3(0,0.04,0),.darkGray,0.0007);wire.name="pendulum-wire"
  let bob=sphere(0.006,SCNVector3Zero,.systemOrange);bob.name="pendulum-bob"
  label("T=2π√(L/g)",SCNVector3(-0.040,0.047,-0.020),.darkGray)
  label("small angle · authored L",SCNVector3(-0.044,-0.048,-0.055),.darkGray,fontSize:3.2)
 }
 func makeCircuit(){let z:Float = -0.008;let vertices=[SCNVector3(-0.035,-0.027,z),SCNVector3(0.035,-0.027,z),SCNVector3(0.035,0.027,z),SCNVector3(-0.035,0.027,z)]
  for i in 0..<4{if i==0{line(vertices[0],SCNVector3(-0.008,-0.027,z),.darkGray,0.0008);line(SCNVector3(0.008,-0.027,z),vertices[1],.darkGray,0.0008)}else{line(vertices[i],vertices[(i+1)%4],.darkGray,0.0008)}}
  line(SCNVector3(-0.008,-0.027,z),SCNVector3(0.008,state.circuit.closed ? -0.027:-0.038,z),state.circuit.closed ? .systemGreen:.systemRed,0.001)
  for (offset,width) in [(Float(-0.003),CGFloat(0.018)),(Float(0.003),CGFloat(0.011))]{line(SCNVector3(-0.035-Float(width/2),offset,z-0.001),SCNVector3(-0.035+Float(width/2),offset,z-0.001),.systemGreen,0.001)}
  let resistor=SCNNode(geometry:SCNBox(width:0.010,height:0.016,length:0.006,chamferRadius:0.001));resistor.position=SCNVector3(0.035,0,z-0.002);resistor.geometry?.materials=[material(.systemOrange)];node.addChildNode(resistor)
  for i in 0..<12{let charge=sphere(0.0015,SCNVector3Zero,.systemYellow);charge.name="circuit-charge-\(i)"}
  label("I=V/R   P=VI",SCNVector3(-0.04,-0.046,-0.008),.darkGray)
  label(String(format:"%.0f V   %.0f Ω",state.circuit.voltage,state.circuit.resistance),SCNVector3(-0.04,0.046,-0.008),.systemOrange)
 }
 func makeFractions(){func bar(_ numerator:Int,_ denominator:Int,_ y:Float){let width:Float=0.096/Float(denominator);for i in 0..<denominator{let height:CGFloat=i<numerator ? 0.009:0.003;let part=SCNNode(geometry:SCNBox(width:CGFloat(width)-0.001,height:0.014,length:height,chamferRadius:0.0004));part.position=SCNVector3(-0.048+width*(Float(i)+0.5),y,-Float(height/2));part.geometry?.materials=[material(i<numerator ? .systemCyan:.lightGray)];node.addChildNode(part)}}
  bar(state.fraction.numerator,state.fraction.denominator,0)
  if state.fraction.showEquivalent{bar(state.fraction.numerator*2,state.fraction.denominator*2,0.028)}
  label("\(state.fraction.numerator)/\(state.fraction.denominator)",SCNVector3(-0.042,-0.027,-0.008),.systemCyan)
  if state.fraction.showEquivalent{label("= \(state.fraction.numerator*2)/\(state.fraction.denominator*2)",SCNVector3(-0.042,0.052,-0.008),.systemCyan)}
 }
 func arrow(_ a:SCNVector3,_ b:SCNVector3,_ color:UIColor){let delta=SIMD3<Float>(b.x-a.x,b.y-a.y,b.z-a.z),length=simd_length(delta);guard length>0.00001 else{return};let direction=delta/length,tip:Float=min(0.006,length*0.25),end=SIMD3<Float>(b.x,b.y,b.z);line(a,SCNVector3(end-direction*tip),color,0.0008);let head=SCNNode(geometry:SCNCone(topRadius:0,bottomRadius:0.0025,height:CGFloat(tip)));head.geometry?.materials=[material(color)];head.simdPosition=end-direction*tip/2;head.simdOrientation=simd_quatf(from:SIMD3<Float>(0,1,0),to:direction);node.addChildNode(head)}
 func makeVectors(){let u:Float=0.025,z:Float = -0.009,origin=SCNVector3(-0.023,0.006,z),a=SCNVector3(0.002,0.006,z),b=SCNVector3(-0.023+Float(state.vectors.bX)*u,0.006-Float(state.vectors.bY)*u,z),sum=SCNVector3(a.x+Float(state.vectors.bX)*u,a.y-Float(state.vectors.bY)*u,z)
  line(SCNVector3(-0.050,0.006,-0.002),SCNVector3(0.050,0.006,-0.002),.lightGray,0.0003)
  arrow(origin,a,.systemCyan);arrow(origin,b,.systemOrange)
  if state.vectors.showProjection{let projection=SCNVector3(b.x,origin.y,z-0.003);arrow(SCNVector3(origin.x,origin.y,z-0.003),projection,.systemPink);arrow(projection,SCNVector3(b.x,b.y,z-0.003),.systemPurple)}else{arrow(a,sum,.systemOrange);arrow(origin,sum,.systemGreen)}
  label(state.vectors.showProjection ? "proj + rejection":"a + b",SCNVector3(-0.048,-0.040,-0.008),.darkGray)
  label(String(format:"a·b = %.2f",state.vectors.dot),SCNVector3(-0.042,0.049,-0.008),.systemPink)
 }
 func makeBinomial(){let width:Float=0.010,base:Float=0.023,heightScale:Float=0.072;line(SCNVector3(-0.050,base,0),SCNVector3(0.050,base,0),.darkGray,0.0005)
  for (k,p) in state.binomial.probabilities.enumerated(){let h=Float(p)*heightScale;let x=Float(k-4)*width;if h>0{let bar=SCNNode(geometry:SCNBox(width:0.007,height:CGFloat(h),length:0.006,chamferRadius:0.0002));bar.position=SCNVector3(x,base-h/2,-0.006);bar.geometry?.materials=[material(.systemCyan)];node.addChildNode(bar)};label("\(k)",SCNVector3(x-0.0015,base+0.007,-0.008),.darkGray)}
  label(String(format:"n=8  p=%.1f",state.binomial.probability),SCNVector3(-0.043,-0.038,-0.008),.systemCyan)
  if state.binomial.showMoments{let meanX=Float(state.binomial.mean-4)*width;line(SCNVector3(meanX,base,-0.011),SCNVector3(meanX,base-0.055,-0.011),.systemOrange,0.0006);let sd=Float(sqrt(state.binomial.variance))*width;line(SCNVector3(meanX-sd,base-0.050,-0.011),SCNVector3(meanX+sd,base-0.050,-0.011),.systemPink,0.0008);label(String(format:"μ %.1f  σ² %.2f",state.binomial.mean,state.binomial.variance),SCNVector3(-0.043,0.049,-0.008),.systemOrange)}
 }
 func teachingMesh(_ mesh:PaperTeachingMesh,_ color:UIColor,_ opacity:CGFloat=1){guard !mesh.positions.isEmpty else{return};let vertices=mesh.positions.map{SCNVector3(Float($0.x),Float($0.y),Float($0.z))},normals=mesh.normals.map{SCNVector3(Float($0.x),Float($0.y),Float($0.z))};let element=SCNGeometryElement(indices:Array(0..<Int32(vertices.count)),primitiveType:.triangles);let geometry=SCNGeometry(sources:[SCNGeometrySource(vertices:vertices),SCNGeometrySource(normals:normals)],elements:[element]);geometry.materials=[material(color,opacity)];node.addChildNode(SCNNode(geometry:geometry))}
 func captionBackground(_ y:Float,_ z:Float){let caption=SCNNode(geometry:SCNPlane(width:0.104,height:0.014));caption.position=SCNVector3(0,y-0.003,z+0.0006);caption.geometry?.materials=[material(UIColor(white:0.98,alpha:1))];node.addChildNode(caption)}
 func makeSurface(){teachingMesh(.surface(state.surface),state.surface.saddle ? .systemPurple:.systemCyan,0.85)
  // Wire meridians make out-of-plane curvature visible even at a nearly head-on viewpoint.
  for fixed in [-1.0,-0.5,0,0.5,1]{for i in 0..<24{let x = -1+Double(i)/12,next=x+1/12;func p(_ x:Double,_ y:Double)->SCNVector3{SCNVector3(Float(x*0.035),Float(-y*0.035),Float(-0.035-state.surface.height(x,y)*0.010-0.0003))};line(p(x,fixed),p(next,fixed),.darkGray,0.00025);line(p(fixed,x),p(fixed,next),.darkGray,0.00025)}}
  captionBackground(0.055,-0.080)
  label(state.surface.saddle ? "h=a(x²−y²)":"h=a(x²+y²)",SCNVector3(-0.046,0.055,-0.080),.darkGray)
 }
 func makeRevolution(){teachingMesh(.revolution(state.revolution),.systemCyan,0.82)
  line(SCNVector3(0,0,-0.002),SCNVector3(0,0,Float(-state.revolution.height-0.012)),.systemOrange,0.0005)
  let phi=state.revolution.sweep;for i in 0..<24{let t=Double(i)/24,next=Double(i+1)/24;func p(_ t:Double)->SCNVector3{let r=state.revolution.radiusAt(t);return SCNVector3(Float(r*cos(phi)),Float(-r*sin(phi)),Float(-0.004-state.revolution.height*t))};line(p(t),p(next),.systemPink,0.0007)}
  captionBackground(0.049,Float(-state.revolution.height-0.014))
  label("r(t)=Rt^\(state.revolution.exponent)",SCNVector3(-0.042,0.049,Float(-state.revolution.height-0.014)),.darkGray)
  label(String(format:"V=%.2f cm³",state.revolution.volume*1e6),SCNVector3(-0.042,-0.042,-0.008),.darkGray)
 }
 func makeCubeNet(){let side:Float=0.03,half=side/2,angle=Float(state.fold)*(.pi/2)
  func face(_ color:UIColor,parent:SCNNode,position:SCNVector3){let n=SCNNode(geometry:SCNPlane(width:CGFloat(side),height:CGFloat(side)));n.position=position;n.geometry?.materials=[material(color,0.8)];parent.addChildNode(n)}
  face(.systemTeal,parent:node,position:SCNVector3(0,0,-0.001))
  for (i,color) in [UIColor.systemBlue,.systemOrange,.systemGreen,.systemPurple].enumerated(){let hinge=SCNNode();node.addChildNode(hinge);switch i{
   case 0:hinge.position=SCNVector3(-half,0,-0.001);hinge.eulerAngles.y = -angle;face(color,parent:hinge,position:SCNVector3(-half,0,0))
   case 1:hinge.position=SCNVector3(half,0,-0.001);hinge.eulerAngles.y = angle;face(color,parent:hinge,position:SCNVector3(half,0,0))
   case 2:hinge.position=SCNVector3(0,-half,-0.001);hinge.eulerAngles.x = angle;face(color,parent:hinge,position:SCNVector3(0,-half,0))
   default:hinge.position=SCNVector3(0,half,-0.001);hinge.eulerAngles.x = -angle;face(color,parent:hinge,position:SCNVector3(0,half,0));let lid=SCNNode();lid.position.y=side;lid.eulerAngles.x = -angle;hinge.addChildNode(lid);face(.systemPink,parent:lid,position:SCNVector3(0,half,0))
  }}
 }
 func updateAnimated(){
  if state.topic == .incline,let block=node.childNode(withName:"incline-block",recursively:false){let a=Float(state.incline.angle),u=Float(state.incline.distance),l:Float=0.08;block.position=SCNVector3(-0.04+l*cos(a)*u,0,-0.014-l*sin(a)*(1-u));block.eulerAngles.y = -a}
  if state.topic == .pendulum,let bob=node.childNode(withName:"pendulum-bob",recursively:false),let wire=node.childNode(withName:"pendulum-wire",recursively:false){let l=Float(0.025+0.015*state.pendulum.length),a=Float(state.pendulum.angle),pivot=SIMD3<Float>(0,0,-0.060),end=pivot+SIMD3<Float>(l*sin(a),0,l*cos(a)),d=end-pivot;bob.simdPosition=end;wire.simdPosition=(pivot+end)/2;(wire.geometry as? SCNCylinder)?.height=CGFloat(l);wire.simdOrientation=simd_quatf(from:SIMD3<Float>(0,1,0),to:d/l)}
if state.topic == .circuit{let vertices=[SIMD3<Float>(-0.035,-0.027,-0.009),SIMD3<Float>(0.035,-0.027,-0.009),SIMD3<Float>(0.035,0.027,-0.009),SIMD3<Float>(-0.035,0.027,-0.009)];for i in 0..<12{guard let charge=node.childNode(withName:"circuit-charge-\(i)",recursively:false) else{continue};charge.isHidden = !state.circuit.closed || state.circuit.current==0;let t=Float((state.circuit.phase+Double(i)/12).truncatingRemainder(dividingBy:1))*4,segment=min(3,Int(t)),u=t-Float(segment);charge.simdPosition=vertices[segment]*(1-u)+vertices[(segment+1)%4]*u}}
  if state.topic == .solar{for i in 0..<3{node.childNode(withName:"orbit-\(i)",recursively:false)?.eulerAngles.z=Float(state.elapsed*state.orbitRate/Double(i+1))}}
  if state.topic == .spring,let animated{let length=Float(0.05+state.spring.displacement);animated.position.z = -length;let wire=node.childNode(withName:"spring-wire",recursively:false)!;for (i,segment) in wire.childNodes.enumerated(){func p(_ t:Float)->SIMD3<Float>{SIMD3(0.003*cos(t*12 * .pi),0.003*sin(t*12 * .pi),-length*t)};let a=p(Float(i)/100),b=p(Float(i+1)/100),delta=b-a,l=simd_length(delta);(segment.geometry as? SCNCylinder)?.height=CGFloat(l);segment.simdPosition=(a+b)/2;if l>0{segment.simdOrientation=simd_quatf(from:SIMD3<Float>(0,1,0),to:delta/l)}}}
 }
 func advance(_ dt:Double,measured:Bool,paused:Bool){state.advance(dt,measured:measured,paused:paused);if measured && !paused{updateAnimated()}}
}
#endif
