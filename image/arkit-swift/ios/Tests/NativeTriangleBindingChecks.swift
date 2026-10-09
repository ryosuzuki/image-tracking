import Foundation
@main struct NativeTriangleBindingChecks {
 static func near(_ a:Double,_ b:Double,_ e:Double=1e-9){precondition(abs(a-b)<e,"\(a) != \(b)")}
 static func main(){
  var m=NativeTriangleBinding()
  near(m.left.x,839);near(m.left.y,1218);near(m.upper.x,1051);near(m.upper.y,1086)
  near(m.a*m.a+m.b*m.b,m.c*m.c)
  m.setA(1.2);m.setB(1.6);near(m.c,2);near(m.angleDegrees,53.13010235415598)
  m.setA(1);m.setAngle(45);near(m.b,1);near(m.c,sqrt(2))
  m.setA(.nan);m.setB(.infinity);m.setAngle(-.infinity);near(m.a,1);near(m.b,1)
  m.setA(-50);m.setB(50);near(m.a,0.2);near(m.b,2.2)
  m.drag(horizontal:true,pixel:CGPoint(x:839,y:10));near(m.a,1);near(m.b,2.2)
  m.drag(horizontal:false,pixel:CGPoint(x:10,y:1006));near(m.b,1)
  for a in stride(from:0.2,through:2.2,by:0.1){for theta in stride(from:10.0,through:80.0,by:5){m.setA(a);m.setAngle(theta);precondition(m.c.isFinite && m.angleDegrees>0 && m.angleDegrees<90);near(m.a*m.a+m.b*m.b,m.c*m.c);near(m.left.y,NativeTriangleBinding.corner.y);near(m.upper.x,NativeTriangleBinding.corner.x)}}
  let map=NativeTriangleBinding.mapping();near(map.targetWidth,650.0/1240*0.21)
  // A full-page point lands on the crop's corresponding coordinate after displacement.
  let scale=0.21/1240.0,crop=NativeTriangleBinding.referenceCrop
  near((1051.0-620)*scale+map.offsetX,(1051-Double(crop.midX))*scale)
  near((1218.0-877.5)*scale+map.offsetZ,(1218-Double(crop.midY))*scale)
  print("PASS triangle source landmarks, right-angle invariant, Pythagoras, angle coupling, input bounds and crop mapping")
 }
}
