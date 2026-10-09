import Foundation
struct NativeMathBinding {
 var coefficient: Double = 1
 var selected = true
 static let linear = 6.0, constant = 10.0
 mutating func setCoefficient(_ value: Double) { guard value.isFinite else{return};coefficient=min(3,max(0.25,value)) }
 func evaluate(_ x:Double)->Double {coefficient*x*x+Self.linear*x+Self.constant}
 var vertexX:Double {-Self.linear/(2*coefficient)}
 var vertexY:Double {evaluate(vertexX)}
 mutating func graphDrag(x:Double,y:Double)->Bool {guard x.isFinite,y.isFinite,abs(x)>0.05 else{return false};setCoefficient((y-Self.linear*x-Self.constant)/(x*x));return true}
 func sourcePixel(x:Double)->CGPoint {CGPoint(x:1033+x*26.5,y:949-evaluate(x)*26.5)}
 var equation:String {String(format:"f(x) = %.2f x² + 6x + 10",coefficient)}
}
