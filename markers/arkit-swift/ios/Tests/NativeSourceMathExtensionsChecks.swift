import Foundation
@main struct NativeSourceMathExtensionsChecks {
 static func main() {
  func near(_ a:Double,_ b:Double){precondition(abs(a-b)<1e-7)}
  var s=NativeSineBinding();near(s.period,.pi);near(s.evaluate(.pi/4),1);near(Double(s.sourcePixel(x:.pi/4).y),1274)
  near(Double(s.sourcePixel(x:0).x),869);near(Double(s.sourcePixel(x:0).y),1311)
  s.setFrequency(4);near(s.period,.pi/2);near(s.evaluate(.pi/8),1);s.setFrequency(.nan);near(s.frequency,4)
  s.setFrequency(-1);near(s.frequency,0.25);s.setFrequency(99);near(s.frequency,5)
  var sum=NativeSummationBinding();precondition(sum.terms.count==20 && sum.total==210)
  sum.setLower(3);sum.setUpper(5);precondition(sum.terms==[3,4,5] && sum.expansion=="3 + 4 + 5 = 12")
  sum.dragBound(upper:true,initial:5,sourceDeltaY:-30);precondition(sum.upper==7 && sum.total==25)
  sum.setLower(9);precondition(sum.terms.isEmpty && sum.total==0 && sum.expansion=="0 = 0")
  sum.setLower(-999);sum.setUpper(999);precondition(sum.lower==0 && sum.upper==100 && sum.total==5050)
  for k in [NativeSourceMathKind.sine,.summation] {
   let m=k.mapping(),r=k.referenceCrop,s=k.sourceSize,scale=0.21/Double(s.width)
   near(m.targetWidth,Double(r.width)*scale)
   near(m.offsetX+Double(r.midX)*scale,Double(s.width)/2*scale)
   near(m.offsetZ+Double(r.midY)*scale,Double(s.height)/2*scale)
  }
  print("PASS source sine analytic baseline/period/input clamps; summation identity/bounds/empty/drag; both crop-to-page centres")
 }
}
