import Foundation
import CoreGraphics

/// Prepared original source fixtures, not OCR or arbitrary algebra.
enum NativeSourceMathKind: String {
 case sine = "original-math-sine", summation = "original-math-summation"
 var sourceSize: CGSize { self == .sine ? CGSize(width:1284,height:1541) : CGSize(width:1275,height:1651) }
 var referenceCrop: CGRect { self == .sine ? CGRect(x:430,y:1030,width:800,height:445) : CGRect(x:450,y:1140,width:440,height:250) }
 var pageFilename: String { self == .sine ? "original-math-quadratic.png" : "original-math-summation.jpg" }
 /// Reference crop physical width and full-page displacement from crop centre, in metres.
 func mapping(fullPageWidth: Double = 0.21) -> (targetWidth:Double, offsetX:Double, offsetZ:Double) {
  let s=sourceSize,c=referenceCrop,scale=fullPageWidth/Double(s.width)
  return (Double(c.width)*scale, (Double(s.width)/2-Double(c.midX))*scale, (Double(s.height)/2-Double(c.midY))*scale)
 }
}
struct NativeSineBinding {
 private(set) var frequency:Double = 2
 var selected = true
 static let origin = CGPoint(x:869,y:1311)
 static let graphBox = CGRect(x:726,y:1205,width:432,height:183)
 static let equationBox = CGRect(x:453,y:1061,width:133,height:28)
 static let coefficientBox = CGRect(x:558,y:1063,width:15,height:24)
 mutating func setFrequency(_ value:Double) { guard value.isFinite else{return};frequency=min(5,max(0.25,value)) }
 func evaluate(_ x:Double)->Double {sin(frequency*x)}
 var period:Double {2 * .pi/frequency}
 func sourcePixel(x:Double)->CGPoint {CGPoint(x:Self.origin.x+x*37,y:Self.origin.y-evaluate(x)*37)}
 var equation:String {String(format:"y = sin(%.2f x) · period %.3f",frequency,period)}
}
struct NativeSummationBinding {
 private(set) var lower = 1
 private(set) var upper = 20
 var selected = true
 static let formulaBox=CGRect(x:605,y:1180,width:60,height:65)
 static let upperBox=CGRect(x:614,y:1181,width:28,height:20)
 static let lowerBox=CGRect(x:607,y:1228,width:38,height:18)
 mutating func setLower(_ value:Int) { lower=min(100,max(0,value)) }
 mutating func setUpper(_ value:Int) { upper=min(100,max(0,value)) }
 var terms:[Int] {upper < lower ? [] : Array(lower...upper)}
 var total:Int {terms.reduce(0,+)}
 var equation:String {"Σ(i=\(lower)…\(upper)) i"}
 var expansion:String {terms.isEmpty ? "0 = 0" : terms.map(String.init).joined(separator:" + ")+" = \(total)"}
 /// Bound dragging follows whole source-pixel steps; each 15-pixel move changes one index.
 mutating func dragBound(upper isUpper:Bool, initial:Int, sourceDeltaY:Double) {
  guard sourceDeltaY.isFinite else{return}
  let delta=Int(min(100,max(-100,(-sourceDeltaY/15).rounded())))
  if isUpper {setUpper(initial+delta)}else{setLower(initial+delta)}
 }
}
