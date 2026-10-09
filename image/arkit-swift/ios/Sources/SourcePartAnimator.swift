import UIKit
import SceneKit
import CryptoKit

/// Actual learned source parts, not generated primitive companion stand-ins.
/// Attach root directly in full-page-centered 5.7-unit space, +Y normal / up=-Z.
/// Parent owns stage controls, whole-body visibility and image tracking lifecycle.
final class SourcePartAnimator {
 struct Asset:Decodable {let file:String,sha256:String}
 struct Part:Decodable {
  let id:String,bbox:[Double],centroid:[Double],cutout:Asset
  let baselineGeometry:Asset,baselineTexture:Asset,selectedGeometry:Asset,selectedTexture:Asset
  let fallback2D:Bool,hostZDegrees:Double,quantity:Int
  let rotationAxis:[Double]?,hinge:[Double]?,hostBasis:[Double]?,sourceFaceNormal:[Double]?
 }
 struct Page:Decodable {let pageID:String,domainID:String,page:Asset,sourceSize:[Double],referenceCrop:[Double],parts:[Part]}
 struct Config:Decodable {let schema:String,pageWidthUnits:Double,pages:[Page],selectionManifest:Asset}
 struct CatalogEntry:Decodable {let id:String,page:String;let referenceCrop:[Double]?}
 let root=SCNNode()
 private let page:Page
 private var flat:[SCNNode]=[],volume:[SCNNode]=[],flatMotion:[SCNNode]=[],volumeMotion:[SCNNode]=[]
 private init(page:Page){self.page=page;root.name="actual-source-parts-"+page.pageID;root.isHidden=true}
 static func make(pageID:String,directory:URL)->SourcePartAnimator? {
  guard let data=try? Data(contentsOf:directory.appendingPathComponent("source-parts-animator.json")),
   let cfg=try? JSONDecoder().decode(Config.self,from:data),cfg.schema=="source-parts-native-v2",cfg.pageWidthUnits==5.7,cfg.pages.count==6,Set(cfg.pages.map(\.pageID))==Set(["primary9-solar-system","primary9-arithmetic","primary9-cell","primary9-dna","primary9-machine","primary9-origami"]),cfg.pages.allSatisfy({valid($0)}),checked(cfg.selectionManifest,directory) != nil,
   let page=cfg.pages.first(where:{$0.pageID==pageID}),valid(page),
   let catalogData=try? Data(contentsOf:directory.appendingPathComponent("manifest.json")),let catalog=try? JSONDecoder().decode([CatalogEntry].self,from:catalogData),
   let entry=catalog.first(where:{$0.id==pageID}),entry.page==page.page.file,entry.referenceCrop==page.referenceCrop,
   let imageData=checked(page.page,directory),let pageImage=UIImage(data:imageData)?.cgImage,pageImage.width==1000,pageImage.height==1400 else{return nil}
  let animator=SourcePartAnimator(page:page)
  // Parent primary9 content origin is selected reference-crop centre.
  animator.root.position=SCNVector3((500-(page.referenceCrop[0]+page.referenceCrop[2]/2))*5.7/1000,0,(700-(page.referenceCrop[1]+page.referenceCrop[3]/2))*5.7/1000)
  for part in page.parts {
   // Validate even unused baseline/blue meshes: no silent partial or altered delivery.
   guard let cutoutData=checked(part.cutout,directory),let cutout=UIImage(data:cutoutData),let cg=cutout.cgImage,
    cg.width==Int(part.bbox[2]-part.bbox[0]),cg.height==Int(part.bbox[3]-part.bbox[1]),
    let baseline=checked(part.baselineGeometry,directory),mesh(baseline,texture:nil,hostZDegrees:0) != nil,
    let baselineTexture=checked(part.baselineTexture,directory),UIImage(data:baselineTexture) != nil,
    let selected=checked(part.selectedGeometry,directory),let selectedTex=checked(part.selectedTexture,directory),let texture=UIImage(data:selectedTex),
    let geometry=mesh(selected,texture:texture,hostZDegrees:part.hostZDegrees,hostBasis:part.hostBasis) else{return nil}
   let flatRoot=SCNNode(),volumeRoot=SCNNode();flatRoot.name=part.id+"-learned-source-RGBA";volumeRoot.name=part.id+(part.fallback2D ? "-declared-source-2.5D-fallback":"-actual-inferred-unrigged-3D")
   let plane=sourcePlane(part:part,image:cutout);flatRoot.addChildNode(plane)
   if part.fallback2D {volumeRoot.addChildNode(sourcePlane(part:part,image:cutout))}
   else {
    let model=SCNNode(geometry:geometry),bounds=model.boundingBox,min=bounds.0,max=bounds.1
    // Source front basis is already applied to geometry BEFORE these bounds.
    let extent=Swift.max(max.x-min.x,Swift.max(max.y-min.y,max.z-min.z))
    guard extent.isFinite,extent>0 else{return nil}
    let target=SCNFloat(Swift.max(part.bbox[2]-part.bbox[0],part.bbox[3]-part.bbox[1])*5.7/1000),scale=target/extent
    model.scale=SCNVector3(scale,scale,scale)
    model.position=SCNVector3(-(min.x+max.x)*0.5*scale,-min.y*scale,-(min.z+max.z)*0.5*scale)
    volumeRoot.addChildNode(model)
   }
   var flatRotator=flatRoot,volumeRotator=volumeRoot
   if let hinge=part.hinge {
    let h=pagePosition([(hinge[0]+hinge[2])/2,(hinge[1]+hinge[3])/2]),center=pagePosition(part.centroid),delta=SCNVector3(h.x-center.x,0,h.z-center.z)
    func hingeNode(_ holder:SCNNode)->SCNNode {let wrapper=SCNNode();wrapper.name="authored-source-crease-hinge";wrapper.position=delta;for child in holder.childNodes {child.removeFromParentNode();child.position.x -= delta.x;child.position.z -= delta.z;wrapper.addChildNode(child)};holder.addChildNode(wrapper);return wrapper}
    flatRotator=hingeNode(flatRoot);volumeRotator=hingeNode(volumeRoot)
   }
   animator.flatMotion.append(flatRotator);animator.volumeMotion.append(volumeRotator)
   animator.flat.append(flatRoot);animator.volume.append(volumeRoot);animator.root.addChildNode(flatRoot);animator.root.addChildNode(volumeRoot)
  }
  animator.update(state:DomainInteractionState(id:page.domainID));return animator
 }
 /// All page positions remain in original source coordinates, NOT crop-normalized.
 static func pagePosition(_ pixel:[Double],normal:Double=0.03)->SCNVector3 {SCNVector3((pixel[0]-500)*5.7/1000,normal,(pixel[1]-700)*5.7/1000)}
 static func positions(page:Page,state:DomainInteractionState)->[SCNVector3] {
  let rate=state.phase,amount=0.75+0.5*state.parameter
  if page.domainID=="solar-system",let sun=page.parts.first(where:{$0.id=="solar-sun"}) {
   let center=pagePosition(sun.centroid)
   return page.parts.enumerated().map {i,part in
    if part.id=="solar-sun" {return center}
    let p=pagePosition(part.centroid),dx=Double(p.x-center.x),dz=Double(p.z-center.z),angle=rate*(0.35+Double(i)*0.15)
    return SCNVector3(Double(center.x)+(dx*cos(angle)-dz*sin(angle))*amount,0.03,Double(center.z)+(dx*sin(angle)+dz*cos(angle))*amount)
   }
  }
  let ease=1-cos(min(1,max(0,state.time)) * .pi/2),separation=state.parameter*0.8*ease
  return page.parts.enumerated().map {i,part in
   var p=pagePosition(part.centroid)
   switch page.domainID {
   case "arithmetic":if state.stage != 0 {p.x += SCNFloat((i<2 ? -1.0:1.0)*separation)}
   case "cell":if i>0 {p.x += SCNFloat((i==1 ? -1.0:1.0)*separation);p.y += SCNFloat((i==1 ? 0.5:0.8)*state.parameter*ease)}
   case "dna":p.x += SCNFloat((i==0 ? -1.0:1.0)*separation)
   default:break
   }
   return p
  }
 }
 /// Rigid authored source-part rotations. Gear 3D axes come from selected mesh
 /// observed face normals; a 2.5D source plane rotates about its own page normal.
 static func rotation(part:Part,index:Int,page:Page,state:DomainInteractionState,flat:Bool)->SCNVector4 {
  if page.domainID=="machine" {let axis=flat || part.fallback2D ? [0.0,1,0]:part.rotationAxis!;return SCNVector4(axis[0],axis[1],axis[2],state.phase*(index==0 ? 1:-1))}
  if page.domainID=="origami",let h=part.hinge {
   let dx=h[2]-h[0],dz=h[3]-h[1],length=hypot(dx,dz),ease=1-cos(min(1,max(0,state.time)) * .pi/2)
   return SCNVector4(dx/length,0,dz/length,state.foldAngle*ease*(index==0 ? 1:-1))
  }
  return SCNVector4(0,1,0,0)
 }

