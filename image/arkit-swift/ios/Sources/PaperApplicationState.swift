import Foundation

/// Teaching parameters are authored, never inferred from the printed document.
struct PaperApplicationState {
 enum Topic: Int, CaseIterable { case solar, cubeNet, crossSection, function, spring, circuit, fractions, vectors, binomial, surface, revolution, incline, pendulum
  var title:String { ["Solar orbits", "Cube net → solid", "Solid cross-section", "Quadratic + tangent", "Spring energy", "Ohm law circuit", "Equivalent fractions", "Vector sum + projection", "Binomial distribution", "Surface height + saddle", "Solids of revolution", "Inclined plane forces", "Pendulum period + energy"][rawValue] }
  var pickerTitle:String { ["Solar","Net","Slice","Graph","Spring","Circuit","Parts","Vectors","Binomial","Surface","Revolve","Incline","Pendulum"][rawValue] }
  var controls:[String] { switch self { case .solar:return ["Faster orbit","Slower orbit","Next planet"];case .cubeNet:return ["Fold +15°","Unfold −15°","Net / solid"];case .crossSection:return ["Slice higher","Slice lower","Cube / sphere"];case .function:return ["Curve a +0.25","Curve a −0.25","Move tangent"];case .spring:return ["Stiffer spring","Softer spring","Release mass"];case .circuit:return ["Voltage +1 V","Resistance +10 Ω","Open / close switch"];case .fractions:return ["Add one part","More equal parts","Equivalent ×2"];case .vectors:return ["Angle +15°","Angle −15°","Projection / sum"];case .binomial:return ["Probability +0.1","Probability −0.1","Mean / variance"];case .surface:return ["Surface a +0.25","Surface a −0.25","Bowl / saddle"];case .revolution:return ["Radius +2 mm","Radius −2 mm","Next profile"];case .incline:return ["Slope +5°","Slope −5°","Friction / release"];case .pendulum:return ["Length +0.2 m","Length −0.2 m","Release +5°"] } }
 }
 var topic:Topic = .solar { didSet{if topic != oldValue{springPulling=false}} }
 var fold=0.0,slice=0.5,coefficient=1.0,tangentX=0.0,orbitRate=1.0
 var shapeSphere=false,selectedPlanet=0
 var spring=SourceSpringDynamics()
 var springPulling=false
 var circuit=PaperCircuitState(),fraction=PaperFractionState()
 var vectors=PaperVectorState(),binomial=PaperBinomialState()
 var surface=PaperSurfaceState(),revolution=PaperRevolutionState()
 var incline=PaperInclineState(),pendulum=PaperPendulumState()
 var elapsed=0.0
 var description:String { switch topic {
 case .solar:return String(format:"Orbit speed ×%.2f · selected planet %d · orbital illustration, not to scale",orbitRate,selectedPlanet+1)
 case .cubeNet:return String(format:"Fold %.0f° · six hinged square faces · side 3 cm",fold*90)
 case .crossSection:let r=sqrt(max(0,1-pow(2*slice-1,2)));return String(format:"%@ · slice %.0f%% · section %@",shapeSphere ? "Sphere":"Cube",slice*100,shapeSphere ? String(format:"radius %.1f mm",r*25):"50 × 50 mm square")
 case .function:return String(format:"y = %.2f x² · x = %.1f · tangent slope %.2f",coefficient,tangentX,2*coefficient*tangentX)
 case .spring:return String(format:"k %.0f N/m · m %.2f kg · x %.1f mm · E %.5f J",spring.stiffness,spring.mass,spring.displacement*1000,spring.energy)
 case .circuit:return String(format:"V %.0f V · R %.0f Ω · I %.3f A · P %.3f W · %@ · illustrative charges",circuit.voltage,circuit.resistance,circuit.current,circuit.power,circuit.closed ? "closed":"open")
 case .fractions:return "\(fraction.numerator)/\(fraction.denominator) = \(fraction.numerator*2)/\(fraction.denominator*2) · same whole, equal parts"
 case .vectors:return String(format:"θ %.0f° · a·b %.3f · |a+b| %.3f · %@",vectors.angleDegrees,vectors.dot,vectors.sumLength,vectors.showProjection ? "signed projection + rejection":"head-to-tail vector sum")
 case .binomial:return String(format:"n %d · p %.1f · mean %.2f · variance %.2f · exact probabilities",binomial.trials,binomial.probability,binomial.mean,binomial.variance)
 case .surface:return String(format:"h = %.2f(x² %@ y²) · authored 10 mm/unit height · 35 mm base",surface.coefficient,surface.saddle ? "−":"+")
 case .revolution:return String(format:"r(t)=R t^%d · R %.0f mm · H %.0f mm · sweep %.0f° · V %.2f cm³ · authored dimensions",revolution.exponent,revolution.radius*1000,revolution.height*1000,revolution.sweep*180/Double.pi,revolution.volume*1e6)
 case .incline:return String(format:"θ %.0f° · μ %.2f · g sinθ %.2f · μg cosθ %.2f · a %.2f m/s²",incline.angle*180/Double.pi,incline.friction,incline.downhillGravity,incline.frictionLimit,incline.acceleration)
 case .pendulum:return String(format:"L %.2f m · θ₀ %.0f° · T %.2f s · E %.3f J · small-angle ideal model",pendulum.length,pendulum.initialAngle*180/Double.pi,pendulum.period,pendulum.energy)
 } }
 mutating func parameter(_ direction:Double){guard direction.isFinite else{return};let d=direction>0 ? 1.0:-1.0;switch topic {
 case .solar:orbitRate=min(3,max(0.25,orbitRate+d*0.25))
 case .cubeNet:fold=min(1,max(0,fold+d/6))
 case .crossSection:slice=min(0.95,max(0.05,slice+d*0.1))
 case .function:coefficient=min(2,max(-2,coefficient+d*0.25))
 case .spring:spring.setStiffness(spring.stiffness+d*2)
 case .circuit:if d>0{circuit.setVoltage(circuit.voltage>=12 ? 1:circuit.voltage+1)}else{circuit.setResistance(circuit.resistance>=100 ? 10:circuit.resistance+10)}
 case .fractions:if d>0{fraction.numerator=(fraction.numerator+1)%(fraction.denominator+1)}else{fraction.setDenominator(fraction.denominator>=8 ? 2:fraction.denominator+1)}
 case .vectors:vectors.setAngle(vectors.angleDegrees+d*15)
 case .binomial:binomial.setProbability(binomial.probability+d*0.1)
 case .surface:surface.setCoefficient(surface.coefficient+d*0.25)
 case .revolution:revolution.setRadius(revolution.radius+d*0.002)
 case .incline:incline.setAngle(incline.angle+d*Double.pi/36)
 case .pendulum:pendulum.setLength(pendulum.length+d*0.2)
 } }
 mutating func event(){switch topic{case .solar:selectedPlanet=(selectedPlanet+1)%3;case .cubeNet:fold=fold<0.5 ? 1:0;case .crossSection:shapeSphere.toggle();case .function:tangentX=tangentX>=1.5 ? -1.5:tangentX+0.5;case .spring:springPulling=false;spring.reset();case .circuit:circuit.closed.toggle();case .fractions:fraction.showEquivalent.toggle();case .vectors:vectors.showProjection.toggle();case .binomial:binomial.showMoments.toggle();case .surface:surface.saddle.toggle();case .revolution:revolution.exponent=(revolution.exponent+1)%3;case .incline:incline.friction=incline.friction>0 ? 0:0.35;incline.time=0;case .pendulum:pendulum.setInitialAngle(pendulum.initialAngle>=Double.pi/9 ? Double.pi/36:pendulum.initialAngle+Double.pi/36)}}
 mutating func advance(_ dt:Double,measured:Bool,paused:Bool){
  guard measured,!paused,dt.isFinite,dt>0,dt<=0.25 else{return}
  // Consume all fresh elapsed time; substeps stabilize numerical models, not slow time.
  let steps=max(1,Int(ceil(dt/0.05))),step=dt/Double(steps)
  elapsed += dt
  for _ in 0..<steps{if topic == .spring && !springPulling{spring.advance(step)};if topic == .circuit{circuit.advance(step)}}
  if topic == .incline{incline.time += dt};if topic == .pendulum{pendulum.time += dt}
 }
 /// Absolute lesson input from a fresh measured page pose relative to an explicit baseline.
 /// Caller owns optical freshness, pause/lost gating, physical axes and default-OFF UI.
 /// Returns true only when an actual lesson parameter changes; fractions intentionally unsupported.
 @discardableResult mutating func applyPaperDial(rotationRadians:Double,translationMeters:Double)->Bool {
  guard rotationRadians.isFinite,translationMeters.isFinite else{return false}
  // Bound arithmetic before conversion, without changing any resulting saturated lesson range.
  let angle=min(10 * Double.pi,max(-10 * Double.pi,rotationRadians)),turn=angle/(Double.pi/2)
  let translation=min(0.12,max(-0.12,translationMeters))
  switch topic {
  case .solar:let value=min(3,max(0.2,1+turn));guard value != orbitRate else{return false};orbitRate=value
  case .cubeNet:let value=min(1,max(0,turn));guard value != fold else{return false};fold=value
  case .crossSection:let value=min(1,max(0,0.5+translation/0.12));guard value != slice else{return false};slice=value
  case .function:let value=min(3,max(0.25,1+turn)),point=min(2,max(-2,translation/0.03));guard value != coefficient || point != tangentX else{return false};coefficient=value;tangentX=point
  case .spring:
   let value=min(60,max(2,14+turn*10));var changed=false
   if value != spring.stiffness{spring.setStiffness(value);changed=true}
   // Authored page gesture controls the spring initial condition, not measured force.
   if abs(translation)>0.005{let pulled=min(0.015,max(-0.015,0.5*translation));changed = changed || !springPulling || pulled != spring.displacement || spring.velocity != 0;springPulling=true;spring.displacement=pulled;spring.velocity=0}
   else if abs(translation)<0.003 && springPulling{springPulling=false;changed=true}
   return changed
  case .circuit:let value=min(100,max(10,30+turn*70));guard value != circuit.resistance else{return false};circuit.setResistance(value)
  case .incline:let a=min(Double.pi/3,max(0,Double.pi/6+angle/2)),f=min(0.8,max(0,0.2+translation*5));guard a != incline.angle || f != incline.friction else{return false};let time=incline.time;incline.setAngle(a);incline.friction=f;incline.time=time
  case .pendulum:let length=min(2,max(0.2,1+translation*10)),amplitude=min(Double.pi/9,max(Double.pi/180,Double.pi/18+angle/12));guard length != pendulum.length || amplitude != pendulum.initialAngle else{return false};let time=pendulum.time;pendulum.setLength(length);pendulum.setInitialAngle(amplitude);pendulum.time=time
  case .fractions:return false // No arbitrary rotation-to-discrete-count pedagogical mapping.
  case .vectors:var wrapped=rotationRadians.truncatingRemainder(dividingBy:2 * Double.pi);if wrapped<0{wrapped += 2 * Double.pi};let value=(wrapped*180/Double.pi).truncatingRemainder(dividingBy:360);guard value != vectors.angleDegrees else{return false};vectors.setAngle(value)
  case .binomial:let value=min(1,max(0,0.5+angle/Double.pi));guard value != binomial.probability else{return false};binomial.setContinuousProbability(value)
  case .surface:let value=min(1.5,max(-1.5,1+turn)),saddle=translation>0.02;guard value != surface.coefficient || saddle != surface.saddle else{return false};surface.setCoefficient(value);surface.saddle=saddle
  case .revolution:let value=min(2 * Double.pi,max(0,2 * Double.pi+angle)),profile=translation>0.04 ? 2:(translation>0.02 ? 1:0);guard value != revolution.sweep || profile != revolution.exponent else{return false};revolution.setSweep(value);revolution.exponent=profile
  }
  return true
 }
 mutating func reset(){let topic=self.topic;self=PaperApplicationState();self.topic=topic}
}

