import UIKit
import SceneKit
import ARKit
import ReplayKit

func evidence(_ message: String) {
 print(message)
 let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("ar-evidence.log")
 let data = ("\(Date()) \(message)\n").data(using: .utf8)!
 if let h = try? FileHandle(forWritingTo: url) { h.seekToEndOfFile(); h.write(data); try? h.close() } else { try? data.write(to: url) }
}
@main class App: UIResponder, UIApplicationDelegate {
 func application(_ application: UIApplication, configurationForConnecting session: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
  let config = UISceneConfiguration(name: "Default", sessionRole: session.role); config.delegateClass = SceneDelegate.self; return config
 }
}
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
 var window: UIWindow?
 func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
  guard let scene = scene as? UIWindowScene else { return }
  window = UIWindow(windowScene: scene)
  #if MARKER_BENCH
  window?.rootViewController = ProcessInfo.processInfo.arguments.contains("--marker-bench") ? MarkerBench() : Demo()
  #else
  window?.rootViewController = Demo()
  #endif
  window?.makeKeyAndVisible()
 }
}
final class Demo: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
 let scene = SCNScene(), placement = SCNNode(), content = SCNNode()
 let sciencePages = SciencePages()
 var forcedCatalogMode: Bool?
 var catalogMode: Bool {forcedCatalogMode ?? (ProcessInfo.processInfo.arguments.contains("--science-pages") || UserDefaults.standard.bool(forKey:"paperlab-catalog-mode"))}
 var activeScienceID: String?
 var selectedScienceTargetID = UserDefaults.standard.string(forKey:"paperlab-selected-page")
 let pageSelector = UIButton(type:.system)
 var mathBinding = NativeMathBinding()
 var mathGraphDragging = false
 var adjustmentButtons: [UIButton] = []
 let interactionInstructions = UILabel()
 let sourceMathControls = UIStackView()
 weak var installedMathAdapter: (any NativeBoundMath)?
 var sourceMathInputAllowed:Bool {
  if !live {return true}
  guard selectedScienceTargetID==nil || selectedScienceTargetID==activeScienceID else{return false}
  return stability.sample(at:CACurrentMediaTime()).interactive
 }
 var textureVariantEnabled = false
 var sciencePaused = false
 let sciencePauseButton = UIButton(type: .system)
 let scienceReplayButton = UIButton(type: .system)
 let worldPinButton = UIButton(type: .system)
 var stability = TrackingStability()
 var presentationTick: CADisplayLink?
 var lastPresentationState: TrackingStability.State?
 let targetPolicy = UISegmentedControl(items: ["Moving image", "Fixed image", "World pin"])
 var canvas: SCNView!
 let status = UILabel(), values = UILabel()
 let modes = UISegmentedControl(items: ["Trebuchet", "Math"])
 let angle = UISlider(), mass = UISlider()
 var arm = SCNNode(), blocks: [SCNNode] = [], initial: [SCNVector3] = []
 var fired = false, live = false, coefficient: Float = 1
 var previewCamera: SCNNode?
 var lastScienceDiagnostic: Double = 0
 var minimumScienceFrameTime:Double = 0
 var lastDynamicsTime: Double?
 var cameraTrackingNormal=false
 var hasCameraFrame = false
 var anchor: UUID?
 var liveDemoScheduled = false, lastImageTracked: Bool?
 override func viewDidLoad() {
  super.viewDidLoad(); UIApplication.shared.isIdleTimerDisabled = true; view.backgroundColor = UIColor(red: 0.04, green: 0.07, blue: 0.12, alpha: 1)
  #if targetEnvironment(simulator)
  canvas = SCNView(); status.text = "SIMULATOR • mock image anchor • no camera tracking"
  #else
  let ar = ARSCNView(); ar.delegate = self; ar.session.delegate = self; canvas = ar
  status.text = "Preview • tap Start AR for real image tracking"
  #endif
  canvas.accessibilityIdentifier = "ARCanvas"; canvas.scene = scene; canvas.backgroundColor = view.backgroundColor; canvas.autoenablesDefaultLighting = true; canvas.isPlaying = true; canvas.allowsCameraControl = true
  scene.rootNode.addChildNode(placement); placement.addChildNode(content)
  if !ProcessInfo.processInfo.arguments.contains("--ar-live") && (!catalogMode || ProcessInfo.processInfo.arguments.contains("--science-preview")) { let camera = SCNNode(); camera.camera = SCNCamera(); camera.position = SCNVector3(1.2, 3.5, 6); camera.look(at: SCNVector3(0, 0.4, 0)); scene.rootNode.addChildNode(camera); canvas.pointOfView = camera; previewCamera = camera }
  scene.physicsWorld.gravity = SCNVector3(0, -9.81, 0)
  targetPolicy.overrideUserInterfaceStyle = .dark; targetPolicy.selectedSegmentIndex = ProcessInfo.processInfo.arguments.contains("--fixed-target") ? 1 : 0
  stability.policy = targetPolicy.selectedSegmentIndex == 1 ? .fixed : .moving
  targetPolicy.addTarget(self, action: #selector(changeTargetPolicy), for: .valueChanged)
  modes.overrideUserInterfaceStyle = .dark; modes.selectedSegmentIndex = 0; modes.addTarget(self, action: #selector(reset), for: .valueChanged)
  angle.minimumValue = 20; angle.maximumValue = 65; angle.value = 40
  mass.minimumValue = 0.25; mass.maximumValue = 1; mass.value = 0.48
  for slider in [angle, mass] { slider.addTarget(self, action: #selector(parameters), for: .valueChanged) }
  let buttons = UIStackView(); buttons.distribution = .fillEqually; buttons.spacing = 10
  for (title, action) in [("Launch / Plot", #selector(launch)), ("Reset", #selector(reset)), ("Move mock anchor", #selector(moveAnchor)), ("Start AR", #selector(startAR))] {
   let button = UIButton(type: .system); button.setTitle(title, for: .normal); button.addTarget(self, action: action, for: .touchUpInside); buttons.addArrangedSubview(button)
  }
  for label in [status, values] { label.textColor = .white; label.font = .systemFont(ofSize: UIDevice.current.userInterfaceIdiom == .phone ? 12 : 15, weight: .medium); label.numberOfLines = 2 }
  let title = UILabel(); title.text = "Paper Lab · Apple Native Prototype"; title.textColor = .white; title.font = .boldSystemFont(ofSize: UIDevice.current.userInterfaceIdiom == .phone ? 18 : 26)
  let scienceLayout = catalogMode
  let catalogSwitch = UIButton(type:.system);catalogSwitch.setTitle(scienceLayout ? "Legacy Math / Physics" : "Open AR catalog",for:.normal);catalogSwitch.addTarget(self,action:#selector(switchCatalogMode),for:.touchUpInside)
  if let i=ProcessInfo.processInfo.arguments.firstIndex(of:"--science-target"),ProcessInfo.processInfo.arguments.count>i+1 {selectedScienceTargetID=ProcessInfo.processInfo.arguments[i+1]}
  configurePageSelector()
  let catalogNavigation=UIStackView(arrangedSubviews:[catalogSwitch,pageSelector]);catalogNavigation.distribution = .fillEqually;catalogNavigation.spacing=8
  let scienceControls = UIStackView(); scienceControls.distribution = .fillEqually
  sciencePauseButton.setTitle("Pause motion", for: .normal); sciencePauseButton.addTarget(self, action: #selector(toggleScienceMotion), for: .touchUpInside)
  scienceControls.addArrangedSubview(sciencePauseButton)
  worldPinButton.setTitle("Pin page",for:.normal);worldPinButton.addTarget(self,action:#selector(toggleWorldPin),for:.touchUpInside);scienceControls.addArrangedSubview(worldPinButton)
  let replay = scienceReplayButton; replay.setTitle("Replay pop-out", for: .normal); replay.addTarget(self, action: #selector(replayScience), for: .touchUpInside); scienceControls.addArrangedSubview(replay)
  let adjustments = UIStackView(); adjustments.distribution = .fillEqually
  for (title, action) in [("Rotate +30°", #selector(stepRotation)), ("Scale +20%", #selector(stepScale)), ("Move right", #selector(stepMove)), ("Compare texture", #selector(compareTexture))] { let b=UIButton(type:.system);b.setTitle(title,for:.normal);b.addTarget(self,action:action,for:.touchUpInside);adjustments.addArrangedSubview(b);adjustmentButtons.append(b) }
  let instructions = interactionInstructions; instructions.text = "Drag: rotate · two fingers: move · pinch: resize · tap model: pause"; instructions.textColor = .white; instructions.font = .systemFont(ofSize: 11); instructions.numberOfLines = 2
  let rotate = UIPanGestureRecognizer(target:self, action:#selector(rotateScience(_:))); rotate.maximumNumberOfTouches = 1; canvas.addGestureRecognizer(rotate)
  let move = UIPanGestureRecognizer(target:self, action:#selector(moveScience(_:))); move.minimumNumberOfTouches = 2; move.maximumNumberOfTouches = 2; canvas.addGestureRecognizer(move)
  canvas.addGestureRecognizer(UIPinchGestureRecognizer(target:self, action:#selector(scaleScience(_:))))
  canvas.addGestureRecognizer(UITapGestureRecognizer(target:self, action:#selector(tapScience(_:))))
  if scienceLayout { canvas.allowsCameraControl = false }
  sourceMathControls.axis = .vertical;sourceMathControls.isHidden=true
  let stack = UIStackView(arrangedSubviews: scienceLayout ? [title, catalogNavigation, status, canvas, values, instructions, sourceMathControls, scienceControls, adjustments] : [title, catalogSwitch, status, modes, targetPolicy, canvas, values, angle, mass, buttons]); stack.axis = .vertical; stack.spacing = UIDevice.current.userInterfaceIdiom == .phone ? 5 : 12; stack.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(stack)
  #if MARKER_BENCH
  let markerEntry=UIButton(type:.system);markerEntry.setTitle("Open interactive paper lessons",for:.normal);markerEntry.accessibilityIdentifier="OpenMarkerLab";markerEntry.addTarget(self,action:#selector(openMarkerLab),for:.touchUpInside);stack.insertArrangedSubview(markerEntry,at:1)
  #endif
  NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6), stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6), stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24), stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24), canvas.heightAnchor.constraint(greaterThanOrEqualToConstant: UIDevice.current.userInterfaceIdiom == .phone ? 80 : 350), buttons.heightAnchor.constraint(equalToConstant: 36)])
  if ProcessInfo.processInfo.arguments.contains("--validate-catalog") { DispatchQueue.global(qos: .utility).async { self.sciencePages.validateMeshes() } }
  reset()
  let args = ProcessInfo.processInfo.arguments
  if args.contains("--science-tour") {
   for (index, page) in sciencePages.entries.enumerated() {
    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index)*4) {
     self.activeScienceID = page.id; self.reset()
     self.status.text = "PREVIEW • no optical tracking • " + page.title
     self.values.text = "Actual inferred mesh • authored English page • scripted visualization"
    }
   }
  }
  if let index = args.firstIndex(of: "--science-preview"), args.count > index+1, let page = sciencePages.entries.first(where: { $0.id == args[index+1] }) {
   activeScienceID = page.id; reset(); if sciencePages.diagramPhysicsAdapter != nil,let camera=previewCamera {camera.position=SCNVector3(0,10,0.001);camera.look(at:SCNVector3Zero);camera.camera?.usesOrthographicProjection=true;camera.camera?.orthographicScale=4.6}; status.text = sciencePages.diagramPhysicsAdapter != nil ? "OFFLINE PREVIEW • original source pixels / authored numerical physics • no tracking" : "PREVIEW • no optical tracking • inferred geometry / scripted animation"
  }
  presentationTick = CADisplayLink(target: self, selector: #selector(updatePresentation)); presentationTick?.add(to: .main, forMode: .common)
  if ProcessInfo.processInfo.arguments.contains("--demo") { scheduleDemo() }
  #if !targetEnvironment(simulator)
  if ProcessInfo.processInfo.arguments.contains("--ar-live") || (catalogMode && !args.contains("--science-preview") && !args.contains("--science-tour")) { DispatchQueue.main.asyncAfter(deadline: .now()+0.6) { self.startAR() } }
  #endif
 }
 #if MARKER_BENCH
 @objc func openMarkerLab(){presentationTick?.invalidate();presentationTick=nil;(canvas as? ARSCNView)?.session.pause();view.window?.rootViewController=MarkerBench()}
 #endif
 override func viewWillAppear(_ animated: Bool) {
  super.viewWillAppear(animated)
  if presentationTick == nil {presentationTick=CADisplayLink(target:self,selector:#selector(updatePresentation));presentationTick?.add(to:.main,forMode:.common)}
  if live {(canvas as? ARSCNView)?.session.pause();startAR()}
 }
 override func viewWillDisappear(_ animated: Bool) {
  super.viewWillDisappear(animated); presentationTick?.invalidate(); presentationTick = nil
  (canvas as? ARSCNView)?.session.pause(); stability.reset()
 }
 func configurePageSelector() {
  let selected=sciencePages.entries.first{$0.id==selectedScienceTargetID}
  if selected==nil {selectedScienceTargetID=nil}
  pageSelector.setTitle(selected.map{"Scan: "+$0.title} ?? "Choose page",for:.normal)
  pageSelector.titleLabel?.font = .systemFont(ofSize:12);pageSelector.accessibilityIdentifier="ChoosePage"
  pageSelector.showsMenuAsPrimaryAction=false;pageSelector.menu=nil
  pageSelector.removeTarget(self,action:#selector(showPagePicker),for:.touchUpInside)
  pageSelector.addTarget(self,action:#selector(showPagePicker),for:.touchUpInside)

 }
 @objc func showPagePicker() {
  let picker=NativePagePicker(entries:sciencePages.entries,selectedID:selectedScienceTargetID){[weak self] id in self?.selectScienceTarget(id)}
  present(UINavigationController(rootViewController:picker),animated:true)
 }
 func selectScienceTarget(_ id:String?) {
  selectedScienceTargetID=id;UserDefaults.standard.set(id,forKey:"paperlab-selected-page")
  activeScienceID=nil;sciencePages.domainAdapter=nil;sciencePages.physicsAdapter=nil;sciencePages.diagramPhysicsAdapter=nil;sciencePages.sourceMathAdapter=nil;sciencePages.triangleAdapter=nil;values.text="Point the camera at the selected page"
  content.childNodes.forEach{$0.removeFromParentNode()}
  configurePageSelector();updateContentControls()
  interactionInstructions.text="Point the camera at the selected page; controls activate after recognition"
  evidence("SCIENCE_SCAN_SELECTION id=\(id ?? "automatic") input=UI")
  if catalogMode {startAR()}
 }
 func scienceModel() -> SCNNode? { content.childNode(withName: "science-interaction", recursively: true) }
 func resetScienceInteraction() {
  sciencePaused = false; sciencePauseButton.setTitle("Pause motion", for:.normal)
 }
 @objc func compareTexture() {guard sourceMathInputAllowed else{return};if let physics=sciencePages.diagramPhysicsAdapter {guard sourceMathInputAllowed else{return};physics.compareReference();return};guard let id=activeScienceID,sciencePages.entries.contains(where:{$0.id==id && ($0.variantMesh != nil || ["rx-car","rx-butterfly"].contains(id))}) else{values.text="Texture comparison available on primary-nine, car and butterfly pages";return};textureVariantEnabled.toggle();reset();values.text=textureVariantEnabled ? "Hunyuan2mini + Paint UV texture · precomputed" : "TripoSR vertex color · precomputed";evidence("SCIENCE_INTERACTION action=texture-compare enabled=\(textureVariantEnabled) id=\(id) input=UI") }
 @objc func switchCatalogMode() {
  let next = !catalogMode;UserDefaults.standard.set(next,forKey:"paperlab-catalog-mode");evidence("CATALOG_MODE_INPUT catalog=\(next) input=UI persisted=true")
  presentationTick?.invalidate();presentationTick=nil;(canvas as? ARSCNView)?.session.pause()
  let nextController=Demo();nextController.forcedCatalogMode=next;view.window?.rootViewController=nextController
 }
 @objc func stepRotation() {guard sourceMathInputAllowed else{return}; if let domain=sciencePages.domainAdapter {guard sourceMathInputAllowed else{return};domain.parameter(0.1);values.text=domain.description;return}; if let physics=sciencePages.diagramPhysicsAdapter {guard sourceMathInputAllowed else{return};physics.primaryControl();values.text=physics.description;evidence("SOURCE_DIAGRAM_INPUT action=primaryControl model=\(physics.description) input=UI");return}; if let physics=sciencePages.physicsAdapter {physics.primaryControl();values.text=physics.description;evidence("SOURCE_PHYSICS_INPUT action=primary parameter=\(physics.description) input=UI");return}; if activeScienceID=="original-math-quadratic" {mathBinding.setCoefficient(mathBinding.coefficient+0.25);updateMathBinding(input:"coefficient-increase-button");return}; guard let n=scienceModel() else{return};n.eulerAngles.y += .pi/6;evidence("SCIENCE_INTERACTION action=rotate-button yaw=\(n.eulerAngles.y) id=\(activeScienceID ?? "none") input=UI") }
 @objc func stepScale() {guard sourceMathInputAllowed else{return}; if let domain=sciencePages.domainAdapter {guard sourceMathInputAllowed else{return};domain.parameter(-0.1);values.text=domain.description;return}; if let physics=sciencePages.diagramPhysicsAdapter {guard sourceMathInputAllowed else{return};physics.secondaryControl();values.text=physics.description;evidence("SOURCE_DIAGRAM_INPUT action=secondaryControl model=\(physics.description) input=UI");return}; if let physics=sciencePages.physicsAdapter {physics.secondaryControl();values.text=physics.description;evidence("SOURCE_PHYSICS_INPUT action=secondary parameter=\(physics.description) input=UI");return}; if activeScienceID=="original-math-quadratic" {mathBinding.setCoefficient(mathBinding.coefficient-0.25);updateMathBinding(input:"coefficient-decrease-button");return}; guard let n=scienceModel() else{return};let v=min(Float(2.5),n.scale.x*1.2);n.scale=SCNVector3(v,v,v);evidence("SCIENCE_INTERACTION action=scale-button value=\(v) id=\(activeScienceID ?? "none") input=UI") }
 @objc func stepMove() {guard sourceMathInputAllowed else{return}; if let domain=sciencePages.domainAdapter {guard sourceMathInputAllowed else{return};domain.event();values.text=domain.description;return}; if let physics=sciencePages.diagramPhysicsAdapter {guard sourceMathInputAllowed else{return};physics.tertiaryControl();values.text=physics.description;evidence("SOURCE_DIAGRAM_INPUT action=tertiaryControl model=\(physics.description) input=UI");return}; if let physics=sciencePages.physicsAdapter {physics.reset();values.text=physics.description;evidence("SOURCE_PHYSICS_INPUT action=reset input=UI");return}; if activeScienceID=="original-math-quadratic" {mathBinding=NativeMathBinding();updateMathBinding(input:"reset-print-coefficient-button");return}; guard let n=scienceModel() else{return};n.position.x += 0.4;evidence("SCIENCE_INTERACTION action=move-button x=\(n.position.x) id=\(activeScienceID ?? "none") input=UI") }
 @objc func toggleScienceMotion() {
  guard sourceMathInputAllowed else{return}
  guard let node = scienceModel() else { return }
  sciencePaused.toggle(); node.isPaused = sciencePaused
  sciencePauseButton.setTitle(sciencePaused ? "Resume motion" : "Pause motion", for:.normal)
  evidence("SCIENCE_INTERACTION action=pause paused=\(sciencePaused) id=\(activeScienceID ?? "none") input=UI")
 }
 @objc func replayScience() {
  guard sourceMathInputAllowed else{return}
  guard activeScienceID != nil else { return }; resetScienceInteraction(); reset()
  evidence("SCIENCE_INTERACTION action=replay id=\(activeScienceID ?? "none") input=UI")
 }
 func updateMathBinding(input:String) {
  guard activeScienceID=="original-math-quadratic" else{return};content.childNodes.forEach{$0.removeFromParentNode()};if let node=sciencePages.makeContent(id:"original-math-quadratic",mathBinding:mathBinding){content.addChildNode(node)}
  values.text=mathBinding.equation+" · cyan controlled curve / original pink reference";evidence("MATH_BINDING_INPUT action=\(input) a=\(mathBinding.coefficient) selected=\(mathBinding.selected) vertex=\(mathBinding.vertexX),\(mathBinding.vertexY) input=UI")
 }
 func refreshSourceMath(input:String) {
  guard sourceMathInputAllowed,let adapter=sciencePages.mathInputAdapter,activeScienceID==adapter.pageID else{return}
  content.childNode(withName:"science-interaction",recursively:false)?.removeFromParentNode();content.addChildNode(adapter.makeNode())
  values.text=adapter.description
  evidence("SOURCE_MATH_INPUT id=\(adapter.pageID) action=\(input) model=\(adapter.description) input=UI trackingMeasured=\(live && stability.sample(at:CACurrentMediaTime()).interactive)")
 }
 func extensionMathPixel(_ location:CGPoint)->CGPoint? {
  guard let adapter=sciencePages.mathInputAdapter,let hit=canvas.hitTest(location,options:nil).first(where:{$0.node.name=="original-source-math-page-overlay"}) else{return nil}
  return adapter.sourcePixel(localPlane:hit.localCoordinates)
 }
 func updateContentControls() {
  scienceReplayButton.setTitle(sciencePages.diagramPhysicsAdapter == nil ? "Replay pop-out":"Reset fixture",for:.normal)
  let adapter=sciencePages.mathInputAdapter
  if installedMathAdapter !== adapter {
   sourceMathControls.arrangedSubviews.forEach{sourceMathControls.removeArrangedSubview($0);$0.removeFromSuperview()}
   installedMathAdapter=adapter
   if let adapter {
    adapter.inputAllowed = {[weak self,weak adapter] in guard let self,let adapter else{return false};return self.sourceMathInputAllowed && self.activeScienceID==adapter.pageID}
    sourceMathControls.addArrangedSubview(adapter.makeControls());adapter.onChange={[weak self] input in self?.refreshSourceMath(input:input)}
   }
  }
  sourceMathControls.isHidden=adapter==nil;sourceMathControls.isUserInteractionEnabled=sourceMathInputAllowed
  adjustmentButtons.forEach{$0.isHidden=adapter != nil}
  sciencePauseButton.isHidden=adapter != nil
  if let adapter {interactionInstructions.text=adapter.interactionInstructions;values.text=adapter.description;return}

  if let domain=sciencePages.domainAdapter {
   for (button,title) in zip(adjustmentButtons,["Parameter +10%","Parameter −10%",["drive","walk","swim"].contains(domain.action) ? "Reset path" : "Next stage","Compare texture"]){button.setTitle(title,for:.normal)}
   values.text=domain.description;interactionInstructions.text="Inferred appearance + authored teaching parts · parameter changes mechanism · stage event · pause/reset";return
  }
  if let physics=sciencePages.diagramPhysicsAdapter {for (button,title) in zip(adjustmentButtons,physics.titles){button.setTitle(title,for:.normal);button.titleLabel?.font = .systemFont(ofSize:12);button.titleLabel?.numberOfLines=2;button.titleLabel?.textAlignment = .center};values.text=physics.description;interactionInstructions.text=physics.interactionInstructions;return}
  let originalMath=activeScienceID=="original-math-quadratic"
  let sourcePhysics=sciencePages.physicsAdapter
  let physicsTitles=(sourcePhysics?.isSpring ?? false) ? ["Stiffness +25%","Mass +25%","Reset dynamics","Compare texture"] : ["Slope +5°","Friction +0.05","Reset dynamics","Compare texture"]
  let titles=sourcePhysics != nil ? physicsTitles : originalMath ? ["a +0.25","a −0.25","Reset printed a=1","Compare texture"] : ["Rotate +30°","Scale +20%","Move right","Compare texture"]
  for (button,title) in zip(adjustmentButtons,titles){button.setTitle(title,for:.normal)}
  interactionInstructions.text=sourcePhysics != nil ? "Original segmented diagram · explicit SI teaching dynamics · change parameters / reset / pause" : originalMath ? "Tap equation/graph: show binding · drag: change linked coefficient · cyan curve / pink printed reference" : "Drag: rotate · two fingers: move · pinch: resize · tap model: pause"
 }
 func sourceMathPixel(_ location:CGPoint)->CGPoint? {
  guard let hit=canvas.hitTest(location,options:nil).first(where:{$0.node.name=="original-math-page-overlay"}) else{return nil}
  let height=5.7*1541.0/1284.0
  return CGPoint(x:(Double(hit.localCoordinates.x)/5.7+0.5)*1284,y:(0.5-Double(hit.localCoordinates.y)/height)*1541)
 }
 @objc func tapScience(_ gesture: UITapGestureRecognizer) {
  guard sourceMathInputAllowed else{return}
  if let adapter=sciencePages.mathInputAdapter {guard sourceMathInputAllowed,let pixel=extensionMathPixel(gesture.location(in:canvas)) else{return};adapter.tap(pixel:pixel);return}
  if activeScienceID=="original-math-quadratic" {
   guard let pixel=sourceMathPixel(gesture.location(in:canvas)),CGRect(x:835,y:600,width:195,height:28).contains(pixel) || CGRect(x:842,y:780,width:244,height:204).contains(pixel) else{return}
   mathBinding.selected.toggle();updateMathBinding(input:"select-printed-equation-graph");return
  }
  guard scienceModel() != nil else { return }
  let hits = canvas.hitTest(gesture.location(in:canvas), options:nil)
  if hits.contains(where: { hit in var node: SCNNode? = hit.node; while let current = node { if current.name == "science-interaction" { return true }; node=current.parent }; return false }) { toggleScienceMotion() }
 }
 @objc func rotateScience(_ gesture: UIPanGestureRecognizer) {
  guard sourceMathInputAllowed else {sciencePages.mathInputAdapter?.endDrag();mathGraphDragging=false;gesture.setTranslation(.zero,in:canvas);return}
  if let adapter=sciencePages.diagramPhysicsAdapter {guard sourceMathInputAllowed,let hit=canvas.hitTest(gesture.location(in:canvas),options:nil).first(where:{$0.node.name=="original-source-physics-overlay"}) else{return};adapter.drag(pixel:adapter.sourcePixel(hit.localCoordinates));values.text=adapter.description;return}
  if let adapter=sciencePages.mathInputAdapter {
   guard sourceMathInputAllowed else{adapter.endDrag();return}
   if let pixel=extensionMathPixel(gesture.location(in:canvas)) {if gesture.state == .began {adapter.beginDrag(pixel:pixel)}else{adapter.drag(pixel:pixel)}}
   if gesture.state == .ended || gesture.state == .cancelled {adapter.endDrag()};return
  }
  if activeScienceID=="original-math-quadratic" {
   let pixel=sourceMathPixel(gesture.location(in:canvas))
   if gesture.state == .began {mathGraphDragging=pixel.map {CGRect(x:842,y:780,width:244,height:204).contains($0)} ?? false}
   guard mathGraphDragging else{return}
   if let pixel {let x=(Double(pixel.x)-1033)/26.5,y=(949-Double(pixel.y))/26.5;if mathBinding.graphDrag(x:x,y:y){updateMathBinding(input:"inverse-graph-drag-linked-coefficient")}}
   if gesture.state == .ended || gesture.state == .cancelled {mathGraphDragging=false};return
  }
  guard let node = scienceModel() else { return }
  let delta = gesture.translation(in:canvas); node.eulerAngles.y += Float(delta.x / max(canvas.bounds.width,1)) * .pi * 2
  gesture.setTranslation(.zero,in:canvas)
  if gesture.state == .ended { evidence("SCIENCE_INTERACTION action=rotate yaw=\(node.eulerAngles.y) id=\(activeScienceID ?? "none") input=touch") }
 }
 @objc func moveScience(_ gesture: UIPanGestureRecognizer) {
  guard sourceMathInputAllowed else{gesture.setTranslation(.zero,in:canvas);return}
  guard sciencePages.mathInputAdapter==nil else{return}
  guard let node = scienceModel() else { return }
  let delta = gesture.translation(in:canvas)
  node.position.x = min(2.5,max(-2.5,node.position.x + Float(delta.x / max(canvas.bounds.width,1))*5.7))
  node.position.z = min(2.5,max(-2.5,node.position.z + Float(delta.y / max(canvas.bounds.height,1))*5.7))
  gesture.setTranslation(.zero,in:canvas)
  if gesture.state == .ended { evidence("SCIENCE_INTERACTION action=move x=\(node.position.x) z=\(node.position.z) id=\(activeScienceID ?? "none") input=touch") }
 }
 @objc func scaleScience(_ gesture: UIPinchGestureRecognizer) {
  guard sourceMathInputAllowed else{gesture.scale=1;return}
  guard sciencePages.mathInputAdapter==nil else{return}
  guard let node = scienceModel() else { return }
  let size = min(Float(2.5),max(Float(0.5),node.scale.x * Float(gesture.scale)))
  node.scale = SCNVector3(size,size,size); gesture.scale = 1
  if gesture.state == .ended { evidence("SCIENCE_INTERACTION action=scale value=\(size) id=\(activeScienceID ?? "none") input=touch") }
 }
 func box(_ size: SCNVector3, _ p: SCNVector3, _ color: UIColor, parent: SCNNode? = nil, dynamic: Bool = false) -> SCNNode {
  let geometry = SCNBox(width: CGFloat(size.x), height: CGFloat(size.y), length: CGFloat(size.z), chamferRadius: 0.005)
  geometry.firstMaterial?.diffuse.contents = color; let node = SCNNode(geometry: geometry); node.position = p; (parent ?? content).addChildNode(node)
  if dynamic { node.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: geometry, options: [.collisionMargin: 0.001])); node.physicsBody?.mass = 0.012; node.physicsBody?.friction = 0.18; node.physicsBody?.restitution = 0.035 }
  return node
 }
 @objc func reset() {
  updateContentControls()
  if let id = activeScienceID {
   resetScienceInteraction()
   content.childNodes.forEach { $0.removeFromParentNode() }
   if let node = sciencePages.makeContent(id:id,textureVariant:textureVariantEnabled,mathBinding:mathBinding) { content.addChildNode(node) }
   updateContentControls()
   if !live, let page = sciencePages.entries.first(where: { $0.id == id }), let image = UIImage(contentsOfFile: sciencePages.directory.appendingPathComponent(page.page).path) {
    let geometry = SCNPlane(width:5.7, height:5.7*image.size.height/image.size.width); geometry.firstMaterial?.diffuse.contents=image; geometry.firstMaterial?.isDoubleSided=true
    if sciencePages.diagramPhysicsAdapter != nil {geometry.firstMaterial?.lightingModel = .constant};let paper = SCNNode(geometry:geometry); paper.eulerAngles.x = -.pi/2; paper.position.y = -0.02; content.addChildNode(paper)
   }
   return
  }
  content.childNodes.forEach { $0.removeFromParentNode() }; blocks = []; initial = []; fired = false
  let floor = box(SCNVector3(6, 0.03, 3), SCNVector3(0, -0.025, 0), .darkGray); floor.physicsBody = .static(); if live { floor.geometry?.firstMaterial?.transparency = 0; floor.geometry?.firstMaterial?.writesToDepthBuffer = false }
  let targetImage = UIImage(named: modes.selectedSegmentIndex == 0 ? "trebuchet.png" : "math.png")!
  let paper = SCNPlane(width: 5.7, height: 5.7 * targetImage.size.height / targetImage.size.width); paper.firstMaterial?.diffuse.contents = targetImage; paper.firstMaterial?.isDoubleSided = true
  let sheet = SCNNode(geometry: paper); sheet.eulerAngles.x = -.pi / 2; sheet.position.y = -0.005; content.addChildNode(sheet); sheet.isHidden = live
  if modes.selectedSegmentIndex == 1 { plot(); return }
  let wood = UIColor(red: 0.75, green: 0.5, blue: 0.23, alpha: 1)
  for z: Float in [-0.24, 0.24] {
   _ = box(SCNVector3(1.2, 0.08, 0.08), SCNVector3(-1.5, 0.16, z), wood)
   _ = box(SCNVector3(0.08, 0.65, 0.08), SCNVector3(-1.5, 0.38, z), wood)
  }
  arm = SCNNode(); arm.position = SCNVector3(-1.5, 0.7, 0); content.addChildNode(arm)
  _ = box(SCNVector3(1.24, 0.06, 0.07), SCNVector3(-0.32, 0, 0), wood, parent: arm)
  _ = box(SCNVector3(0.19, 0.19, 0.22), SCNVector3(0.3, -0.24, 0), .systemGray, parent: arm); arm.eulerAngles.z = 28 * .pi / 180
  for row in 0..<4 { for column in 0..<(4-row) {
   let p = SCNVector3(1.18, 0.123 + Float(row)*0.247, (Float(column)-Float(3-row)/2)*0.252)
   blocks.append(box(SCNVector3(0.2, 0.245, 0.245), p, .systemOrange, dynamic: true)); initial.append(p)
  }}
  updateText()
 }
 @objc func parameters() { coefficient = (angle.value - 42.5)/15; reset() }
 func updateText() { values.text = modes.selectedSegmentIndex == 0 ? String(format: "Angle %.0f° · counterweight %.2f kg · projectile 0.05 kg", angle.value, mass.value) : String(format: "y = %.2f x² · change the first slider to reshape the graph", coefficient) }
 func plot() {
  for i in -60...60 { let x = Float(i)/30; let y = coefficient*x*x*0.25
   let dot = SCNNode(geometry: SCNSphere(radius: 0.025)); dot.geometry?.firstMaterial?.diffuse.contents = UIColor.systemCyan; dot.position = SCNVector3(x, 0.03, -y); content.addChildNode(dot)
  }; updateText()
 }
 @objc func launch() {
  if live, !stability.sample(at: CACurrentMediaTime()).measured { values.text = "Wait for measured image tracking before launching"; return }
  if modes.selectedSegmentIndex == 1 { coefficient = coefficient == 1 ? -0.7 : 1; reset(); return }
  guard !fired else { return }; fired = true
  let a = angle.value * .pi/180, speed = sqrt(2 * 0.35 * mass.value * 9.81 * 0.25 / 0.05)
  arm.runAction(.rotateTo(x: 0, y: 0, z: CGFloat(-150 * Float.pi/180), duration: 0.65))
  let projectile = SCNNode(geometry: SCNSphere(radius: 0.075)); projectile.geometry?.firstMaterial?.diffuse.contents = UIColor.systemCyan
  projectile.position = SCNVector3(-1.5-0.89*sin(a), 0.7+0.89*cos(a), 0); content.addChildNode(projectile)
  projectile.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil); projectile.physicsBody?.mass = 0.05; projectile.physicsBody?.damping = 0; projectile.physicsBody?.restitution = 0.17; projectile.physicsBody?.continuousCollisionDetectionThreshold = 0.01
  let unitScale: Float = live ? 0.21/5.7 : 1
  projectile.physicsBody?.velocity = content.convertVector(SCNVector3(speed*cos(a), speed*sin(a), 0), to: nil)
  scene.physicsWorld.gravity = live ? content.convertVector(SCNVector3(0, -9.81, 0), to: nil) : SCNVector3(0, -9.81*unitScale, 0)
  values.text = String(format: "Launched at %.2f m/s • SceneKit gravity + rigid-body collisions", speed)
  DispatchQueue.main.asyncAfter(deadline: .now()+4) { [weak self] in
   guard let self, self.fired else { return }
   var count = 0
   for (block, start) in zip(self.blocks, self.initial) {
    let p = block.presentation.position
    if abs(p.x - start.x) > Float(0.13) || abs(p.z - start.z) > Float(0.15) || p.y < start.y - Float(0.10) { count += 1 }
   }
   self.values.text = "\(count)/10 blocks displaced • Reset to compare settings"
   evidence("VERIFIED_PHYSICS mass=\(self.mass.value) speed=\(speed) displaced=\(count)")
  }
 }
 @objc func moveAnchor() {
  guard !live else { return }
  content.runAction(.group([.moveBy(x: 0.3, y: 0, z: 0.15, duration: 0.6), .rotateBy(x: 0, y: .pi/15, z: 0, duration: 0.6)]))
 }
 @objc func startAR() {
  #if targetEnvironment(simulator)
  status.text = "Simulator has NO live ARKit image tracking. Mock anchor only."
  #else
  guard ARWorldTrackingConfiguration.isSupported, let ar = canvas as? ARSCNView else { status.text = "ARKit unavailable on this device"; return }
  let preserveWorldTracking=live
  var images = Set<ARReferenceImage>()
  for name in (catalogMode && selectedScienceTargetID != nil ? [] : (catalogMode ? ["trebuchet"] : ["math", "trebuchet"])) { if let cg = UIImage(named: name+".png")?.cgImage { let ref = ARReferenceImage(cg, orientation: .up, physicalWidth: 0.21); ref.name = name; images.insert(ref) } }
  images.formUnion(sciencePages.referenceImages(selectedID:catalogMode ? selectedScienceTargetID : nil))
  let config = ARWorldTrackingConfiguration(); config.detectionImages = images; config.maximumNumberOfTrackedImages = 1
  previewCamera?.removeFromParentNode(); previewCamera = nil;
  content.removeAllActions()
  minimumScienceFrameTime=CACurrentMediaTime()
  stability.reset(); cameraTrackingNormal=false; anchor = nil; lastPresentationState = nil; placement.simdTransform = matrix_identity_float4x4; placement.isHidden = true; content.isHidden = false; content.opacity = 1
  evidence("REAL_AR_STARTED policy=\(stability.policy.rawValue) selectedPage=\(selectedScienceTargetID ?? "automatic") targetCount=\(images.count)")
  live = true; canvas.allowsCameraControl = false; canvas.backgroundColor = .clear
  if ProcessInfo.processInfo.arguments.contains("--image-only"), ARImageTrackingConfiguration.isSupported {
   let imageConfig = ARImageTrackingConfiguration(); imageConfig.trackingImages = images; imageConfig.maximumNumberOfTrackedImages = 1
   ar.session.run(imageConfig, options: preserveWorldTracking ? [.removeExistingAnchors] : [.resetTracking, .removeExistingAnchors]); evidence("SCIENCE_CONFIGURATION mode=ARImageTrackingConfiguration")
  } else { ar.session.run(config, options: preserveWorldTracking ? [.removeExistingAnchors] : [.resetTracking, .removeExistingAnchors]); evidence("SCIENCE_CONFIGURATION mode=ARWorldTrackingConfiguration") }
   status.text = "REAL ARKit • looking for selected image"
  #endif
 }
 func session(_ session: ARSession, didUpdate frame: ARFrame) {
  let normal: Bool
  if case .normal = frame.camera.trackingState { normal = true } else { normal = false }
  let images = frame.anchors.compactMap { $0 as? ARImageAnchor }
  let captureTime = frame.timestamp
  if captureTime - lastScienceDiagnostic >= 2 {
   lastScienceDiagnostic = captureTime
   evidence("SCIENCE_FRAME_DIAGNOSTIC images=\(images.count) tracked=\(images.filter { $0.isTracked }.count) camera=\(frame.camera.trackingState) age=\(CACurrentMediaTime()-captureTime)")
  }
  DispatchQueue.main.async {
   // Queued old camera frames cannot refresh a held pose's lifetime.
   guard self.live, captureTime >= self.minimumScienceFrameTime, CACurrentMediaTime() - captureTime <= self.stability.observationTimeout else { return }
   self.cameraTrackingNormal=normal
   self.stability.setCameraReliable(normal)
   guard normal else { self.updatePresentation(); return }
   let acceptedImages = images.filter { !self.catalogMode || self.selectedScienceTargetID==nil || $0.referenceImage.name==self.selectedScienceTargetID }
   let selected = acceptedImages.first { $0.identifier == self.anchor }
   // Keep one physical image; switch only after ARKit actually tracks another.
   if let image = selected, image.isTracked { self.observeImage(image, at: captureTime) }
   else if let image = acceptedImages.first(where: { $0.isTracked }) { self.observeImage(image, at: captureTime) }
   else if let image = selected { self.observeImage(image, at: captureTime) }
   else { self.stability.markLost() }
  }
  guard !hasCameraFrame else { return }; hasCameraFrame = true
  let ci = CIImage(cvPixelBuffer: frame.capturedImage)
  if let cg = CIContext().createCGImage(ci, from: ci.extent), let data = UIImage(cgImage: cg).jpegData(compressionQuality: 0.85) {
   let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("camera-diagnostic.jpg")
   try? data.write(to: url)
   evidence("REAL_CAMERA_DIAGNOSTIC_SAVED")
  }
  evidence("REAL_AR_CAMERA_FRAME width=\(CVPixelBufferGetWidth(frame.capturedImage)) height=\(CVPixelBufferGetHeight(frame.capturedImage))")
 }
 func session(_ session: ARSession, didFailWithError error: Error) {
  evidence("REAL_AR_SESSION_FAILED \(error.localizedDescription)")
  DispatchQueue.main.async { self.cameraTrackingNormal=false; self.stability.setCameraReliable(false); self.updatePresentation(); self.status.text = "ARKit: \(error.localizedDescription)" }
 }
 func observeImage(_ image: ARImageAnchor, at time: Double) {
  // Previously queued anchors from another selected page must not resurrect stale controls or pose.
  if catalogMode,let requested=selectedScienceTargetID,image.referenceImage.name != requested {return}
  if anchor != image.identifier {
   guard image.isTracked else { return }
   anchor = image.identifier; stability.reset(); lastImageTracked = nil
   if let name = image.referenceImage.name, sciencePages.entries.contains(where: { $0.id == name }) {
    activeScienceID = name
    updateContentControls()
    resetScienceInteraction()
    content.childNodes.forEach { $0.removeFromParentNode() }
    if let mesh = sciencePages.makeContent(id: name,textureVariant:textureVariantEnabled,mathBinding:mathBinding) { content.addChildNode(mesh) }
    updateContentControls()
    values.text = "Science page: " + (sciencePages.entries.first { $0.id == name }?.title ?? name) + (name.hasPrefix("original-physics") ? " • original 2D cutouts / authored visualization" : (name.hasPrefix("original-math") ? " • linked printed equation and graph" : " • inferred shape / authored motion"))
   } else {
    activeScienceID = nil
    modes.selectedSegmentIndex = image.referenceImage.name == "math" ? 1 : 0; reset()
   }
   content.position = SCNVector3Zero; content.eulerAngles = SCNVector3Zero
   let extensionKind=NativeSourceMathKind(rawValue:image.referenceImage.name ?? "")
   let isSourceMath=image.referenceImage.name=="original-math-quadratic" || extensionKind != nil || image.referenceImage.name==NativeTriangleBinding.pageID
   let cropEntry=sciencePages.entries.first{$0.id==image.referenceImage.name && $0.referenceCrop != nil}
   let fullWidth:Float=isSourceMath ? 0.21 : cropEntry.map{Float($0.physicalWidth ?? 0.21)} ?? Float(image.referenceImage.physicalSize.width)
   let scale = fullWidth / 5.7
   if image.referenceImage.name=="original-math-quadratic" {content.position=SCNVector3(-fullWidth*Float(830.0-642.0)/1284,0,-fullWidth*Float(817.5-770.5)/1284);evidence("MATH_CROP_TO_FULL_PAGE offset=\(content.position) fullWidth=\(fullWidth)")}
   if image.referenceImage.name==NativeTriangleBinding.pageID {let m=NativeTriangleBinding.mapping(fullPageWidth:Double(fullWidth));content.position=SCNVector3(m.offsetX,0,m.offsetZ);evidence("SOURCE_TRIANGLE_CROP_TO_FULL_PAGE offset=\(content.position) normalized_units=true")}
   if let kind=extensionKind {let m=kind.mapping(fullPageWidth:Double(fullWidth));content.position=SCNVector3(m.offsetX,0,m.offsetZ);evidence("SOURCE_MATH_CROP_TO_FULL_PAGE id=\(kind.rawValue) offset=\(content.position) fullWidth=\(fullWidth)")}
   if let entry=cropEntry,entry.animation=="source-diagram-physics",let crop=entry.referenceCrop,let page=UIImage(contentsOfFile:sciencePages.directory.appendingPathComponent(entry.page).path) {content.position=SCNVector3(-fullWidth*Float((crop[0]+crop[2]/2-Double(page.size.width)/2)/Double(page.size.width)),0,-fullWidth*Float((crop[1]+crop[3]/2-Double(page.size.height)/2)/Double(page.size.width)));evidence("SOURCE_DIAGRAM_CROP_TO_FULL_PAGE offset=\(content.position) pageNormal=+Y sourcePixelY=+Z")}
   content.scale = SCNVector3(scale, scale, scale); content.isHidden = false
   evidence("REAL_IMAGE_ANCHOR name=\(image.referenceImage.name ?? "target") tracked=\(image.isTracked) id=\(image.identifier)")
  }
  stability.observe(pose: image.transform, tracked: image.isTracked, at: time)
  if lastImageTracked != image.isTracked {
   evidence("REAL_IMAGE_TRACKING tracked=\(image.isTracked) target=\(image.referenceImage.name ?? "target")")
   lastImageTracked = image.isTracked
  }
  maybeScheduleLiveDemo(image)
 }
 @objc func toggleWorldPin() {
  guard !ProcessInfo.processInfo.arguments.contains("--image-only") else{values.text="World pin requires world-tracking mode";return}
  targetPolicy.selectedSegmentIndex=targetPolicy.selectedSegmentIndex==2 ? 0:2;changeTargetPolicy();updatePresentation()
 }
 @objc func changeTargetPolicy() {
  stability.policy = targetPolicy.selectedSegmentIndex==2 ? .worldPinned : (targetPolicy.selectedSegmentIndex == 1 ? .fixed : .moving)
  worldPinButton.setTitle(stability.policy == .worldPinned ? "Unpin page" : "Pin page",for:.normal)
  evidence("PRESENTATION_POLICY policy=\(stability.policy.rawValue) maximumHold=\(stability.policy.maximumHold)")
 }
 @objc func updatePresentation() {
  let now=CACurrentMediaTime(),dt=lastDynamicsTime.map{now-$0} ?? 0
  lastDynamicsTime=now
  if let domain=sciencePages.domainAdapter,sourceMathInputAllowed {domain.update(dt);values.text=domain.description}
  if let physics=sciencePages.physicsAdapter,sourceMathInputAllowed {physics.update(dt);values.text=physics.description}
  if let physics=sciencePages.diagramPhysicsAdapter,sourceMathInputAllowed {physics.update(dt);values.text=physics.description}
  guard live else { return }
  let result = stability.sample(at: CACurrentMediaTime())
  let interactive=result.interactive && sourceMathInputAllowed
  sourceMathControls.isUserInteractionEnabled=interactive;sourceMathControls.alpha=interactive ? 1 : 0.45
  for button in adjustmentButtons+[sciencePauseButton,scienceReplayButton] {button.isEnabled=interactive}
  if !interactive {sciencePages.mathInputAdapter?.endDrag();mathGraphDragging=false}
  placement.isHidden = result.pose == nil; content.opacity = CGFloat(result.opacity)
  if let pose = result.pose { placement.simdTransform = pose }
  scene.physicsWorld.speed = interactive ? 1 : 0
  if interactive { scene.physicsWorld.gravity = content.convertVector(SCNVector3(0, -9.81, 0), to: nil) }
  switch result.state {
  case .tracked: status.text = "ARKit • measured image tracking"
  case .pinned: status.text = "ARKit • world pinned to last measured page pose · page NOT tracked"
  case .held: status.text = "ARKit • brief loss: holding last world pose (not tracked)"
  case .fading: status.text = "ARKit • image lost: fading held pose"
  case .hidden: status.text = "ARKit • image lost: hidden until reacquired"
  case .searching: status.text = cameraTrackingNormal ? "ARKit • camera ready: looking for selected image" : "ARKit • camera tracking initializing / unavailable"
  }
  if result.state != lastPresentationState {
   let position = result.pose.map { TrackingStability.position($0) }
   evidence("PRESENTATION_STATE state=\(result.state.rawValue) measured=\(result.measured) age=\(result.observationAge ?? -1) policy=\(stability.policy.rawValue) position=\(String(describing: position))")
   lastPresentationState = result.state
  }
 }
 func sessionWasInterrupted(_ session: ARSession) {
  DispatchQueue.main.async { self.cameraTrackingNormal=false; self.stability.setCameraReliable(false); self.updatePresentation() }
  evidence("REAL_AR_SESSION_INTERRUPTED")
 }
 func sessionInterruptionEnded(_ session: ARSession) {
  evidence("REAL_AR_SESSION_INTERRUPTION_ENDED awaiting normal world tracking")
 }
 func maybeScheduleLiveDemo(_ image: ARImageAnchor) {
  guard image.isTracked, !liveDemoScheduled, ProcessInfo.processInfo.arguments.contains("--ar-actions") else { return }
  liveDemoScheduled = true
  evidence("REAL_ANCHOR_ACTIONS_SCHEDULED")
  if ProcessInfo.processInfo.arguments.contains("--ar-record") {
   let recorder = RPScreenRecorder.shared(); recorder.isMicrophoneEnabled = false
   recorder.startRecording { error in
    DispatchQueue.main.async {
     if let error { evidence("REAL_RECORDING_START_FAILED \(error.localizedDescription)"); self.status.text = "Recording: \(error.localizedDescription)"; return }
     evidence("REAL_RECORDING_STARTED")
     self.runLiveActions()
     DispatchQueue.main.asyncAfter(deadline: .now()+32) {
      let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("real-arkit-demo.mp4")
      if FileManager.default.fileExists(atPath: url.path) { try? FileManager.default.removeItem(at: url) }
      recorder.stopRecording(withOutput: url) { error in
       DispatchQueue.main.async {
        if let error { evidence("REAL_RECORDING_SAVE_FAILED \(error.localizedDescription)") }
        else { evidence("REAL_RECORDING_SAVED Documents/real-arkit-demo.mp4"); self.status.text = "Real ARKit recording saved" }
       }
      }
     }
    }
   }
  } else { runLiveActions() }
 }
 func runLiveActions() {
  let steps: [(Double, () -> Void)] = [(3, { self.mass.value = 0.25; self.reset(); self.launch() }), (9, { self.reset() }), (12, { self.mass.value = 0.48; self.reset(); self.launch() }), (19, { self.reset() }), (23, { if self.modes.selectedSegmentIndex == 1 { self.launch() } })]
  for (delay, action) in steps { DispatchQueue.main.asyncAfter(deadline: .now()+delay, execute: action) }
 }
 func scheduleDemo() {
  let steps: [(Double, () -> Void)] = [(1, {
   let ys = self.blocks.map { $0.presentation.position.y }
   evidence("BASELINE_BLOCK_HEIGHTS \(ys)")
  }), (2, { self.mass.value = 0.25; self.reset(); self.launch() }), (8, { self.mass.value = 0.48; self.reset() }), (10, { self.launch() }), (17, { self.reset(); self.moveAnchor() }), (21, { self.modes.selectedSegmentIndex = 1; self.reset() }), (25, { self.launch() }), (29, { self.moveAnchor() })]
  for (delay, action) in steps { DispatchQueue.main.asyncAfter(deadline: .now()+delay, execute: action) }
 }
}

/// Native, searchable catalogue rather than an inaccessible nested70-item menu.
final class NativePagePicker:UITableViewController,UISearchResultsUpdating {
 let entries:[SciencePage],selectedID:String?,choose:(String?)->Void
 let search=UISearchController(searchResultsController:nil)
 var visible:[SciencePage]
 init(entries:[SciencePage],selectedID:String?,choose:@escaping(String?)->Void){
  let sorted=entries.sorted{($0.id.hasPrefix("original-") ? "0":"1")+$0.title < ($1.id.hasPrefix("original-") ? "0":"1")+$1.title};self.entries=sorted;visible=sorted;self.selectedID=selectedID;self.choose=choose
  super.init(style:.insetGrouped)
 }
 required init?(coder:NSCoder){fatalError("init(coder:) has not been implemented")}
 override func viewDidLoad(){super.viewDidLoad();title="Choose a page";tableView.register(UITableViewCell.self,forCellReuseIdentifier:"Page");search.searchResultsUpdater=self;search.obscuresBackgroundDuringPresentation=false;search.searchBar.placeholder="Search diagrams and topics";search.searchBar.accessibilityIdentifier="SearchPages";navigationItem.searchController=search;navigationItem.hidesSearchBarWhenScrolling=false;navigationItem.rightBarButtonItem=UIBarButtonItem(barButtonSystemItem:.done,target:self,action:#selector(close));definesPresentationContext=true}
 func updateSearchResults(for searchController:UISearchController){let q=(searchController.searchBar.text ?? "").lowercased();visible=q.isEmpty ? entries : entries.filter{$0.title.lowercased().contains(q)||$0.id.lowercased().contains(q)};tableView.reloadData()}
 override func tableView(_ tableView:UITableView,numberOfRowsInSection section:Int)->Int{visible.count+1}
 override func tableView(_ tableView:UITableView,cellForRowAt indexPath:IndexPath)->UITableViewCell{
  let cell=tableView.dequeueReusableCell(withIdentifier:"Page",for:indexPath);var text=cell.defaultContentConfiguration()
  if indexPath.row==0 {text.text="Auto-detect prepared pages";text.secondaryText="Registered catalogue only";cell.accessoryType=selectedID==nil ? .checkmark:.none;cell.accessibilityIdentifier="Page:auto"}
  else {let page=visible[indexPath.row-1];text.text=page.title;text.secondaryText=page.id.hasPrefix("original-") ? "Original reference diagram" : page.id.hasPrefix("primary9-") ? "Same-input quality comparison" : "Prepared illustration";cell.accessoryType=selectedID==page.id ? .checkmark:.none;cell.accessibilityIdentifier="Page:"+page.id}
  cell.contentConfiguration=nil;cell.accessibilityTraits.remove(.button)
  cell.contentView.subviews.forEach{$0.removeFromSuperview()}
  let button=UIButton(type:.system);button.setTitle(text.text,for:.normal);button.contentHorizontalAlignment = .left;button.titleLabel?.font = .systemFont(ofSize:15);button.titleLabel?.numberOfLines=2;button.accessibilityIdentifier=cell.accessibilityIdentifier
  button.translatesAutoresizingMaskIntoConstraints=false;cell.contentView.addSubview(button)
  NSLayoutConstraint.activate([button.leadingAnchor.constraint(equalTo:cell.contentView.leadingAnchor,constant:16),button.trailingAnchor.constraint(equalTo:cell.contentView.trailingAnchor,constant:-8),button.topAnchor.constraint(equalTo:cell.contentView.topAnchor,constant:12),button.bottomAnchor.constraint(equalTo:cell.contentView.bottomAnchor,constant:-12)])
  let id=indexPath.row==0 ? nil:visible[indexPath.row-1].id
  button.addAction(UIAction{[weak self] _ in self?.select(id)},for:.touchUpInside)
  return cell
 }
 override func tableView(_ tableView:UITableView,didSelectRowAt indexPath:IndexPath){let id=indexPath.row==0 ? nil:visible[indexPath.row-1].id;select(id)}
 func select(_ id:String?){search.isActive=false;dismiss(animated:true){self.choose(id)}}
 @objc func close(){dismiss(animated:true)}
}
