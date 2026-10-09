#if MARKER_BENCH
import UIKit
import ARKit
import SceneKit
import simd
import AVFoundation

/// Real native optical tracking. The detector pose and ARKit camera transform come from one ARFrame.
final class MarkerBench: UIViewController, ARSessionDelegate {
 let actualARViewRecorder=PaperARViewRecorder()
 let ar=ARSCNView(), root=SCNNode(), model=SCNNode(), label=UILabel(), detail=UILabel()
 let tracker=UISegmentedControl(items:["Color dots","ArUco","ARKit image"])
 let queue=DispatchQueue(label:"paperlab.marker-detector",qos:.userInitiated)
 var busy=false,epoch=0,minimumTime=0.0,lastFrameTime=0.0,lastMeasurement=0.0,frameCount=0,accepted=0
 var lastState="",activeID:Int?,sceneIndex=0,paused=false,tick:CADisplayLink?,stability=TrackingStability()
 let paperApplication=PaperApplicationScene()
 let applicationPicker=UISegmentedControl(items:PaperApplicationState.Topic.allCases.map{$0.pickerTitle})
 let applicationPickerScroll=UIScrollView()
 let focusButton=UIButton(type:.system), paperDialButton=UIButton(type:.system), inspectButton=UIButton(type:.system), generalControls=UIStackView()
 var paperDialEnabled=false,paperDialReference:simd_float4x4?,paperDialTick=0.0,paperDialLogTime=0.0
 var classroomFocused=false,inspectionEnabled=false
 let applicationButtons=[UIButton(type:.system),UIButton(type:.system),UIButton(type:.system)]
 var applicationClock=PaperApplicationClock(),lastCameraDiagnostic=0.0,lastApplicationDiagnostic=0.0
 var latestObservedCorners=0,latestObservedDots=0
 var latestMS=0.0,latestError=0.0,lastWorld:simd_float4x4?,lastRawTime=0.0
 let extent=0.12 // Shared fixture outside/dot-centre square in metres; override is recorded at launch.
 var markerExtent:Double {let a=ProcessInfo.processInfo.arguments;if let i=a.firstIndex(of:"--marker-extent"),i+1<a.count,let d=Double(a[i+1]),d>0{return d};return extent}
 override func viewDidLoad(){
  super.viewDidLoad();overrideUserInterfaceStyle = .dark;view.backgroundColor = .black;UIApplication.shared.isIdleTimerDisabled=true
  ar.session.delegate=self;ar.scene=SCNScene();ar.scene.rootNode.addChildNode(root);root.addChildNode(model);root.isHidden=true;ar.autoenablesDefaultLighting=true
  tracker.overrideUserInterfaceStyle = .dark;tracker.selectedSegmentIndex=ProcessInfo.processInfo.arguments.contains("--marker-aruco") ? 1:0;tracker.addTarget(self,action:#selector(changeTracker),for:.valueChanged)
  label.textColor = .white;label.font = .boldSystemFont(ofSize:15);label.numberOfLines=2;detail.textColor = .white;detail.font = .systemFont(ofSize:11);detail.numberOfLines=5
  let controls=generalControls;controls.distribution = .fillEqually
  for (title,selector) in [("Pause / resume",#selector(toggleMotion)),("Rotate +30°",#selector(rotate)),("Scale +20%",#selector(scaleUp)),("Explode",#selector(explode)),("Change scene",#selector(changeScene)),("Reset",#selector(reset))]{let b=UIButton(type:.system);b.setTitle(title,for:.normal);b.accessibilityIdentifier=title;b.addTarget(self,action:selector,for:.touchUpInside);controls.addArrangedSubview(b)}
  applicationPicker.selectedSegmentIndex=0;applicationPicker.accessibilityIdentifier="PaperApplicationPicker";applicationPicker.addTarget(self,action:#selector(selectApplication),for:.valueChanged)
  precondition(applicationPicker.numberOfSegments==PaperApplicationState.Topic.allCases.count,"Every lesson must be selectable")
  applicationPicker.translatesAutoresizingMaskIntoConstraints=false;applicationPickerScroll.addSubview(applicationPicker);applicationPickerScroll.showsHorizontalScrollIndicator=true;applicationPickerScroll.accessibilityIdentifier="PaperApplicationPickerScroll"
  NSLayoutConstraint.activate([applicationPickerScroll.heightAnchor.constraint(equalToConstant:34),applicationPicker.leadingAnchor.constraint(equalTo:applicationPickerScroll.contentLayoutGuide.leadingAnchor),applicationPicker.trailingAnchor.constraint(equalTo:applicationPickerScroll.contentLayoutGuide.trailingAnchor),applicationPicker.topAnchor.constraint(equalTo:applicationPickerScroll.contentLayoutGuide.topAnchor),applicationPicker.bottomAnchor.constraint(equalTo:applicationPickerScroll.contentLayoutGuide.bottomAnchor),applicationPicker.heightAnchor.constraint(equalTo:applicationPickerScroll.frameLayoutGuide.heightAnchor),applicationPicker.widthAnchor.constraint(greaterThanOrEqualToConstant:CGFloat(PaperApplicationState.Topic.allCases.count)*72),applicationPicker.widthAnchor.constraint(greaterThanOrEqualTo:applicationPickerScroll.frameLayoutGuide.widthAnchor)])
  let applicationControls=UIStackView(arrangedSubviews:applicationButtons);applicationControls.distribution = .fillEqually
  for (index,button) in applicationButtons.enumerated(){button.tag=index;button.accessibilityIdentifier="PaperApplicationAction\(index)";button.addTarget(self,action:#selector(applicationAction(_:)),for:.touchUpInside)}
  let back=UIButton(type:.system);back.setTitle("Back to AR catalog",for:.normal);back.addTarget(self,action:#selector(backToCatalog),for:.touchUpInside);focusButton.setTitle("Focus lesson",for:.normal);focusButton.addTarget(self,action:#selector(toggleClassroomFocus),for:.touchUpInside);paperDialButton.setTitle("Use paper dial",for:.normal);paperDialButton.addTarget(self,action:#selector(togglePaperDial),for:.touchUpInside);inspectButton.setTitle("Inspect 3D",for:.normal);inspectButton.accessibilityIdentifier="PaperInspect3D";inspectButton.addTarget(self,action:#selector(toggleInspection),for:.touchUpInside);let navigation=UIStackView(arrangedSubviews:[back,focusButton,paperDialButton,inspectButton]);navigation.distribution = .fillEqually;let stack=UIStackView(arrangedSubviews:[navigation,tracker,label,ar,detail,applicationPickerScroll,applicationControls,controls]);stack.axis = .vertical;stack.spacing=5;stack.translatesAutoresizingMaskIntoConstraints=false;view.addSubview(stack)
  for item in stack.arrangedSubviews where item !== ar {item.setContentHuggingPriority(.required,for:.vertical)};ar.setContentHuggingPriority(.defaultLow,for:.vertical);ar.setContentCompressionResistancePriority(.defaultLow,for:.vertical)
  navigation.heightAnchor.constraint(equalToConstant:32).isActive=true;applicationControls.heightAnchor.constraint(equalToConstant:36).isActive=true
  let controlHeight=controls.heightAnchor.constraint(equalToConstant:45);controlHeight.priority = .defaultHigh
  NSLayoutConstraint.activate([stack.leadingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.leadingAnchor,constant:8),stack.trailingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.trailingAnchor,constant:-8),stack.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor),stack.bottomAnchor.constraint(equalTo:view.safeAreaLayoutGuide.bottomAnchor),ar.heightAnchor.constraint(greaterThanOrEqualToConstant:100),controlHeight])
  ar.addGestureRecognizer(UIPanGestureRecognizer(target:self,action:#selector(drag(_:))));ar.addGestureRecognizer(UIPinchGestureRecognizer(target:self,action:#selector(pinch(_:))))
  if ProcessInfo.processInfo.arguments.contains("--marker-selftest"){queue.async{self.selfTest()}}
  let startupArgs=ProcessInfo.processInfo.arguments;if let i=startupArgs.firstIndex(of:"--paper-topic"),i+1<startupArgs.count,let topic=Int(startupArgs[i+1]),PaperApplicationState.Topic(rawValue:topic) != nil{sceneIndex=topic};inspectionEnabled=startupArgs.contains("--paper-inspect-3d");paperDialEnabled=startupArgs.contains("--paper-dial");paperDialButton.setTitle(paperDialEnabled ? "Use lesson buttons":"Use paper dial",for:.normal)
  makeScene();if startupArgs.contains("--paper-focus"){toggleClassroomFocus()};tick=CADisplayLink(target:self,selector:#selector(renderState));tick?.add(to:.main,forMode:.common);startSession()
  let recordingArgs=ProcessInfo.processInfo.arguments;
  actualARViewRecorder.onCompletion={result in switch result{case .success(let report):evidence("PAPER_AR_VIEW_VERIFIED_RECORD path=\(report.file) frames=\(report.frames) duration=\(report.sourceSeconds) status=\(report.writerStatus)");case .failure(let error):evidence("PAPER_AR_VIEW_RECORD_FAILED "+error.localizedDescription)}};if let i=recordingArgs.firstIndex(of:"--paper-view-record-seconds"),i+1<recordingArgs.count,let seconds=Double(recordingArgs[i+1]){DispatchQueue.main.asyncAfter(deadline:.now()+3){do{try self.actualARViewRecorder.start(ar:self.ar,seconds:seconds)}catch{evidence("PAPER_AR_VIEW_RECORD_START_FAILED "+error.localizedDescription)}}}
  evidence("MARKERBENCH_BEGIN version=1 extent=\(markerExtent) fixture=shared marker pose=metric optical ARKitWorld=true input=actual-camera")
 }
 deinit{tick?.invalidate();actualARViewRecorder.stop();ar.session.pause()}
 func applyInspection(){model.eulerAngles.x=inspectionEnabled ? .pi/6:0;model.eulerAngles.y=inspectionEnabled ? -.pi/9:0;inspectButton.setTitle(inspectionEnabled ? "Paper-aligned view":"Inspect 3D",for:.normal)}
 @objc func toggleInspection(){guard interactive else{return};inspectionEnabled.toggle();applyInspection();evidence("PAPER_APP_INSPECTION enabled=\(inspectionEnabled) authoredModelRotation=true cameraPoseUnchanged=true actualUIKit=true")}
 @objc func togglePaperDial(){guard interactive else{return};guard paperApplication.state.topic != .fractions else{evidence("PAPER_DIAL_UNSUPPORTED topic=fractions");return};paperDialEnabled.toggle();paperDialReference=paperDialEnabled ? stability.sample(at:CACurrentMediaTime()).pose:nil;paperDialButton.setTitle(paperDialEnabled ? "Use lesson buttons":"Use paper dial",for:.normal);evidence("PAPER_DIAL_MODE enabled=\(paperDialEnabled) source=measured-world-marker-pose actualUIKit=true")}
 func applyMeasuredPaperDial(pose:simd_float4x4?,measured:Bool,at now:Double){
  guard paperDialEnabled,measured,!paused,now-paperDialTick>=0.1,let pose else{return};paperDialTick=now
  guard let reference=paperDialReference else{paperDialReference=pose;return}
  let relative=simd_inverse(reference)*pose
  let rawAngle=Double(atan2(relative.columns.0.y,relative.columns.0.x))
  let angle=(rawAngle * 360 / .pi).rounded() * .pi/360
  let translation=(Double(relative.columns.3.y)*2000).rounded()/2000
  let wasSpringPulling=paperApplication.state.springPulling
  if paperApplication.state.applyPaperDial(rotationRadians:angle,translationMeters:translation){if wasSpringPulling != paperApplication.state.springPulling{evidence("PAPER_SPRING_PULL_CHANGE wallUnix=\(Date().timeIntervalSince1970) pulling=\(paperApplication.state.springPulling) x=\(paperApplication.state.spring.displacement) springTime=\(paperApplication.state.spring.time) source=fresh-ARKit-world-marker-pose")};paperApplication.rebuild();if now-paperDialLogTime>=0.25{paperDialLogTime=now;evidence("PAPER_DIAL_MEASURED wallUnix=\(Date().timeIntervalSince1970) id=\(activeID ?? -1) angleRadians=\(angle) pageYMetres=\(translation) model=\(paperApplication.state.description) source=fresh-ARKit-world-marker-pose")}}
 }
 @objc func toggleClassroomFocus(){classroomFocused.toggle();tracker.isHidden=classroomFocused;label.isHidden=classroomFocused;applicationPickerScroll.isHidden=classroomFocused;generalControls.isHidden=classroomFocused;focusButton.setTitle(classroomFocused ? "Show all lessons":"Focus lesson",for:.normal);detail.numberOfLines=classroomFocused ? 3:5;evidence("PAPER_APP_INPUT action=classroom-focus enabled=\(classroomFocused) actualUIKit=true")}
 @objc func backToCatalog(){actualARViewRecorder.stop();tick?.invalidate();tick=nil;ar.session.pause();view.window?.rootViewController=Demo()}
 @objc func changeTracker(){epoch += 1;minimumTime=CACurrentMediaTime();activeID=nil;stability.reset();root.isHidden=true;lastWorld=nil;startSession();evidence("MARKER_MODE mode=\(mode) epoch=\(epoch)")}
 var mode:String{["dots","aruco","arkit-image"][tracker.selectedSegmentIndex]}
 func selfTest(){
  for (mode,name) in [("dots","marker-dot-7"),("dots","marker-dot-8"),("aruco","marker-aruco-7"),("aruco","marker-aruco-8")]{
   guard let cg=UIImage(named:name+".png")?.cgImage else{evidence("MARKER_SELFTEST missing=\(name)");continue}
   var output:CVPixelBuffer?;let attributes=[kCVPixelBufferCGImageCompatibilityKey:true,kCVPixelBufferCGBitmapContextCompatibilityKey:true] as CFDictionary
   guard CVPixelBufferCreate(kCFAllocatorDefault,cg.width,cg.height,kCVPixelFormatType_32BGRA,attributes,&output)==kCVReturnSuccess,let buffer=output else{continue}
   CVPixelBufferLockBaseAddress(buffer,[])
   if let context=CGContext(data:CVPixelBufferGetBaseAddress(buffer),width:cg.width,height:cg.height,bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(buffer),space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo.byteOrder32Little.rawValue|CGImageAlphaInfo.premultipliedFirst.rawValue){context.draw(cg,in:CGRect(x:0,y:0,width:cg.width,height:cg.height))}
   CVPixelBufferUnlockBaseAddress(buffer,[])
   let fx=Double(cg.width),fy=Double(cg.width),cx=Double(cg.width)/2,cy=Double(cg.height)/2
   let start=CACurrentMediaTime();let found=MarkerVision.detect(buffer,mode:mode,fx:fx,fy:fy,cx:cx,cy:cy,extent:0.12)
   let json=String(data:(try? JSONSerialization.data(withJSONObject:found)) ?? Data(),encoding:.utf8) ?? "[]";evidence("MARKER_SELFTEST source=generated-fixture-not-camera name=\(name) ms=\((CACurrentMediaTime()-start)*1000) results=\(json)")
  }
  if let folder=Bundle.main.url(forResource:"fixtures",withExtension:nil),let data=try? Data(contentsOf:folder.appendingPathComponent("manifest.json")),let manifest=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any],let tests=manifest["tests"] as? [[String:Any]] {
   for item in tests {guard let file=item["file"] as? String,let name=item["name"] as? String,let mode=item["mode"] as? String,let k=item["K"] as? [Double],let image=UIImage(contentsOfFile:folder.appendingPathComponent(file).path)?.cgImage else{continue};var output:CVPixelBuffer?;CVPixelBufferCreate(kCFAllocatorDefault,image.width,image.height,kCVPixelFormatType_32BGRA,[kCVPixelBufferCGImageCompatibilityKey:true,kCVPixelBufferCGBitmapContextCompatibilityKey:true] as CFDictionary,&output);guard let buffer=output else{continue};CVPixelBufferLockBaseAddress(buffer,[]);if let c=CGContext(data:CVPixelBufferGetBaseAddress(buffer),width:image.width,height:image.height,bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(buffer),space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo.byteOrder32Little.rawValue|CGImageAlphaInfo.premultipliedFirst.rawValue){c.draw(image,in:CGRect(x:0,y:0,width:image.width,height:image.height))};CVPixelBufferUnlockBaseAddress(buffer,[]);let start=CACurrentMediaTime();let found=MarkerVision.detect(buffer,mode:mode,fx:k[0],fy:k[1],cx:k[2],cy:k[3],extent:0.12);let expected=item["expectedID"] as? Int;let actual=(found.first?["id"] as? NSNumber)?.intValue;let expectedCorners=item["expectedCorners"] as? Int;let actualCorners=(found.first?["decodedCorners"] as? NSNumber)?.intValue;let expectedCornerIDs=item["expectedCornerIDs"] as? [Int];let actualCornerIDs=(found.first?["observedCornerIDs"] as? [NSNumber])?.map{$0.intValue};let passed=expected==actual && (expectedCorners==nil || expectedCorners==actualCorners) && (expectedCornerIDs==nil || expectedCornerIDs==actualCornerIDs);let record:[String:Any]=["name":name,"source":item["source"] as? String ?? "generated-projection-not-camera","pass":passed,"expectedCorners":expectedCorners as Any? ?? NSNull(),"actualCorners":actualCorners as Any? ?? NSNull(),"expectedCornerIDs":expectedCornerIDs as Any? ?? NSNull(),"actualCornerIDs":actualCornerIDs as Any? ?? NSNull(),"expectedID":expected as Any? ?? NSNull(),"actualID":actual as Any? ?? NSNull(),"ms":(CACurrentMediaTime()-start)*1000,"rvec":item["rvec"] ?? [],"tvec":item["tvec"] ?? [],"results":found];if let data=try? JSONSerialization.data(withJSONObject:record),let json=String(data:data,encoding:.utf8){evidence("MARKER_CALIBRATED_SELFTEST_JSON "+json)}
   }
  }
 }
 func startSession(){guard ARWorldTrackingConfiguration.isSupported else{label.text="ARKit unavailable";return};let c=ARWorldTrackingConfiguration();if mode=="arkit-image",let image=UIImage(contentsOfFile:Bundle.main.path(forResource:"marker-dot-7",ofType:"png") ?? "")?.cgImage{let r=ARReferenceImage(image,orientation:.up,physicalWidth:markerExtent*7/6);r.name="marker-dot-7";c.detectionImages=[r];c.maximumNumberOfTrackedImages=1};minimumTime=CACurrentMediaTime();stability.reset();ar.session.run(c,options:[.removeExistingAnchors]);label.text="Searching · \(mode) · live ARKit camera"}
 func session(_ session:ARSession,didUpdate frame:ARFrame){
  let time=frame.timestamp
  if time-lastCameraDiagnostic>2 {lastCameraDiagnostic=time;evidence("MARKER_CAMERA_STATE state=\(frame.camera.trackingState) timestamp=\(time) epoch=\(epoch) fx=\(frame.camera.intrinsics.columns.0.x) fy=\(frame.camera.intrinsics.columns.1.y) cx=\(frame.camera.intrinsics.columns.2.x) cy=\(frame.camera.intrinsics.columns.2.y)")}
  let normal:Bool;if case .normal=frame.camera.trackingState{normal=true}else{normal=false}
  DispatchQueue.main.async{self.stability.setCameraReliable(normal)}
  guard normal,time>=minimumTime else{return}
  if mode=="arkit-image"{let found=frame.anchors.compactMap{$0 as? ARImageAnchor}.first{$0.isTracked};DispatchQueue.main.async{guard time>=self.minimumTime else{return};if let found{let pageToImage=simd_float4x4(SIMD4(1,0,0,0),SIMD4(0,0,1,0),SIMD4(0,-1,0,0),SIMD4(0,0,0,1));self.stability.observe(pose:found.transform*pageToImage,tracked:true,at:time);self.activeID=7}else{self.stability.markLost()}};return}
  guard !busy,time-lastFrameTime>=0.066 else{return};busy=true;lastFrameTime=time;frameCount += 1
  let k=frame.camera.intrinsics,camera=frame.camera.transform,buffer=frame.capturedImage,runEpoch=epoch,detectorMode=mode,side=markerExtent
  queue.async{
   let started=CACurrentMediaTime()
   let found=MarkerVision.detect(buffer,mode:detectorMode,fx:Double(k.columns.0.x),fy:Double(k.columns.1.y),cx:Double(k.columns.2.x),cy:Double(k.columns.2.y),extent:side)
   DispatchQueue.main.async{
    self.busy=false
    let delivered=CACurrentMediaTime(),eligible=runEpoch==self.epoch && time>=self.minimumTime && delivered-time<=0.15
    let attempt:[String:Any]=["mode":detectorMode,"epoch":runEpoch,"captureTime":time,"deliveryTime":delivered,"wallDeliveryUnix":Date().timeIntervalSince1970,"ageSeconds":delivered-time,"latencyMs":(delivered-started)*1000,"detectedIDs":found.compactMap{($0["id"] as? NSNumber)?.intValue},"acceptedForPresentation":eligible && !found.isEmpty,"rejectedOldEpochOrFrame":!eligible,"attemptSequence":self.frameCount,"bufferWidth":CVPixelBufferGetWidth(buffer),"bufferHeight":CVPixelBufferGetHeight(buffer)]
    if let data=try? JSONSerialization.data(withJSONObject:attempt),let json=String(data:data,encoding:.utf8){evidence("MARKER_ATTEMPT_JSON "+json)}
    guard eligible else{return}
    guard let p=found.first,let a=p["cameraFromPageRowMajor"] as? [NSNumber],a.count==16,let id=p["id"] as? NSNumber else{self.stability.markLost();return}
    var cv=matrix_identity_float4x4;for r in 0..<4{for c in 0..<4{cv[c][r]=a[r*4+c].floatValue}}
    let opticalToAR=simd_float4x4(diagonal:SIMD4<Float>(1,-1,-1,1))
    // CV optical axes x-right,y-down,z-forward; ARKit camera x-right,y-up,z-back.
    let world=camera*opticalToAR*cv
    if self.activeID != id.intValue {self.stability.reset();self.lastWorld=nil;self.paperDialReference=self.paperDialEnabled ? world:nil;evidence("MARKER_ID_CHANGED id=\(id)")};self.stability.observe(pose:world,tracked:true,at:time);self.activeID=id.intValue;self.accepted += 1
    self.latestObservedCorners=(p["decodedCorners"] as? NSNumber)?.intValue ?? 4;self.latestObservedDots=(p["observedDots"] as? NSNumber)?.intValue ?? 0
    self.latestMS=(CACurrentMediaTime()-started)*1000;self.latestError=(p["reprojectionPixels"] as? NSNumber)?.doubleValue ?? 0
    let pos=world.columns.3;let step=self.lastWorld.map{simd_distance(TrackingStability.position($0),TrackingStability.position(world))} ?? 0
    let q=simd_quatf(world);let angle=self.lastWorld.map{2*acos(min(1,abs(simd_dot(simd_quatf($0).vector,q.vector))))} ?? 0
    self.lastWorld=world;self.lastRawTime=time;self.lastMeasurement=time
    let sample:[String:Any]=["mode":detectorMode,"id":id.intValue,"captureTime":time,"deliveryTime":CACurrentMediaTime(),"wallDeliveryUnix":Date().timeIntervalSince1970,"ageSeconds":CACurrentMediaTime()-time,"latencyMs":self.latestMS,"detectorMs":p["processMs"] ?? 0,"reprojectionPixels":self.latestError,"worldPosition":[pos.x,pos.y,pos.z],"worldQuaternion":[q.vector.x,q.vector.y,q.vector.z,q.vector.w],"stepMeters":step,"stepRadians":angle,"corners":p["corners"] ?? [],"imagePoints":p["imagePoints"] ?? [],"observedCornerIDs":p["observedCornerIDs"] ?? [],"decodedCorners":p["decodedCorners"] ?? 4,"observedDots":p["observedDots"] ?? 0,"recoveryMode":p["recoveryMode"] ?? "aruco-four-measured-corners","intrinsics":[k.columns.0.x,k.columns.1.y,k.columns.2.x,k.columns.2.y],"bufferWidth":CVPixelBufferGetWidth(buffer),"bufferHeight":CVPixelBufferGetHeight(buffer),"detectorScale":p["detectorScale"] ?? 1]
    if let data=try? JSONSerialization.data(withJSONObject:sample),let json=String(data:data,encoding:.utf8){evidence("MARKER_SAMPLE_JSON "+json)}
   }
  }
 }
 func sessionWasInterrupted(_ session:ARSession){DispatchQueue.main.async{self.invalidate("sessionInterrupted")}}
 func sessionInterruptionEnded(_ session:ARSession){DispatchQueue.main.async{self.invalidate("interruptionEnded");self.startSession()}}
 func session(_ session:ARSession,didFailWithError error:Error){DispatchQueue.main.async{self.invalidate(error.localizedDescription)}}
 func invalidate(_ reason:String){epoch += 1;minimumTime=CACurrentMediaTime();stability.reset();root.isHidden=true;activeID=nil;evidence("MARKER_INVALIDATE reason=\(reason)")}
 @objc func renderState(){let now=CACurrentMediaTime();let state=stability.sample(at:now);let runnable=state.measured && !paused && UIApplication.shared.applicationState == .active && view.window != nil;applyMeasuredPaperDial(pose:state.pose,measured:runnable,at:now);let dt=applicationClock.interval(at:now,runnable:runnable);paperApplication.advance(dt,measured:runnable,paused:paused);if now-lastApplicationDiagnostic>=0.5{lastApplicationDiagnostic=now;let app=paperApplication.state;let tickInfo:[String:Any]=["wallUnix":Date().timeIntervalSince1970,"topic":app.topic.rawValue,"measured":state.measured,"paused":paused,"elapsed":app.elapsed,"runnable":runnable,"modelInterval":dt,"inclineTime":app.incline.time,"pendulumTime":app.pendulum.time,"pendulumAngle":app.pendulum.angle,"pendulumLength":app.pendulum.length,"pendulumPeriod":app.pendulum.period,"springPulling":app.springPulling,"springTime":app.spring.time,"springX":app.spring.displacement,"springVelocity":app.spring.velocity,"springEnergy":app.spring.energy,"description":app.description];if let d=try? JSONSerialization.data(withJSONObject:tickInfo,options:[.sortedKeys]),let text=String(data:d,encoding:.utf8){evidence("PAPER_APP_TICK_JSON "+text)}};for button in applicationButtons{button.isEnabled=state.measured && !paperDialEnabled};root.isHidden=state.pose==nil;root.opacity=CGFloat(state.opacity);if let pose=state.pose{root.simdTransform=pose};model.isPaused=paused || !state.measured;inspectButton.isEnabled=state.measured;label.text="\(mode) · ID \(activeID.map(String.init) ?? "—") · \(state.state.rawValue.uppercased())"+(state.measured ? " · \(latestObservedCorners) observed corners":"");detail.text=String(format:"Live optical → metric world pose · %.0f ms · fit %.2f px\n0.65 s bounded hold (NOT tracked) · controls only when measured\nScene: %@ · target extent %.3f m",latestMS,latestError,paperApplication.state.topic.title + " · " + paperApplication.state.description,markerExtent);if classroomFocused{detail.text=paperApplication.state.topic.title + " · " + (state.measured ? "Paper tracked":"Show the paper to continue") + "\n" + paperApplication.state.description + (paperDialEnabled ? "\nRotate the paper to change the lesson":"")};if lastState != state.state.rawValue{evidence("MARKER_STATE mode=\(mode) state=\(state.state.rawValue) now=\(CACurrentMediaTime()) measurement=\(lastMeasurement)");lastState=state.state.rawValue}}
 var interactive:Bool{stability.sample(at:CACurrentMediaTime()).measured}
 @objc func toggleMotion(){guard interactive else{return};paused.toggle();evidence("MARKER_INPUT action=pause paused=\(paused) actualUIKit=true")}
 @objc func rotate(){guard interactive else{return};model.eulerAngles.z += .pi/6;evidence("MARKER_INPUT action=rotate actualUIKit=true")}
 @objc func changeScene(){guard interactive else{return};sceneIndex=(sceneIndex+1)%PaperApplicationState.Topic.allCases.count;makeScene();evidence("MARKER_INPUT action=scene scene=\(sceneIndex) actualUIKit=true")}
 @objc func scaleUp(){guard interactive else{return};let v=min(2.5,model.scale.x*1.2);model.scale=SCNVector3(v,v,v);evidence("MARKER_INPUT action=scale actualUIKit=true value=\(v)")}
 @objc func explode(){guard interactive else{return};for (i,n) in model.childNodes.enumerated(){n.runAction(.moveBy(x:CGFloat(i%3-1)*0.03,y:CGFloat(i%2)*0.025,z:-0.025,duration:0.5))};evidence("MARKER_INPUT action=explode actualUIKit=true")}
 @objc func reset(){guard interactive else{return};makeScene();evidence("MARKER_INPUT action=reset actualUIKit=true")}
 @objc func drag(_ p:UIPanGestureRecognizer){guard interactive else{return};let t=p.translation(in:ar);model.eulerAngles.z += Float(t.x)*0.006;model.eulerAngles.x=min(.pi/3,max(-.pi/3,model.eulerAngles.x+Float(t.y)*0.005));p.setTranslation(.zero,in:ar);if p.state == .ended{evidence("MARKER_INPUT action=drag source=gesture")}}
 @objc func pinch(_ p:UIPinchGestureRecognizer){guard interactive else{return};let s=min(2.5,max(0.4,CGFloat(model.scale.x)*p.scale));model.scale=SCNVector3(s,s,s);p.scale=1;if p.state == .ended{evidence("MARKER_INPUT action=pinch source=gesture")}}
 @objc func selectApplication(){guard PaperApplicationState.Topic(rawValue:applicationPicker.selectedSegmentIndex) != nil else{applicationPicker.selectedSegmentIndex=sceneIndex;return};guard interactive else{applicationPicker.selectedSegmentIndex=sceneIndex;return};sceneIndex=applicationPicker.selectedSegmentIndex;makeScene();evidence("PAPER_APP_INPUT action=select topic=\(paperApplication.state.topic.title) actualUIKit=true")}
 @objc func applicationAction(_ sender:UIButton){guard interactive else{evidence("PAPER_APP_INPUT rejected=tracking-lost action=\(sender.tag)");return};if sender.tag<2{paperApplication.state.parameter(sender.tag==0 ? 1:-1)}else{paperApplication.state.event()};paperApplication.rebuild();evidence("PAPER_APP_INPUT topic=\(paperApplication.state.topic.title) action=\(sender.tag) model=\(paperApplication.state.description) actualUIKit=true")}
 func makeScene(){model.childNodes.forEach{$0.removeFromParentNode()};model.removeAllActions();model.position=SCNVector3Zero;model.eulerAngles=SCNVector3Zero;model.scale=SCNVector3(1,1,1);paused=false;applyInspection()
  paperDialReference=paperDialEnabled ? stability.sample(at:CACurrentMediaTime()).pose:nil
  applicationPicker.selectedSegmentIndex=sceneIndex;let segmentWidth=applicationPicker.bounds.width/CGFloat(max(1,applicationPicker.numberOfSegments));applicationPickerScroll.scrollRectToVisible(CGRect(x:CGFloat(sceneIndex)*segmentWidth,y:0,width:segmentWidth,height:34),animated:false);paperApplication.state.topic=PaperApplicationState.Topic(rawValue:sceneIndex) ?? .solar;paperApplication.state.reset();if paperApplication.state.topic == .fractions{paperDialEnabled=false;paperDialReference=nil;paperDialButton.setTitle("Use paper dial",for:.normal)};paperApplication.rebuild();model.addChildNode(paperApplication.node)
  for (button,title) in zip(applicationButtons,paperApplication.state.topic.controls){button.setTitle(title,for:.normal);button.titleLabel?.font = .systemFont(ofSize:12);button.titleLabel?.numberOfLines=2}
  evidence("PAPER_APP_SCENE topic=\(paperApplication.state.topic.title) metricMarkerBound=true authoredInspection=\(inspectionEnabled) inspectionNotCameraMotion=true")
 }
}
#endif