/// Ideal resistive circuit; not measured current or particle velocity.
struct PaperCircuitState {
 private(set) var voltage=6.0,resistance=30.0
 var closed=true,phase=0.0
 var current:Double{closed ? voltage/resistance:0}
 var power:Double{voltage*current}
 mutating func setVoltage(_ value:Double){guard value.isFinite else{return};voltage=min(12,max(0,value))}
 mutating func setResistance(_ value:Double){guard value.isFinite else{return};resistance=min(1000,max(1,value))}
 mutating func advance(_ dt:Double){guard dt.isFinite,dt>0,closed else{return};phase=(phase+min(dt,0.05)*current*1.5).truncatingRemainder(dividingBy:1)}
}
struct PaperFractionState {
 var numerator=1,denominator=4,showEquivalent=false
 var value:Double{Double(numerator)/Double(denominator)}
 mutating func setDenominator(_ d:Int){denominator=min(8,max(2,d));numerator=min(denominator,max(0,numerator))}
}

/// Unit vectors in the page plane. Projection remains signed, including obtuse angles.
struct PaperVectorState {
 private(set) var angleDegrees=60.0
 var showProjection=false
 var bX:Double{cos(angleDegrees * .pi/180)}
 var bY:Double{sin(angleDegrees * .pi/180)}
 var dot:Double{bX}
 var sumLength:Double{hypot(1+bX,bY)}
 mutating func setAngle(_ value:Double){guard value.isFinite else{return};angleDegrees=value.truncatingRemainder(dividingBy:360);if angleDegrees<0{angleDegrees += 360}}
}
/// Exact finite binomial PMF, not a simulated or empirically measured frequency.
struct PaperBinomialState {
 let trials=8
 private(set) var probability=0.5
 var showMoments=true
 var mean:Double{Double(trials)*probability}
 var variance:Double{Double(trials)*probability*(1-probability)}
 var probabilities:[Double]{(0...trials).map{k in
  if probability==0{return k==0 ? 1:0};if probability==1{return k==trials ? 1:0}
  var choose=1.0;if k>0{for j in 1...k{choose *= Double(trials-j+1)/Double(j)}}
  return choose*pow(probability,Double(k))*pow(1-probability,Double(trials-k))
 }}
 mutating func setContinuousProbability(_ value:Double){guard value.isFinite else{return};probability=min(1,max(0,value))}
 mutating func setProbability(_ value:Double){guard value.isFinite else{return};probability=min(1,max(0,(value*10).rounded()/10))}
}

