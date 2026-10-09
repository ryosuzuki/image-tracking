import Foundation
import CryptoKit

/// Prepared source fixtures only. These parameters are authored, not OCR, fitted calibration or general MNA.
struct SourceThinLens {
 var objectX = 350.0, focal = 124.0
 let lensX = 653.0, axisY = 567.0, objectHeight = 80.0
 struct Solution { let distance:Double; let imageDistance:Double?; let magnification:Double?; let imageX:Double?; let imageY:Double?; var atFocus:Bool { imageDistance == nil } }
 var solution:Solution {
  let d=lensX-objectX,den=d-focal
  guard abs(den)>0.01,d>0 else{return Solution(distance:d,imageDistance:nil,magnification:nil,imageX:nil,imageY:nil)}
  let v=focal*d/den,m = -v/d
  return Solution(distance:d,imageDistance:v,magnification:m,imageX:lensX+v,imageY:axisY-objectHeight*m)
 }
 mutating func setObjectX(_ x:Double){guard x.isFinite else{return};objectX=min(635,max(150,x))}
 mutating func setFocal(_ x:Double){guard x.isFinite else{return};focal=min(220,max(30,x))}
}
struct SourceSeriesCircuit {
 var voltage=100.0,r1=300.0,r2=200.0
 var current:Double {voltage/(r1+r2)}
 var drops:[Double] {[current*r1,current*r2]}
 mutating func setVoltage(_ x:Double){guard x.isFinite else{return};voltage=min(200,max(0,x))}
 mutating func setR1(_ x:Double){guard x.isFinite else{return};r1=min(1000,max(1,x))}
 mutating func setR2(_ x:Double){guard x.isFinite else{return};r2=min(1000,max(1,x))}
}
struct SourceNonlinearPendulum {
 static let sourceAngle=atan2(-102.0,193.0),sourceLengthPixels=hypot(102.0,193.0)
 var angle=Self.sourceAngle,velocity=0.0,time=0.0,length=1.0,damping=0.02,initialAngle=Self.sourceAngle
 var energy:Double {0.5*length*length*velocity*velocity+9.81*length*(1-cos(angle))} // per unit mass
 var bobPixel:[Double] {[259+Self.sourceLengthPixels*sin(angle),61+Self.sourceLengthPixels*cos(angle)]}
 mutating func reset(){angle=initialAngle;velocity=0;time=0}
 mutating func setLength(_ x:Double){guard x.isFinite else{return};length=min(3,max(0.2,x))}
 /// Magnitude buttons keep the side selected by the user instead of snapping left.
 mutating func setAmplitude(_ degrees:Double){guard degrees.isFinite else{return};let sign=initialAngle>0 ? 1.0:-1.0;initialAngle = sign*min(85,max(5,degrees)) * .pi/180;reset()}
 /// Direct bob dragging is signed: right is positive, vertical is equilibrium.
 mutating func setSignedAmplitude(_ degrees:Double){guard degrees.isFinite else{return};initialAngle = min(85,max(-85,degrees)) * .pi/180;reset()}
 mutating func advance(_ interval:Double){
  guard interval.isFinite,interval>0 else{return};let duration=min(interval,0.1),steps=max(1,Int(ceil(duration/0.002))),dt=duration/Double(steps)
  func acceleration(_ a:Double,_ v:Double)->Double {-9.81/length*sin(a)-damping*v}
  for _ in 0..<steps {let a=angle,v=velocity,k1a=v,k1v=acceleration(a,v),k2a=v+dt*k1v/2,k2v=acceleration(a+dt*k1a/2,v+dt*k1v/2),k3a=v+dt*k2v/2,k3v=acceleration(a+dt*k2a/2,v+dt*k2v/2),k4a=v+dt*k3v,k4v=acceleration(a+dt*k3a,v+dt*k3v);angle += dt*(k1a+2*k2a+2*k3a+k4a)/6;velocity += dt*(k1v+2*k2v+2*k3v+k4v)/6;time += dt}
 }
}
struct SourceDiagramProvenance:Decodable {
 struct Asset:Decodable {let file:String,sha256:String}
 let id:String,page:Asset,cutout:Asset?,mask:Asset?,rawMask:Asset?,crop:[Double]?,sourceSize:[Double],scope:String
 func verifiedData(_ asset:Asset,directory:URL)->Data? {
  guard asset.file==URL(fileURLWithPath:asset.file).lastPathComponent,asset.sha256.count==64,let d=try? Data(contentsOf:directory.appendingPathComponent(asset.file)),Self.digest(d)==asset.sha256 else{return nil};return d
 }
 static func digest(_ d:Data)->String {SHA256.hash(data:d).map{String(format:"%02x",$0)}.joined()}
 func validate(directory:URL)->Bool {verifiedData(page,directory:directory) != nil && (cutout == nil || verifiedData(cutout!,directory:directory) != nil) && (mask == nil || verifiedData(mask!,directory:directory) != nil) && (rawMask == nil || verifiedData(rawMask!,directory:directory) != nil)}
}
