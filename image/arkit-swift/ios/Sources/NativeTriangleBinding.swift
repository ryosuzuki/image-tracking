import Foundation
import CoreGraphics

/// Original sample-10 Figure 0.2 has no printed numeric lengths. Units below are
/// explicitly normalized teaching units, not recovered measurements or OCR.
struct NativeTriangleBinding {
 static let pageID="original-math-triangle"
 static let sourceSize=CGSize(width:1240,height:1755)
 static let referenceCrop=CGRect(x:500,y:970,width:650,height:310)
 static let corner=CGPoint(x:1051,y:1218)
 static let pixelsPerUnit=212.0
 static let formulaBox=CGRect(x:563,y:1088,width:145,height:43)
 private(set) var a=1.0
 private(set) var b=132.0/212.0
 var selected=true
 var c:Double {hypot(a,b)}
 var angleDegrees:Double {atan2(b,a)*180 / .pi}
 var left:CGPoint {CGPoint(x:Self.corner.x-a*Self.pixelsPerUnit,y:Self.corner.y)}
 var upper:CGPoint {CGPoint(x:Self.corner.x,y:Self.corner.y-b*Self.pixelsPerUnit)}
 mutating func setA(_ value:Double){guard value.isFinite else{return};a=min(2.2,max(0.2,value))}
 mutating func setB(_ value:Double){guard value.isFinite else{return};b=min(2.2,max(0.2,value))}
 mutating func setAngle(_ degrees:Double){guard degrees.isFinite else{return};setB(a*tan(min(89,max(1,degrees)) * .pi/180))}
 mutating func drag(horizontal:Bool,pixel:CGPoint){if horizontal {setA((Self.corner.x-pixel.x)/Self.pixelsPerUnit)}else{setB((Self.corner.y-pixel.y)/Self.pixelsPerUnit)}}
 static func mapping(fullPageWidth:Double=0.21)->(targetWidth:Double,offsetX:Double,offsetZ:Double){let s=fullPageWidth/Double(sourceSize.width);return(Double(referenceCrop.width)*s,(Double(sourceSize.width)/2-Double(referenceCrop.midX))*s,(Double(sourceSize.height)/2-Double(referenceCrop.midY))*s)}
 var equation:String {String(format:"a %.3f · b %.3f · c %.3f · θ %.1f° · a²+b²=c²",a,b,c,angleDegrees)}
}