 func update(state:DomainInteractionState) {
  guard (state.id==page.domainID || state.id==page.pageID),state.stage>=0,state.stage<=2,state.time.isFinite,state.parameter.isFinite,(0...1).contains(state.parameter) else{root.isHidden=true;return}
  root.isHidden=state.stage==0
  let locations=Self.positions(page:page,state:state)
  for i in page.parts.indices {
   flat[i].isHidden=state.stage != 1;volume[i].isHidden=state.stage != 2
   flat[i].position=locations[i];volume[i].position=locations[i]
   flatMotion[i].rotation=Self.rotation(part:page.parts[i],index:i,page:page,state:state,flat:true)
   volumeMotion[i].rotation=Self.rotation(part:page.parts[i],index:i,page:page,state:state,flat:false)
  }
 }
 /// Describe the source-part motion, not the unrelated opt-in companion's ratio.
 func parameterDescription(state:DomainInteractionState)->String {
  switch page.domainID {
  case "machine":return String(format:"source gear rate %.2f · equal/opposite authored rotation (1:1)",state.frequency)
  case "cell":return String(format:"source compartment separation %.0f%%",state.parameter*100)
  case "dna":return String(format:"source strand separation %.0f%%",state.parameter*100)
  default:return state.label
  }
 }
 func modeDescription(state:DomainInteractionState)->String {
  if state.stage==0 {return "Whole-body preview · source-part root hidden"}
  let fallback=page.parts.filter{$0.fallback2D}.count
  let mode=state.stage==1 ? "\(page.parts.count) learned exact-source RGBA parts · 2.5D" : "\(page.parts.count-fallback) inferred 3D parts + \(fallback) declared exact-RGBA fallbacks"
  let action:String
  switch page.domainID {
  case "solar-system":action="Sun + 4 visible source forms · authored normalized orbits; hidden blue planet unrecovered"
  case "arithmetic":action="5 source columns → 2 + 3 · full-model column4 · quantities preserved"
  case "cell":action="3 visible compartments explode · membrane source-RGBA · group not independent organelle rig"
  case "dna":action="2 visible strands unzip · hidden connectivity/bonds not recovered, none fabricated"
  case "machine":action="2 actual gears turn oppositely · equal authored rate, not calibrated transmission"
  default:action="2 visible paper panels hinge at authored source crease · not recovered folding rig"
  }
  return mode+" · "+action+" · unrigged/authored kinematics"
 }

