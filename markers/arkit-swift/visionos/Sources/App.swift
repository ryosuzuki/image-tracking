import SwiftUI
import RealityKit
import UIKit
import simd

@main struct PaperLabApp: App {
 @State private var lab = Lab()
 var body: some SwiftUI.Scene {
  WindowGroup(id: "controls") { Controls(lab: lab) }.defaultSize(width: 620, height: 360)
  ImmersiveSpace(id: "paper-space") { SpatialLab(lab: lab) }.immersionStyle(selection: .constant(.mixed), in: .mixed)
 }
}
struct Controls: View {
 var lab: Lab
 @Environment(\.openImmersiveSpace) private var open
 @Environment(\.dismissWindow) private var dismiss
 var body: some View {
  VStack(spacing: 18) {
   Text("Paper Lab · visionOS").font(.largeTitle.bold())
   Text("Native RealityKit · simulated image pose").foregroundStyle(.secondary)
   Text("Math, Augmented Physics and 3D Trebuchet follow the source page in 3D space.").multilineTextAlignment(.center)
   Button("Open spatial demo") { Task { await launch() } }.buttonStyle(.borderedProminent)
   Text("Simulator preview — no camera image recognition").font(.caption)
  }.padding(32).task { try? await Task.sleep(for: .seconds(2)); await launch() }
 }
 func launch() async { let result = await open(id: "paper-space"); if case .opened = result { dismiss(id: "controls") } }
}
struct SpatialLab: View {
 @Bindable var lab: Lab
 var body: some View {
  RealityView { content, attachments in
   lab.setup(); content.add(lab.world)
   if let header = attachments.entity(for: "header") { header.position = [0,2.20,-1.55]; header.scale = [1.25,1.25,1.25]; content.add(header) }
   if let footer = attachments.entity(for: "footer") { footer.position = [0,1.10,-1.55]; footer.scale = [1.2,1.2,1.2]; content.add(footer) }
   lab.start()
  } attachments: {
   Attachment(id: "header") {
    VStack(spacing: 7) {
     Text("Paper Lab · Apple Vision Pro Simulator").font(.title2.bold())
     Text(lab.stage).font(.headline).foregroundStyle(.cyan)
     Text("SIMULATED IMAGE POSE • no camera recognition").font(.caption).foregroundStyle(.secondary)
    }.padding(18).frame(width: 650).glassBackgroundEffect()
   }
   Attachment(id: "footer") {
    VStack(spacing: 10) {
     Text(lab.detail).font(.headline).monospacedDigit().multilineTextAlignment(.center)
     HStack {
      ForEach(0..<4) { i in Button(["Math","Incline","Pendulum","Trebuchet"][i]) { lab.autoplay = false; lab.switchMode(i) } }
     }
     HStack {
      Button(lab.manualMotion ? "Stop page" : "Move page") { lab.autoplay = false; lab.manualMotion.toggle() }
      Button(["Change graph","Release cart","Push pendulum","Fire"][lab.mode]) { lab.autoplay = false; lab.action() }
      Button("Reset") { lab.autoplay = false; lab.switchMode(lab.mode) }
     }.font(.callout)
     if lab.mode == 3 {
      HStack {
       Text(String(format: "Mass %.2f kg",lab.mass)).frame(width: 125)
       Slider(value: $lab.mass, in: 0.1...1.25).frame(width: 160).disabled(lab.launched)
       Text(String(format: "Angle %.0f°",lab.angle)).frame(width: 85)
       Slider(value: $lab.angle, in: 20...60).frame(width: 130).disabled(lab.launched)
      }.font(.callout)
     }
    }.padding(18).frame(width: 800).glassBackgroundEffect()
   }
  }
  .gesture(DragGesture().targetedToAnyEntity().onChanged { value in
   lab.manualMotion = false
   let p = value.convert(value.location3D, from: .local, to: .scene)
   lab.paper.position = p
  })
 }
}
@MainActor @Observable final class Lab {
 var stage = "Math · image-aligned graph"
 var detail = "y = (x + 3)² + 1"
 var mode = 0
 var manualMotion = false
 var autoplay = true
 let world = Entity(), paper = Entity(), overlay = Entity()
 @ObservationIgnored var timer: Timer?
 @ObservationIgnored var started: TimeInterval = 0
 @ObservationIgnored var previous: TimeInterval = 0
 @ObservationIgnored var elapsed: Float = 0
 var modeTime: Float = 0
 @ObservationIgnored var coefficient: Float = 1
 @ObservationIgnored var lastStage = -1
 @ObservationIgnored var lastSample = -1
 @ObservationIgnored var graph = Entity()
 @ObservationIgnored var cart = Entity()
 @ObservationIgnored var rod = Entity()
 @ObservationIgnored var bob = Entity()
 @ObservationIgnored var arm = Entity()
 @ObservationIgnored var shot = Entity()
 @ObservationIgnored var pendTheta: Float = -0.47
 @ObservationIgnored var pendOmega: Float = 0
 var launched = false
 @ObservationIgnored var launchTime: Float = 0
 @ObservationIgnored var cartRunning = false
 @ObservationIgnored var cartStart: Float = 0
 @ObservationIgnored var speed: Float = 0
 var mass: Float = 0.25
 var angle: Float = 40
 @ObservationIgnored var trail = Entity()
 @ObservationIgnored var trailPrevious: SIMD3<Float>?
 @ObservationIgnored var lastTrailTime: Float = 0
 @ObservationIgnored var didHighLaunch = false
 @ObservationIgnored var didPendulumPush = false
 @ObservationIgnored var blocks: [Entity] = []
 @ObservationIgnored var blockPositions: [SIMD3<Float>] = []
 @ObservationIgnored var blockVelocities: [SIMD3<Float>] = []
 @ObservationIgnored var knocked: [Bool] = []
 @ObservationIgnored var width: Float = 1.00
 @ObservationIgnored var imageWidth: Float = 800
 @ObservationIgnored var imageHeight: Float = 445
 @ObservationIgnored var sheetHeight: Float = 0.556
 @ObservationIgnored var metrics: [[String: Any]] = []
 func material(_ color: UIColor) -> UnlitMaterial { UnlitMaterial(color: color) }
 func box(_ size: SIMD3<Float>, _ position: SIMD3<Float>, _ color: UIColor, parent: Entity? = nil) -> ModelEntity {
  let e = ModelEntity(mesh: .generateBox(size: size, cornerRadius: 0.002), materials: [material(color)])
  e.position = position; (parent ?? overlay).addChild(e); return e
 }
 func sphere(_ radius: Float, _ position: SIMD3<Float>, _ color: UIColor, parent: Entity? = nil) -> ModelEntity {
  let e = ModelEntity(mesh: .generateSphere(radius: radius), materials: [material(color)])
  e.position = position; (parent ?? overlay).addChild(e); return e
 }
 func point(_ x: Float, _ y: Float, _ z: Float = 0.018) -> SIMD3<Float> { [(x/imageWidth-0.5)*width,(0.5-y/imageHeight)*sheetHeight,z] }
 func line(_ a: SIMD3<Float>, _ b: SIMD3<Float>, radius: Float = 0.004, color: UIColor = .systemCyan, parent: Entity? = nil) -> Entity {
  let diff = b-a, length = simd_length(diff)
  let e = box([radius,length,radius], (a+b)/2, color, parent: parent)
  if length > 0 { e.orientation = simd_quatf(from: SIMD3<Float>(0,1,0), to: diff/length) }; return e
 }
 func setup() {
  world.name = "SpatialPaperLab"; paper.name = "SimulatedImageAnchor"; world.addChild(paper); paper.position = [0,1.70,-1.55]
  paper.addChild(overlay); switchMode(0)
 }
 func setPaper(_ name: String, w: Float, h: Float) {
  paper.children.filter { $0 !== overlay }.forEach { $0.removeFromParent() }
  imageWidth = w; imageHeight = h; sheetHeight = width*h/w
  var mat = UnlitMaterial(); if let texture = try? TextureResource.load(named: name+".png") { mat.color = .init(tint: .white, texture: .init(texture)) }
  let sheet = ModelEntity(mesh: .generatePlane(width: width, height: sheetHeight), materials: [mat]); sheet.name = "SourceImage_"+name
  sheet.generateCollisionShapes(recursive: true); sheet.components.set(InputTargetComponent()); paper.addChild(sheet)
  for (x,y) in [(Float(0),Float(0)),(w,Float(0)),(Float(0),h),(w,h)] {
   let p = point(x,y,0.006); _ = sphere(0.009,p,.systemMint,parent:paper)
  }
 }
 func switchMode(_ newMode: Int) {
  mode = newMode; modeTime = elapsed; launched = false; cartRunning = false; pendTheta = -0.47; pendOmega = 0; manualMotion = false
  // Snapshot the ChildCollection before removal: mutating its live iterator skips children.
  Array(overlay.children).forEach { $0.removeFromParent() }; blocks = []; blockPositions=[]; blockVelocities=[]; knocked=[]
  switch mode {
  case 0:
   setPaper("math",w:800,h:445); stage="Math · graph registered on source axes"; coefficient=1; buildGraph(); detail="y = (x + 3)² + 1 · registered to the printed graph"
  case 1:
   setPaper("incline",w:846,h:525); stage="Augmented Physics · gravity on the printed ramp"
   _ = line(point(170,254),point(798,321),radius:0.009,color:.systemTeal)
   cart = box([0.072,0.035,0.046],point(310,235,0.033),.systemOrange); cart.orientation = simd_quatf(angle:-0.107,axis:[0,0,1])
   detail="g = 9.81 m/s² · h = 20 cm · length = 180 cm"
  case 2:
   setPaper("pendulum",w:430,h:344); stage="Augmented Physics · pendulum aligned to the diagram"
   _ = sphere(0.014,point(258,62),.systemTeal); rod=Entity(); overlay.addChild(rod); bob=sphere(0.026,[0,0,0],.systemOrange); updatePendulum()
   detail="Pendulum · gravity-driven swing about the printed pivot"
  default:
   setPaper("trebuchet",w:1280,h:800); stage="3D Trebuchet · image-aligned mechanism + ballistic launch"
   let wood = UIColor(red:0.71,green:0.41,blue:0.16,alpha:1)
   _ = line(point(220,593,0.04),point(565,593,0.04),radius:0.021,color:wood)
   _ = line(point(225,589,0.04),point(394,416,0.04),radius:0.022,color:wood)
   _ = line(point(394,416,0.04),point(560,589,0.04),radius:0.022,color:wood)
   // A second support plane and connecting axle make the authored geometry visibly 3D.
   _ = line(point(225,589,0.14),point(394,416,0.14),radius:0.022,color:wood)
   _ = line(point(394,416,0.14),point(560,589,0.14),radius:0.022,color:wood)
   _ = line(point(394,416,0.025),point(394,416,0.155),radius:0.028,color:.systemGray)
   _ = line(point(225,589,0.035),point(225,589,0.145),radius:0.025,color:wood)
   _ = line(point(560,589,0.035),point(560,589,0.145),radius:0.025,color:wood)
   arm=Entity(); arm.position=point(394,416,0.075); overlay.addChild(arm)
   _ = line(point(170,165)-point(394,416),point(488,430)-point(394,416),radius:0.017,color:wood,parent:arm)
   _ = box([0.044,0.05,0.065],point(495,496)-point(394,416),.systemGray,parent:arm)
   for row in 0..<4 { for col in 0..<(4-row) {
    let px: Float = 1060 + Float(col)*77 + Float(row)*38.5, py: Float = 605-Float(row)*85
    let p=point(px,py,0.06); let e=box([0.054,0.059,0.08],p,.systemOrange); blocks.append(e); blockPositions.append(p); blockVelocities.append(.zero); knocked.append(false)
   }}
   shot=sphere(0.017,point(175,165,0.07),.systemCyan); mass=0.25; angle=40
   trail=Entity(); overlay.addChild(trail); trailPrevious=nil; lastTrailTime=0
   detail="Counterweight 0.25 kg · angle 40° · prepared image + authored 3D"
  }
  paper.orientation = simd_quatf(angle:0,axis:[0,0,1]); paper.position=[0,1.70,-1.55]
  print("VISIONOS_MODE \(mode) source-image=\(paper.children.count) overlays=\(overlay.children.count)")
 }
 func buildGraph() {
  graph.removeFromParent(); graph=Entity(); overlay.addChild(graph)
  // Original graph origin (598,355), vertex (-3,1) at (523,329): 25 px / x-unit, 26 px / y-unit.
  for i in 0..<90 {
   let x0 = -5.25+Float(i)*0.05, x1=x0+0.05
   let y0=coefficient*(x0+3)*(x0+3)+1, y1=coefficient*(x1+3)*(x1+3)+1
   _ = line(point(598+25*x0,355-26*y0,0.025),point(598+25*x1,355-26*y1,0.025),radius:0.005,color:.systemCyan,parent:graph)
  }
  _ = sphere(0.012,point(523,329,0.027),.systemOrange,parent:graph)
 }
 func action() {
  if mode==0 { coefficient = coefficient == 1 ? 0.45:1.4; buildGraph(); detail=String(format:"y = %.2f (x + 3)² + 1 · live coefficient change",coefficient) }
  else if mode==1 { cartRunning=true; cartStart=elapsed; detail="Released from rest · gravity moves the cart down the printed slope" }
  else if mode==2 { pendTheta = -0.65; pendOmega=0; detail="Push applied · pendulum continues under gravity" }
  else { fire() }
 }
 func fire() {
  guard !launched else { return }; launched=true; launchTime=elapsed
  // Preserve the source demo's launch-energy equation, scaled to the image's apparent dimensions.
  speed=sqrt(2*0.35*mass*9.81*0.25/0.05)*0.14
  detail=String(format:"Launch · %.2f kg · %.0f° · image-space speed %.2f m/s",mass,angle,speed)
  print("VISIONOS_FIRE mass=\(mass) speed=\(speed)")
 }
 func start() {
  guard timer==nil else {return}; started=Date.timeIntervalSinceReferenceDate; previous=started
  timer=Timer.scheduledTimer(withTimeInterval:1.0/60,repeats:true) { [weak self] _ in Task { @MainActor in self?.tick() } }
 }
 func updatePendulum() {
  Array(rod.children).forEach {$0.removeFromParent()}
  let p=point(258,62,0.029), length:Float=192*width/imageWidth
  let b=p+SIMD3<Float>(sin(pendTheta)*length,-cos(pendTheta)*length,0)
  _ = line(p,b,radius:0.007,color:.systemTeal,parent:rod); bob.position=b
 }
 func tick() {
  let now=Date.timeIntervalSinceReferenceDate, dt=Float(min(now-previous,0.035)); previous=now; elapsed=Float(now-started)
  let t=elapsed
  let stageIndex = t<14 ? 0 : t<27 ? 1 : t<40 ? 2 : 3
  if autoplay && stageIndex != lastStage { lastStage=stageIndex; switchMode(stageIndex) }
  let local=t-modeTime
  if autoplay && mode==0 && local>5 && coefficient==1 {action()}
  if autoplay && mode==1 && local>2 && !cartRunning {action()}
  if mode==1 && cartRunning {
   let tau=elapsed-cartStart, fraction=min(0.5*0.45*tau*tau,1)
   cart.position=point(310+460*fraction,235+49*fraction,0.033)
   if fraction==1 {detail="Cart reaches the bottom · released from rest, no initial push"}
  }
  if mode==2 {
   if autoplay && local>5 && !didPendulumPush { didPendulumPush=true; action() }
   pendOmega += -(9.81/1.0)*sin(pendTheta)*dt; pendOmega *= pow(0.995,dt*60); pendTheta += pendOmega*dt; updatePendulum()
  }
  if mode==3 {
   if autoplay && local>2 && !launched {fire()}
   if autoplay && local>8 && !didHighLaunch { didHighLaunch=true; switchMode(3); modeTime=t-8; mass=1; fire() }
   if launched {
    let tau=elapsed-launchTime, a:Float=angle * .pi/180, p0=point(175,165,0.07), gravity:Float=9.81*0.14
    let p=p0+SIMD3<Float>(speed*cos(a)*tau,speed*sin(a)*tau-0.5*gravity*tau*tau,0)
    shot.position=p; arm.orientation=simd_quatf(angle:-min(tau/0.6,1)*1.6,axis:[0,0,1])
    // Keep the visible trajectory on the source page, rather than drawing through the UI.
    if p.y > point(0,647).y && tau < 1.7 && tau-lastTrailTime > 0.035 {
     if let prior=trailPrevious { _ = line(prior,p,radius:0.003,color:.systemCyan,parent:trail) }
     trailPrevious=p; lastTrailTime=tau
    }
    for i in blocks.indices {
     if !knocked[i] && simd_distance(p,blockPositions[i])<0.055 {
      knocked[i]=true; blockVelocities[i]=[speed*0.4,0.07,0.12]
      // Transfer the impact to touching upper blocks (simple local rigid-block response).
      for j in blocks.indices where !knocked[j] && simd_distance(blockPositions[j],blockPositions[i])<0.10 { knocked[j]=true; blockVelocities[j]=[speed*0.25,0.06,0.11] }
     }
     if knocked[i] {
      blockVelocities[i].y -= gravity*dt; blocks[i].position += blockVelocities[i]*dt
      blocks[i].orientation *= simd_quatf(angle:dt*2.5,axis:[0.2,0.3,1])
      let floor=point(0,647).y; if blocks[i].position.y<floor {blocks[i].position.y=floor; blockVelocities[i].y=0; blockVelocities[i].x *= pow(0.88,dt*60); blockVelocities[i].z *= pow(0.88,dt*60)}
     }
    }
    if tau>3 {detail=String(format:"Counterweight %.2f kg · %d / 10 blocks displaced",mass,knocked.filter{$0}.count)}
    if p.y < -sheetHeight {shot.isEnabled=false} else {shot.isEnabled=true}
   }
  }
  // The image sheet and every augmentation are children of exactly one pose anchor.
  let moving = manualMotion || (autoplay && ((local>8 && mode != 3) || (mode==3 && local>13)))
  if moving {
   let phase=manualMotion ? local : max(local-8,0)
   paper.position=[0.10*sin(phase*0.65),1.70+0.035*sin(phase*0.8),-1.55+0.03*cos(phase*0.6)]
   paper.orientation=simd_quatf(angle:0.11*sin(phase*0.75),axis:[0,0,1])*simd_quatf(angle:0.32*sin(phase*0.55),axis:[0,1,0])
  }
  if Int(t*2) != lastSample {
   lastSample = Int(t*2)
   let q = paper.orientation.vector
   metrics.append(["time":t,"mode":mode,"paperPosition":[paper.position.x,paper.position.y,paper.position.z],"paperQuaternion":[q.x,q.y,q.z,q.w],"overlayChildCount":overlay.children.count,"sharedAnchor":overlay.parent === paper,"overlayLocalPosition":[overlay.position.x,overlay.position.y,overlay.position.z],"sourceImageName":paper.children.first(where:{$0.name.hasPrefix("SourceImage_")})?.name ?? "missing","counterweight":mass,"displaced":knocked.filter{$0}.count])
   if let data=try? JSONSerialization.data(withJSONObject:metrics,options:[.prettyPrinted,.sortedKeys]) {try? data.write(to:URL(fileURLWithPath:NSHomeDirectory()+"/Documents/visionos-demo-metrics.json"))}
  }
 }
}
