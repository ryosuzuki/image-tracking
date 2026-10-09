import Foundation
@main struct NativeMathBindingChecks {
 static func main() {
  func near(_ a:Double,_ b:Double){precondition(abs(a-b)<1e-7)}
  var b=NativeMathBinding();near(b.evaluate(-3),1);near(b.vertexX,-3);near(b.vertexY,1);near(Double(b.sourcePixel(x:-3).x),953.5);near(Double(b.sourcePixel(x:-3).y),922.5)
  b.setCoefficient(2);near(b.vertexX,-1.5);near(b.vertexY,5.5);near(b.evaluate(-2),6)
  precondition(b.graphDrag(x:-2,y:6));near(b.coefficient,2)
  precondition(!b.graphDrag(x:0,y:6));near(b.coefficient,2)
  b.setCoefficient(-100);near(b.coefficient,0.25);b.setCoefficient(100);near(b.coefficient,3);b.setCoefficient(.nan);near(b.coefficient,3)
  print("PASS: printed equation baseline, graph pixel mapping, controlled coefficient, inverse graph binding, singular inverse guard, bounded finite updates")
 }
}
