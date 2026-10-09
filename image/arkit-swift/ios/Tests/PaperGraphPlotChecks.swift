import Foundation
@main struct PaperGraphPlotChecks {
 static func main(){var checks=0;func check(_ value:Bool,_ label:String){precondition(value,label);checks += 1}
  for a in [-2.0,0,0.25,1,3]{let plot=PaperGraphPlot(coefficient:a)
   for x in [-2.0,-1,0,1,2]{let point=plot.point(x);check(abs(point.x)<=0.036001 && abs(point.y)<=0.048001,"finite actualpoint within authoredcardplot");let xRecovered=point.x/plot.xScale,yRecovered = -point.y/plot.yScale;check(abs(yRecovered-a*xRecovered*xRecovered)<1e-10,"mapped point sits ON mathematicalcurve");guard let tangent=plot.tangent(x) else{fatalError("finite actualpoint tangent suppressed")};for endpoint in [tangent.0,tangent.1]{check(abs(endpoint.x)<=0.036001 && abs(endpoint.y)<=0.048001,"tangentsegment clipped not hidden");let tx=endpoint.x/plot.xScale,ty = -endpoint.y/plot.yScale;check(abs(ty-(a*x*x+2*a*x*(tx-x)))<1e-10,"clippedsegment retains analytic mathematicaltangent")};let h=1e-6,fd=(a*pow(x+h,2)-a*pow(x-h,2))/(2*h);check(abs(fd-2*a*x)<1e-8,"independent finite derivative preserved despite visualscale")}
  }
  let flat=PaperGraphPlot(coefficient:0);check(flat.clip(SIMD2(-3,0),SIMD2(3,0)) != nil,"horizontal crossing clippedvalid");check(flat.clip(SIMD2(-3,4),SIMD2(3,4))==nil,"fullyoutside segment rejected");check(flat.tangent(.nan)==nil,"nonfinite geometry rejected");print("PaperGraphPlotChecks: \(checks) passed; authoredgeometry not physicalmetric evidence")
 }
}