 private static func valid(_ p:Page)->Bool {
  let expected:[String:[String]]=[
   "solar-system":["solar-sun","solar-red","solar-green","solar-purple","solar-blue"],
   "arithmetic":["arithmetic-column-1","arithmetic-column-2","arithmetic-column-3","arithmetic-column-4","arithmetic-column-5"],
   "cell":["cell-membrane","cell-nucleus","cell-organelle-group"],"dna":["dna-red-strand","dna-blue-strand"],
   "machine":["machine-blue-gear","machine-yellow-gear"],"origami":["origami-left-panel","origami-right-panel"]]
  guard let ids=expected[p.domainID] else{return false}
  guard p.pageID.hasPrefix("primary9-"),p.pageID=="primary9-"+p.domainID,p.sourceSize==[1000,1400],p.parts.map(\.id)==ids,p.referenceCrop.count==4,p.referenceCrop.allSatisfy({$0.isFinite}),p.referenceCrop[0]>=0,p.referenceCrop[1]>=0,p.referenceCrop[2]>0,p.referenceCrop[3]>0,p.referenceCrop[0]+p.referenceCrop[2]<=1000,p.referenceCrop[1]+p.referenceCrop[3]<=1400 else{return false}
  return p.parts.allSatisfy {part in
   guard part.quantity==1,part.bbox.count==4,part.centroid.count==2,part.bbox.allSatisfy({$0.isFinite}),part.centroid.allSatisfy({$0.isFinite}),part.bbox[0]>=0,part.bbox[1]>=0,part.bbox[2]<=1000,part.bbox[3]<=1400,part.bbox[2]>part.bbox[0],part.bbox[3]>part.bbox[1],part.centroid[0]>=part.bbox[0],part.centroid[0]<=part.bbox[2],part.centroid[1]>=part.bbox[1],part.centroid[1]<=part.bbox[3] else{return false}
   if p.domainID=="machine" {
    guard part.rotationAxis==[0,1,0],let n=part.sourceFaceNormal,n.count==3,n.allSatisfy({$0.isFinite}),abs(n.reduce(0){$0+$1*$1}-1)<1e-6,let m=part.hostBasis,m.count==9,m.allSatisfy({$0.isFinite}) else{return false}
    for i in 0..<3 {for j in 0..<3 {let dot=(0..<3).reduce(0.0){$0+m[i*3+$1]*m[j*3+$1]};guard abs(dot-(i==j ? 1:0))<1e-6 else{return false}}}
    let det=m[0]*(m[4]*m[8]-m[5]*m[7])-m[1]*(m[3]*m[8]-m[5]*m[6])+m[2]*(m[3]*m[7]-m[4]*m[6]);guard abs(det-1)<1e-6 else{return false}
    for i in 0..<3 {let mapped=(0..<3).reduce(0.0){$0+m[i*3+$1]*n[$1]};guard abs(mapped-(i==2 ? 1:0))<1e-6 else{return false}}
   } else if part.hostBasis != nil || part.sourceFaceNormal != nil {return false}
   if p.domainID=="origami" {guard let h=part.hinge,h.count==4,h.allSatisfy({$0.isFinite && $0>=0}),h[0]<=1000,h[2]<=1000,h[1]<=1400,h[3]<=1400,hypot(h[2]-h[0],h[3]-h[1])>1 else{return false}}
   let selectedID=part.id=="arithmetic-column-4" ? "arithmetic-column-4-full-seed42":part.id
   return part.cutout.file=="sourceparts-"+part.id+"-cutout.png" && part.baselineGeometry.file=="sourceparts-"+part.id+".geom" && part.baselineTexture.file=="sourceparts-"+part.id+"-swift-texture.png" && part.selectedGeometry.file=="sourceparts-"+selectedID+".geom" && part.selectedTexture.file=="sourceparts-"+selectedID+"-swift-texture.png" && part.fallback2D==Set(["solar-blue","cell-membrane","cell-organelle-group","origami-right-panel"]).contains(part.id) && part.hostZDegrees==(part.id=="arithmetic-column-4" ? -27:0)
  }
 }
 private static func checked(_ a:Asset,_ directory:URL)->Data? {
  guard a.file==URL(fileURLWithPath:a.file).lastPathComponent,a.sha256.count==64,let d=try? Data(contentsOf:directory.appendingPathComponent(a.file)),SHA256.hash(data:d).map({String(format:"%02x",$0)}).joined()==a.sha256 else{return nil};return d
 }
 private static func sourcePlane(part:Part,image:UIImage)->SCNNode {
  let p=SCNPlane(width:(part.bbox[2]-part.bbox[0])*5.7/1000,height:(part.bbox[3]-part.bbox[1])*5.7/1000),m=SCNMaterial()
  m.diffuse.contents=image;m.lightingModel = .constant;m.isDoubleSided=true;m.blendMode = .alpha;p.materials=[m]
  let node=SCNNode(geometry:p);node.eulerAngles.x = -.pi/2
  // Container pivot is actual alpha centroid; plane centre is original crop centre.
  node.position=SCNVector3(((part.bbox[0]+part.bbox[2])/2-part.centroid[0])*5.7/1000,0,((part.bbox[1]+part.bbox[3])/2-part.centroid[1])*5.7/1000)
  return node
 }
 private static func mesh(_ data:Data,texture:UIImage?,hostZDegrees:Double,hostBasis:[Double]?=nil)->SCNGeometry? {
  guard data.count>=12,data.prefix(4)==Data("PLUV".utf8) else{return nil}
  func u32(_ offset:Int)->UInt32 {data.withUnsafeBytes{$0.loadUnaligned(fromByteOffset:offset,as:UInt32.self).littleEndian}}
  func f32(_ offset:Int)->Float {Float(bitPattern:u32(offset))}
  let count=Int(u32(4)),indexCount=Int(u32(8));guard count>0,count<=1_000_000,indexCount>0,indexCount%3==0,indexCount<=6_000_000,data.count==12+count*32+indexCount*4 else{return nil}
  let angle=Float(hostZDegrees * .pi/180),c=cos(angle),s=sin(angle)
  func basis(_ x:Float,_ y:Float,_ z:Float)->SCNVector3 {
   var a=x,b=y,d=z
   if let m=hostBasis {a=Float(m[0])*x+Float(m[1])*y+Float(m[2])*z;b=Float(m[3])*x+Float(m[4])*y+Float(m[5])*z;d=Float(m[6])*x+Float(m[7])*y+Float(m[8])*z}
   return SCNVector3(c*a-s*b,d,-(s*a+c*b))
  }
  var vertices:[SCNVector3]=[],normals:[SCNVector3]=[],uv:[CGPoint]=[]
  for i in 0..<count {
   let at=12+i*32,v=(0..<8).map{f32(at+$0*4)};guard v.allSatisfy({$0.isFinite}) else{return nil}
   vertices.append(basis(v[0],v[1],v[2]));normals.append(basis(v[3],v[4],v[5]));uv.append(CGPoint(x:Double(v[6]),y:Double(v[7])))
  }
  let offset=12+count*32;for i in 0..<indexCount {guard Int(u32(offset+i*4))<count else{return nil}}
  let element=SCNGeometryElement(data:data.subdata(in:offset..<data.count),primitiveType:.triangles,primitiveCount:indexCount/3,bytesPerIndex:4)
  let geometry=SCNGeometry(sources:[SCNGeometrySource(vertices:vertices),SCNGeometrySource(normals:normals),SCNGeometrySource(textureCoordinates:uv)],elements:[element]),m=SCNMaterial()
  m.diffuse.contents=texture;m.lightingModel = .constant;m.isDoubleSided=true;geometry.materials=[m]
  // UIImage texture identity is intentional: parent proved no extra UV flip.
  return geometry
 }
}