struct PaperSurfaceState {
 private(set) var coefficient=1.0
 var saddle=false
 func height(_ x:Double,_ y:Double)->Double{coefficient*(x*x+(saddle ? -1:1)*y*y)}
 mutating func setCoefficient(_ value:Double){guard value.isFinite else{return};coefficient=min(1.5,max(-1.5,value))}
}
struct PaperRevolutionState {
 private(set) var radius=0.024,height=0.045,sweep=2 * Double.pi
 var exponent=1
 var fullVolume:Double{Double.pi*radius*radius*height/Double(2*exponent+1)}
 var volume:Double{fullVolume*sweep/(2 * Double.pi)}
 func radiusAt(_ t:Double)->Double{guard t.isFinite else{return 0};return radius*pow(min(1,max(0,t)),Double(exponent))}
 mutating func setRadius(_ v:Double){guard v.isFinite else{return};radius=min(0.035,max(0,v))}
 mutating func setHeight(_ v:Double){guard v.isFinite else{return};height=min(0.08,max(0,v))}
 mutating func setSweep(_ v:Double){guard v.isFinite else{return};sweep=min(2 * Double.pi,max(0,v))}
}
/// Shared meter-space triangle data used by renderer and independent geometric QA.
struct PaperTeachingMesh {
 var positions:[SIMD3<Double>]=[],normals:[SIMD3<Double>]=[]
 static func cross(_ a:SIMD3<Double>,_ b:SIMD3<Double>)->SIMD3<Double>{SIMD3(a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x)}
 static func dot(_ a:SIMD3<Double>,_ b:SIMD3<Double>)->Double{a.x*b.x+a.y*b.y+a.z*b.z}
 mutating func triangle(_ a:SIMD3<Double>,_ b:SIMD3<Double>,_ c:SIMD3<Double>){let n=Self.cross(b-a,c-a),length=sqrt(Self.dot(n,n));guard length>1e-14 else{return};positions += [a,b,c];normals += [n/length,n/length,n/length]}
 var signedVolume:Double{stride(from:0,to:positions.count,by:3).reduce(0.0){$0+Self.dot(positions[$1],Self.cross(positions[$1+1],positions[$1+2]))/6}}
 static func surface(_ state:PaperSurfaceState,steps:Int=20)->Self{var mesh=Self();let steps=max(2,min(100,steps));func point(_ i:Int,_ j:Int)->SIMD3<Double>{let x=Double(i)*2/Double(steps)-1,y=Double(j)*2/Double(steps)-1;return SIMD3(x*0.035,-y*0.035,-0.035-state.height(x,y)*0.010)};for j in 0..<steps{for i in 0..<steps{let a=point(i,j),b=point(i+1,j),c=point(i,j+1),d=point(i+1,j+1);mesh.triangle(a,b,d);mesh.triangle(a,d,c)}};return mesh}
 static func revolution(_ state:PaperRevolutionState,rings:Int=24,segments:Int=64)->Self{var mesh=Self();guard state.radius>0,state.height>0,state.sweep>0 else{return mesh};let rings=max(2,min(100,rings)),segments=max(3,min(256,segments)),base=0.004,full=state.sweep==2 * Double.pi
  func point(_ j:Int,_ k:Int)->SIMD3<Double>{let t=Double(k)/Double(rings),phi=full && j==segments ? 0:Double(j)*state.sweep/Double(segments),r=state.radiusAt(t);return SIMD3(r*cos(phi),-r*sin(phi),-base-state.height*t)}
  for k in 0..<rings{for j in 0..<segments{let a=point(j,k),b=point(j+1,k),c=point(j,k+1),d=point(j+1,k+1);mesh.triangle(a,b,d);mesh.triangle(a,d,c)}}
  let low=SIMD3<Double>(0,0,-base),high=SIMD3<Double>(0,0,-base-state.height)
  for j in 0..<segments{mesh.triangle(low,point(j+1,0),point(j,0));mesh.triangle(high,point(j,rings),point(j+1,rings))}
  if !full{for k in 0..<rings{let a=SIMD3<Double>(0,0,-base-state.height*Double(k)/Double(rings)),b=SIMD3<Double>(0,0,-base-state.height*Double(k+1)/Double(rings));mesh.triangle(a,point(0,k),point(0,k+1));mesh.triangle(a,point(0,k+1),b);mesh.triangle(a,point(segments,k+1),point(segments,k));mesh.triangle(a,b,point(segments,k+1))}}
  return mesh
 }
}

