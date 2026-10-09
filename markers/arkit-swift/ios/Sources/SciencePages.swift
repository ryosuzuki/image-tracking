import UIKit
import SceneKit
import ARKit

struct SciencePage: Codable {
 let id: String
 let title: String
 let page: String
 let mesh: String
 let animation: String
 var referenceCrop:[Double]?
 var texture:String?
 var variantMesh:String?
 var variantTexture:String?
 var physicalWidth: Double?
}
final class SciencePages {
 let entries: [SciencePage]
 let directory: URL
 var domainAdapter: DomainInteractionAdapter?
 var diagramPhysicsAdapter: SourceDiagramPhysicsAdapter?
 var physicsAdapter: SourcePhysicsAdapter?
 var sourceMathAdapter: NativeSourceMathAdapter?
 var triangleAdapter: NativeTriangleAdapter?
 var mathInputAdapter:(any NativeBoundMath)? {if let sourceMathAdapter {return sourceMathAdapter};return triangleAdapter}
 init() {
  directory = Bundle.main.bundleURL.appendingPathComponent("SciencePages")
  if let data = try? Data(contentsOf: directory.appendingPathComponent("manifest.json")), let decoded = try? JSONDecoder().decode([SciencePage].self, from: data) { entries = decoded } else { entries = [] }
 }
 func referenceImages(selectedID:String?=nil) -> Set<ARReferenceImage> {
  var result = Set<ARReferenceImage>()
  for entry in entries where selectedID == nil || entry.id == selectedID {
   guard let image = UIImage(contentsOfFile: directory.appendingPathComponent(entry.page).path)?.cgImage else { evidence("SCIENCE_TARGET_MISSING id=\(entry.id)"); continue }
   if let kind=NativeSourceMathKind(rawValue:entry.id), let reference=NativeSourceMathAdapter(kind:kind).referenceImage(directory:directory,fullPageWidth:entry.physicalWidth ?? 0.21) {
    reference.validate { error in evidence("SCIENCE_REFERENCE_VALIDATED id=\(entry.id) error=\(error?.localizedDescription ?? "none")") };result.insert(reference)
    evidence("SOURCE_MATH_REFERENCE_CROP id=\(entry.id) crop=\(kind.referenceCrop) physicalWidth=\(reference.physicalSize.width)");continue
   }
   if entry.id==NativeTriangleBinding.pageID,let reference=NativeTriangleAdapter().referenceImage(directory:directory,fullPageWidth:entry.physicalWidth ?? 0.21) {reference.validate {error in evidence("SCIENCE_REFERENCE_VALIDATED id=\(entry.id) error=\(error?.localizedDescription ?? "none")")};result.insert(reference);evidence("SOURCE_TRIANGLE_REFERENCE_CROP crop=\(NativeTriangleBinding.referenceCrop) physicalWidth=\(reference.physicalSize.width)");continue}
   if let crop=entry.referenceCrop,crop.count==4,let target=image.cropping(to:CGRect(x:crop[0],y:crop[1],width:crop[2],height:crop[3])) {
    let width=(entry.physicalWidth ?? 0.21)*crop[2]/Double(image.width)
    let reference=ARReferenceImage(target,orientation:.up,physicalWidth:width);reference.name=entry.id
    reference.validate {error in evidence("SCIENCE_REFERENCE_VALIDATED id=\(entry.id) error=\(error?.localizedDescription ?? "none")")};result.insert(reference)
    evidence("DOMAIN_REFERENCE_CROP id=\(entry.id) source=SAM2_bbox_plus_context crop=\(crop) referenceWidth=\(width) fullPageWidth=\(entry.physicalWidth ?? 0.21)");continue
   }
   let isMath=entry.id=="original-math-quadratic"
   let target=isMath ? (image.cropping(to:CGRect(x:430,y:595,width:800,height:445)) ?? image) : image
   let targetWidth=(entry.physicalWidth ?? 0.21)*(isMath ? 800.0/1284.0 : 1)
   let reference = ARReferenceImage(target, orientation: .up, physicalWidth:targetWidth)
   if isMath {evidence("MATH_REFERENCE_CROP viewport=430,595,800,445 physicalTargetWidth=\(targetWidth) fullPageWidth=0.21")}
   reference.name = entry.id; reference.validate { error in evidence("SCIENCE_REFERENCE_VALIDATED id=\(entry.id) error=\(error?.localizedDescription ?? "none")") }; result.insert(reference)
  }
  evidence("SCIENCE_TARGETS_REGISTERED count=\(result.count)")
  return result
 }
 func validateMeshes() {
  let validator=SciencePages() // validation cannot replace the active scene controller
  for entry in entries {
   let loaded = validator.makeContent(id: entry.id)
   evidence("SCIENCE_CATALOG_CHECK id=\(entry.id) loaded=\(loaded != nil)")
   loaded?.removeAllActions()
  }
 }
 static func paintedGeometry(_ url: URL, texture: UIImage?) -> SCNGeometry? {
  guard let d=try? Data(contentsOf:url),d.count>=12,d.prefix(4)==Data("PLUV".utf8),let texture else{return nil}
  func u32(_ offset:Int)->Int { d.withUnsafeBytes { Int(UInt32(littleEndian:$0.loadUnaligned(fromByteOffset:offset,as:UInt32.self))) } }
  let vertices=u32(4),indices=u32(8);guard vertices>0,indices%3==0,d.count==12+vertices*32+indices*4 else{return nil}
  let src=d.subdata(in:12..<(12+vertices*32));let element=SCNGeometryElement(data:d.subdata(in:(12+vertices*32)..<d.count),primitiveType:.triangles,primitiveCount:indices/3,bytesPerIndex:4)
  let sources=[SCNGeometrySource(data:src,semantic:.vertex,vectorCount:vertices,usesFloatComponents:true,componentsPerVector:3,bytesPerComponent:4,dataOffset:0,dataStride:32),SCNGeometrySource(data:src,semantic:.normal,vectorCount:vertices,usesFloatComponents:true,componentsPerVector:3,bytesPerComponent:4,dataOffset:12,dataStride:32),SCNGeometrySource(data:src,semantic:.texcoord,vectorCount:vertices,usesFloatComponents:true,componentsPerVector:2,bytesPerComponent:4,dataOffset:24,dataStride:32)]
  let g=SCNGeometry(sources:sources,elements:[element]);let m=SCNMaterial();m.diffuse.contents=texture;m.lightingModel = .constant;m.isDoubleSided=false;var uvTransform=SCNMatrix4Identity;if ProcessInfo.processInfo.arguments.contains("--paint-flip-v") {uvTransform.m22 = -1;uvTransform.m42 = 1};m.diffuse.contentsTransform=uvTransform;g.materials=[m];evidence("PAINTED_UV_RENDER mode=constant_originalGLTF_UV atlasFlipDiagnostic=\(ProcessInfo.processInfo.arguments.contains("--paint-flip-v"))");return g
 }
 static func coloredOBJ(_ url: URL, yUp: Bool = false, texture: UIImage? = nil) -> SCNGeometry? {
  guard let text = try? String(contentsOf: url) else { return nil }
  var vertices: [SCNVector3] = [], colors: [Float] = [], indices: [UInt32] = [], uv: [CGPoint] = []
  for line in text.split(separator: "\n") {
   let parts = line.split(separator: " ")
   if parts.first == "v", parts.count >= 4, let x = Float(parts[1]), let y = Float(parts[2]), let z = Float(parts[3]) {
    vertices.append(yUp ? SCNVector3(x,y,z) : SCNVector3(x,z,-y))
    if parts.count >= 7 { colors += [Float(parts[4]) ?? 1,Float(parts[5]) ?? 1,Float(parts[6]) ?? 1,1] } else { colors += [0.7,0.7,0.7,1] }
   } else if parts.first == "vt", parts.count >= 3, let u=Double(parts[1]),let v=Double(parts[2]) {uv.append(CGPoint(x:u,y:1-v))
   } else if parts.first == "f", parts.count >= 4 {
    let face = parts.dropFirst().compactMap { UInt32($0.split(separator:"/")[0]) }.map { $0-1 }
    if face.count >= 3 { for i in 1..<(face.count-1) { indices += [face[0],face[i],face[i+1]] } }
   }
  }
  guard !vertices.isEmpty, !indices.isEmpty, indices.allSatisfy({ Int($0)<vertices.count }) else { return nil }
  var normals = Array(repeating: SIMD3<Float>(repeating:0), count:vertices.count)
  for i in stride(from:0,to:indices.count,by:3) {
   let a=Int(indices[i]),b=Int(indices[i+1]),c=Int(indices[i+2])
   let va=SIMD3<Float>(vertices[a].x,vertices[a].y,vertices[a].z), vb=SIMD3<Float>(vertices[b].x,vertices[b].y,vertices[b].z), vc=SIMD3<Float>(vertices[c].x,vertices[c].y,vertices[c].z)
   let n=simd_cross(vb-va,vc-va); normals[a]+=n;normals[b]+=n;normals[c]+=n
  }
  let normalSource=SCNGeometrySource(normals:normals.map { n in let m=simd_length(n);let v=m>0 ? n/m : SIMD3<Float>(0,1,0);return SCNVector3(v.x,v.y,v.z) })
  let colorData=colors.withUnsafeBytes { Data($0) }
  let colorSource=SCNGeometrySource(data:colorData,semantic:.color,vectorCount:vertices.count,usesFloatComponents:true,componentsPerVector:4,bytesPerComponent:4,dataOffset:0,dataStride:16)
  let element=SCNGeometryElement(data:indices.withUnsafeBytes { Data($0) },primitiveType:.triangles,primitiveCount:indices.count/3,bytesPerIndex:4)
  var sources=[SCNGeometrySource(vertices:vertices),normalSource];if texture != nil,uv.count==vertices.count {sources.append(SCNGeometrySource(textureCoordinates:uv))}else{sources.append(colorSource)}
  let geometry=SCNGeometry(sources:sources,elements:[element])
  let material=SCNMaterial();material.diffuse.contents=texture ?? UIImage();if texture==nil {material.diffuse.contents=UIColor.white};material.lightingModel = .lambert;material.isDoubleSided=true
  geometry.materials=[material]
  return geometry
 }
 func originalPhysics(_ entry: SciencePage) -> SCNNode? {
  guard let data=try? Data(contentsOf:directory.appendingPathComponent(entry.mesh)),let spec=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any],let parts=spec["parts"] as? [[String:Any]],let image=UIImage(contentsOfFile:directory.appendingPathComponent(entry.page).path) else{return nil}
  let root=SCNNode();let moving=SCNNode();moving.name="science-interaction";root.addChildNode(moving)
  let height=5.7 * image.size.height/image.size.width
  for part in parts {
   guard let file=part["file"] as? String,let name=part["id"] as? String,let cutout=UIImage(contentsOfFile:directory.appendingPathComponent(file).path) else{continue}
   if let bbox=part["bbox"] as? [Double],bbox.count==4,let rgb=part["repairRGB"] as? [Double],rgb.count==3 {
    let repair=SCNPlane(width:5.7*(bbox[2]-bbox[0]),height:height*CGFloat(bbox[3]-bbox[1]));let material=SCNMaterial();material.diffuse.contents=UIColor(red:rgb[0],green:rgb[1],blue:rgb[2],alpha:1);material.lightingModel = .constant;material.isDoubleSided=true;repair.materials=[material]
    let patch=SCNNode(geometry:repair);patch.name="derived-source-color-cover-"+name;patch.eulerAngles.x = -.pi/2;patch.position=SCNVector3(Float(5.7*((bbox[0]+bbox[2])/2-0.5)),0.012,Float(Double(height)*((bbox[1]+bbox[3])/2-0.5)));root.addChildNode(patch)
   }
   let plane=SCNPlane(width:5.7,height:height);let mat=SCNMaterial();mat.diffuse.contents=cutout;mat.lightingModel = .constant;mat.isDoubleSided=true;mat.writesToDepthBuffer=false;plane.materials=[mat]
   let node=SCNNode(geometry:plane);node.name=name;node.eulerAngles.x = -.pi/2;node.position.y=0.05;moving.addChildNode(node)
  }
  physicsAdapter = SourcePhysicsAdapter(root:moving, pageWidthMetres:entry.physicalWidth ?? 0.21)

  evidence("ORIGINAL_PHYSICS_LOADED id=\(entry.id) parts=\(moving.childNodes.count) repair=derived_source_color_cover_not_real_paper_erasure source=SAM2_original_RGB_exact motion=numerical_SI_authored_parameters_not_calibrated_experiment")
  return root
 }
 func originalMath(_ entry:SciencePage, binding:NativeMathBinding)->SCNNode? {
  let size=CGSize(width:1284,height:1541);let renderer=UIGraphicsImageRenderer(size:size)
  let overlay=renderer.image { ctx in
   let cg=ctx.cgContext
   if binding.selected {
    cg.setFillColor(UIColor.systemCyan.withAlphaComponent(0.18).cgColor);cg.fill(CGRect(x:835,y:600,width:195,height:28))
    cg.setStrokeColor(UIColor.systemCyan.cgColor);cg.setLineWidth(4);cg.stroke(CGRect(x:900,y:601,width:24,height:26));cg.stroke(CGRect(x:842,y:780,width:244,height:204))
    cg.setLineWidth(3);cg.move(to:CGPoint(x:912,y:630));cg.addLine(to:CGPoint(x:1065,y:780));cg.strokePath()
   }
   cg.saveGState();cg.clip(to:CGRect(x:842,y:780,width:244,height:204));cg.setStrokeColor(UIColor.systemCyan.cgColor);cg.setLineWidth(5)
   for i in 0...180 {let x = -7.2 + Double(i)*0.045;let p=binding.sourcePixel(x:x);if i==0 {cg.move(to:p)}else{cg.addLine(to:p)}};cg.strokePath();cg.restoreGState()
   (binding.equation as NSString).draw(at:CGPoint(x:835,y:745),withAttributes:[.font:UIFont.boldSystemFont(ofSize:18),.foregroundColor:UIColor.systemCyan])
  }
  let plane=SCNPlane(width:5.7,height:5.7*size.height/size.width);let material=SCNMaterial();material.diffuse.contents=overlay;material.lightingModel = .constant;material.isDoubleSided=true;material.writesToDepthBuffer=false;plane.materials=[material]
  let root=SCNNode();root.name="science-interaction";let node=SCNNode(geometry:plane);node.name="original-math-page-overlay";node.eulerAngles.x = -.pi/2;node.position.y=0.01;root.addChildNode(node)
  evidence("ORIGINAL_MATH_BOUND id=\(entry.id) a=\(binding.coefficient) originalEquation=x2+6x+10 sourceOrigin=1033,949 unitPixels=26.5 viewport=430,595,800,445 implementation=new_Swift_prepared_fixture_adapter_not_arbitrary_algebra")
  return root
 }
 func makeContent(id: String, textureVariant: Bool = false, mathBinding: NativeMathBinding = NativeMathBinding()) -> SCNNode? {
  diagramPhysicsAdapter = nil
  physicsAdapter = nil
  domainAdapter = nil
  guard let entry = entries.first(where: { $0.id == id }) else { return nil }
  if id==NativeTriangleBinding.pageID {sourceMathAdapter=nil;if triangleAdapter==nil {triangleAdapter=NativeTriangleAdapter()};evidence("SOURCE_TRIANGLE_LOADED normalized_units=true newly_authored_binding=true");return triangleAdapter?.makeNode()}
  triangleAdapter=nil
  if let kind=NativeSourceMathKind(rawValue:id) {
   if sourceMathAdapter?.kind != kind {sourceMathAdapter=NativeSourceMathAdapter(kind:kind)}
   evidence("SOURCE_MATH_LOADED id=\(id) model=\(sourceMathAdapter!.description) implementation=new_native_prepared_source_adapter")
   return sourceMathAdapter?.makeNode()
  }
  sourceMathAdapter=nil
  if entry.animation == "source-diagram-physics" {diagramPhysicsAdapter=SourceDiagramPhysicsAdapter(kind:id.replacingOccurrences(of:"original-physics-",with:""),directory:directory);return diagramPhysicsAdapter?.root}
  if entry.animation == "source-pixel-physics" {return originalPhysics(entry)}
  if entry.animation == "source-math-binding" {return originalMath(entry, binding:mathBinding)}
  let root = SCNNode(), model = SCNNode()
  root.name = "science-interaction"
  if entry.mesh.hasSuffix(".geom"),let textureFile=entry.texture {
   let texture=UIImage(contentsOfFile:directory.appendingPathComponent(textureFile).path)
   guard let geometry=Self.paintedGeometry(directory.appendingPathComponent(entry.mesh),texture:texture) else{return nil}
   model.addChildNode(SCNNode(geometry:geometry))
   evidence("ORIGINAL_REFERENCE_CAR_LOADED inferred=SAM2_Hunyuan2mini_Paint UV=preserved rig=none reference=prepared_exact_source_frame_crop")
  } else if entry.mesh.hasSuffix(".obj") {
   let paintedID=id.replacingOccurrences(of:"rx-",with:"");let painted=textureVariant && (entry.variantMesh != nil || ["car","butterfly"].contains(paintedID))
   let selectedMesh=painted ? (entry.variantMesh ?? "paint-"+paintedID+".geom") : entry.mesh
   let texture=painted ? UIImage(contentsOfFile:directory.appendingPathComponent(entry.variantTexture ?? "paint-"+paintedID+"-texture.png").path) : nil
   guard let geometry = (painted ? Self.paintedGeometry(directory.appendingPathComponent(selectedMesh),texture:texture) : Self.coloredOBJ(directory.appendingPathComponent(selectedMesh))) else { evidence("SCIENCE_MESH_LOAD_FAILED id=\(id)"); return nil }
   model.addChildNode(SCNNode(geometry: geometry));if painted {evidence("PAINTED_MESH_LOADED id=\(id) mesh=\(selectedMesh) texture=1024 UV=originalHunyuan inference=Hunyuan2mini_PaintTurbo")}
  } else {
   guard let scene = try? SCNScene(url: directory.appendingPathComponent(entry.mesh), options:nil) else { return nil }
   for node in scene.rootNode.childNodes { model.addChildNode(node.clone()) }
  }
  // ARImageAnchor page normal is +Y; GLTF source-image front is +Z.
  // Rotate the appearance basis into the page before bounds/normalization.
  let oriented=SCNNode();oriented.addChildNode(model);model.eulerAngles.x = -.pi/2
  let (minimum, maximum) = oriented.boundingBox
  let extent = max(maximum.x - minimum.x, max(maximum.y-minimum.y, maximum.z-minimum.z))
  guard extent.isFinite, extent > 0 else { return nil }
  // TripoSR coordinates are normalized; treat geometry as appearance, not measured anatomy.
  let sourceWidth=Float(entry.physicalWidth ?? 0.21)
  let referenceFraction:Float
  if let crop=entry.referenceCrop,let page=UIImage(contentsOfFile:directory.appendingPathComponent(entry.page).path)?.cgImage {referenceFraction=Float(crop[2])/Float(page.width)}else{referenceFraction=1}
  let targetMetres:Float = min(0.13,0.6*sourceWidth*referenceFraction) // matched source-relative size for both inference variants
  let targetUnits = targetMetres / Float(entry.physicalWidth ?? 0.21) * 5.7
  let scale: Float = targetUnits / extent
  evidence("SCIENCE_NORMALIZATION id=\(id) targetMetres=\(targetMetres) rawExtent=\(extent) scale=\(scale) centered=true")
  let centering = SCNNode(); centering.addChildNode(oriented)
  oriented.position = SCNVector3(-(minimum.x+maximum.x)/2, -minimum.y, -(minimum.z+maximum.z)/2)
  centering.scale = SCNVector3(scale, scale, scale)
  root.addChildNode(centering)
  centering.position.y = 0.02; centering.opacity = 0
  let reveal = SCNAction.group([.moveBy(x:0,y:0.45,z:0,duration:0.9), .fadeIn(duration:0.6)])
  reveal.timingMode = .easeOut
  centering.runAction(reveal)
  if id.hasPrefix("rx-") || id.hasPrefix("primary9-") || id=="original-oct2-printed-car" {
   domainAdapter=DomainInteractionAdapter(root:root,appearance:centering,id:id,action:entry.animation,directory:directory)
  } else {centering.runAction(.repeatForever(.rotateBy(x:0,y:Double.pi*2,z:0,duration:12)))}
  evidence("SCIENCE_MESH_LOADED id=\(id) file=\(entry.mesh) animation=\(entry.animation) provenance=inferred_unrigged_mesh_plus_explicit_authored_companion_mechanism")
  return root
 }
}