/// Authored one-metre incline. Static/kinetic coefficient shared in this elementary model.
struct PaperInclineState {
 var angle=Double.pi/6,friction=0.2,time=0.0
 let gravity=9.81,mass=1.0
 var downhillGravity:Double{gravity*sin(angle)}
 var normal:Double{mass*gravity*cos(angle)}
 var frictionLimit:Double{friction*gravity*cos(angle)}
 var acceleration:Double{max(0,downhillGravity-frictionLimit)}
 var distance:Double{min(1,0.5*acceleration*time*time)}
 mutating func setAngle(_ v:Double){guard v.isFinite else{return};angle=min(Double.pi/3,max(0,v));time=0}
}
/// Exact harmonic solution of the small-angle pendulum, not a measured physical pendulum.
struct PaperPendulumState {
 private(set) var length=1.0,initialAngle=Double.pi/18
 var time=0.0
 let gravity=9.81,mass=1.0
 var omega:Double{sqrt(gravity/length)}
 var period:Double{2 * Double.pi/omega}
 var angle:Double{initialAngle*cos(omega*time)}
 var angularVelocity:Double{-initialAngle*omega*sin(omega*time)}
 var kinetic:Double{0.5*mass*length*length*angularVelocity*angularVelocity}
 var potential:Double{0.5*mass*gravity*length*angle*angle}
 var energy:Double{kinetic+potential}
 mutating func setLength(_ v:Double){guard v.isFinite else{return};length=min(2,max(0.2,v));time=0}
 mutating func setInitialAngle(_ v:Double){guard v.isFinite else{return};initialAngle=min(Double.pi/9,max(Double.pi/180,v));time=0}
}

/// Monotonic render clock. No interval straddling a lost/pause/background boundary is simulated.
struct PaperApplicationClock {
 private var previousTime:Double?,previousRunnable=false
 mutating func interval(at now:Double,runnable:Bool)->Double {
  guard now.isFinite else{previousTime=nil;previousRunnable=false;return 0}
  defer{previousTime=now;previousRunnable=runnable}
  guard runnable,previousRunnable,let previousTime else{return 0}
  let dt=now-previousTime;return dt>0 && dt<=0.25 ? dt:0
 }
}