/// Sprite appearance stays source-pixel-faithful; these explicit SI parameters are teaching authoring.
final class SourcePhysicsAdapter {
 let root:SCNNode
 let unitsPerMetre:Double
 let bases:[String:SCNVector3]
 var spring=SourceSpringDynamics(),cart=SourceInclineDynamics()
 var isSpring:Bool {root.childNode(withName:"spring-mass",recursively:true) != nil}
 init(root:SCNNode,pageWidthMetres:Double) {
  self.root=root;unitsPerMetre=5.7/pageWidthMetres
  bases=Dictionary(uniqueKeysWithValues:root.childNodes.compactMap {node in node.name.map{($0,node.position)}})
  update(0)
 }
 func update(_ dt:Double) {
  if !root.isPaused { if isSpring {spring.advance(dt)}else{cart.advance(dt)} }
  if isSpring {
   if let mass=root.childNode(withName:"spring-mass",recursively:true),let base=bases["spring-mass"] {mass.position=SCNVector3(base.x,base.y,base.z+Float(spring.displacement*unitsPerMetre))}
   // Keep coil's original pixels and anchor fixed; do not scale the full page sprite.
  }else {
   for id in ["left-cart","right-cart"] {
    guard let node=root.childNode(withName:id,recursively:true),let base=bases[id] else{continue}
    let direction:Double=id=="left-cart" ? 1 : -1
    node.position=SCNVector3(base.x+Float(direction*cart.position*cos(cart.angle)*unitsPerMetre),base.y,base.z+Float(cart.position*sin(cart.angle)*unitsPerMetre))
   }
  }
 }
 func primaryControl() {if isSpring {spring.setStiffness(spring.stiffness*1.25)}else{cart.setAngle(cart.angle*180 / .pi+5);cart.reset()}}
 func secondaryControl() {if isSpring {spring.setMass(spring.mass*1.25)}else{cart.setFriction(cart.friction+0.05);cart.reset()}}
 func reset() {spring.reset();cart.reset();update(0)}
 var description:String {isSpring ? String(format:"SI spring: k %.1f N/m · m %.3f kg · x %.1f mm · authored parameters",spring.stiffness,spring.mass,spring.displacement*1000) : String(format:"SI incline: %.0f° · μ %.2f · v %.2f m/s · authored parameters",cart.angle*180 / .pi,cart.friction,cart.velocity)}
}
