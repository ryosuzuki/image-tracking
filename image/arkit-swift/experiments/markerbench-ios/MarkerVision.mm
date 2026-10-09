#import "MarkerVision.h"
#include <TargetConditionals.h>
#if !TARGET_OS_SIMULATOR
#include <opencv2/imgproc.hpp>
#include <opencv2/calib3d.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/objdetect/aruco_detector.hpp>
#include <chrono>
using namespace cv;
static NSDictionary *poseResult(const std::vector<Point2f>& c,int ident,const Mat& K,double extent,double ms,const std::vector<Point3f>& points={}){
 // Page frame: +X right, +Y down, +Z toward page back. Frame is converted to ARKit camera convention in Swift.
 std::vector<Point3f> p={{float(-extent/2),float(-extent/2),0},{float(extent/2),float(-extent/2),0},{float(extent/2),float(extent/2),0},{float(-extent/2),float(extent/2),0}};
 if(!points.empty())p=points; Mat r,t; if(!solvePnP(p,c,K,noArray(),r,t,false,SOLVEPNP_IPPE))return nil;
 if(t.at<double>(2)<=0)return nil; Mat R;Rodrigues(r,R);std::vector<Point2f> projected;projectPoints(p,r,t,K,noArray(),projected);double err=0;for(size_t i=0;i<c.size();i++)err+=norm(projected[i]-c[i]);err/=c.size();
 if(!std::isfinite(err)||err>6)return nil;
 NSMutableArray *matrix=[NSMutableArray array],*corners=[NSMutableArray array];for(int y=0;y<4;y++)for(int x=0;x<4;x++)[matrix addObject:@(y==3?(x==3?1.:0.):(x==3?t.at<double>(y):R.at<double>(y,x)))];for(auto v:c)[corners addObject:@[@(v.x),@(v.y)]];
 return @{ @"id":@(ident),@"cameraFromPageRowMajor":matrix,@"corners":corners,@"reprojectionPixels":@(err),@"processMs":@(ms),@"depthMeters":@(t.at<double>(2))};
}

struct DotBlob{Point2f point;int color;float radius;};
struct DotCorner{int id,corner;std::vector<DotBlob> members;};
// Test chromatic dominance before the dark-neutral fallback: live green dots can have75<=hi<85.
static int classify(Vec3b c){float r=c[0],g=c[1],b=c[2],hi=std::max({r,g,b}),lo=std::min({r,g,b});if(hi>=75&&hi-lo>=hi*.32){if(r>g*1.35&&r>b*1.22)return 0;if(g>r*1.22&&g>b*1.12)return 1;if(b>r*1.25&&b>g*1.12)return 2;}if(hi<85)return 3;return -1;}
static std::vector<DotCorner> decodedDots(const Mat& rgb){
 std::vector<DotBlob> blobs;Mat classes(rgb.size(),CV_8SC1);for(int y=0;y<rgb.rows;y++){const auto* row=rgb.ptr<Vec3b>(y);auto* out=classes.ptr<signed char>(y);for(int x=0;x<rgb.cols;x++)out[x]=classify(row[x]);}
 // RETR_EXTERNAL loses black-dot islands enclosed by a dark monitor bezel.
 // CCOMP promotes every foreground component to the top level; exclude child holes.
 for(int col=0;col<4;col++){Mat mask=classes==col;std::vector<std::vector<cv::Point>> contours;std::vector<Vec4i> hierarchy;findContours(mask,contours,hierarchy,RETR_CCOMP,CHAIN_APPROX_SIMPLE);for(size_t ci=0;ci<contours.size();ci++){if(hierarchy[ci][3]>=0)continue;auto& c=contours[ci];double area=contourArea(c);cv::Rect b=boundingRect(c);if(area<9||area>20000||b.width>250||b.height>250||b.x<=0||b.y<=0||b.x+b.width>=rgb.cols-1||b.y+b.height>=rgb.rows-1||double(b.width)/b.height<.22||double(b.width)/b.height>4.5||area/b.area()<.38)continue;Moments m=moments(c);if(m.m00)blobs.push_back({Point2f(m.m10/m.m00,m.m01/m.m00),col,float(std::sqrt(area/CV_PI))});}}
 // Larger plausible round blobs first avoids tiny text dominating the bounded search.
 std::sort(blobs.begin(),blobs.end(),[](auto&a,auto&b){return a.radius>b.radius;});if(blobs.size()>180)blobs.resize(180);
 const int words[2][4][7]={{{1,3,1,2,0,1,3},{1,0,3,2,2,2,2},{2,1,3,3,0,1,3},{3,0,3,3,1,0,2}},{{2,3,3,1,2,0,0},{0,2,1,1,3,3,3},{3,3,2,2,1,0,1},{0,1,3,2,0,2,1}}};
 std::vector<DotCorner> out;for(size_t ci=0;ci<blobs.size();ci++){const auto c=blobs[ci];std::vector<std::pair<float,int>> near;for(size_t j=0;j<blobs.size();j++){float d=norm(blobs[j].point-c.point);if(j!=ci&&d>c.radius*1.45&&d<c.radius*10)near.push_back({d,int(j)});}std::sort(near.begin(),near.end());if(near.size()>10)near.resize(10);
  for(auto un:near)for(auto vn:near){if(un.second==vn.second)continue;Point2f u=blobs[un.second].point-c.point,v=blobs[vn.second].point-c.point;float lu=norm(u),lv=norm(v),cross=u.x*v.y-u.y*v.x,cos=u.dot(v)/(lu*lv);if(cross<=0||std::abs(cos)>.78||lu/lv<.25||lu/lv>4)continue;std::vector<int> indexes={int(ci)};std::vector<DotBlob> members={c};bool fail=false;
   for(auto axis:{u,v}){float len=norm(axis);for(int step=1;step<=3;step++){Point2f target=c.point+float(step)*axis;int best=-1;float dist=len*.36;for(size_t j=0;j<blobs.size();j++){if(std::find(indexes.begin(),indexes.end(),j)!=indexes.end())continue;float d=norm(blobs[j].point-target);if(d<dist){dist=d;best=int(j);}}if(best<0){fail=true;break;}indexes.push_back(best);members.push_back(blobs[best]);}if(fail)break;}
   if(fail||members.size()!=7)continue;for(int id=0;id<2;id++)for(int corner=0;corner<4;corner++){bool match=true;for(int k=0;k<7;k++)if(words[id][corner][k]!=members[k].color)match=false;if(match)out.push_back({id+7,corner,members});}
  }
 }return out;
}

@implementation MarkerVision
+ (NSArray<NSDictionary *> *)detect:(CVPixelBufferRef)b mode:(NSString*)mode fx:(double)fx fy:(double)fy cx:(double)cx cy:(double)cy extent:(double)extent {
 auto started=std::chrono::steady_clock::now();CVPixelBufferLockBaseAddress(b,kCVPixelBufferLock_ReadOnly);Mat rgb,gray;
 size_t w=CVPixelBufferGetWidth(b),h=CVPixelBufferGetHeight(b);
 if(CVPixelBufferIsPlanar(b)){
  Mat y((int)h,(int)w,CV_8UC1,CVPixelBufferGetBaseAddressOfPlane(b,0),CVPixelBufferGetBytesPerRowOfPlane(b,0));gray=y.clone();
  if([mode isEqualToString:@"dots"]){Mat uv((int)h/2,(int)w/2,CV_8UC2,CVPixelBufferGetBaseAddressOfPlane(b,1),CVPixelBufferGetBytesPerRowOfPlane(b,1));cvtColorTwoPlane(y,uv,rgb,COLOR_YUV2RGB_NV12);}
 }else{Mat bgra((int)h,(int)w,CV_8UC4,CVPixelBufferGetBaseAddress(b),CVPixelBufferGetBytesPerRow(b));cvtColor(bgra,gray,COLOR_BGRA2GRAY);if([mode isEqualToString:@"dots"])cvtColor(bgra,rgb,COLOR_BGRA2RGB);}
 CVPixelBufferUnlockBaseAddress(b,kCVPixelBufferLock_ReadOnly);
 static bool debugWritten=false;if(!debugWritten&&!rgb.empty()&&[[NSProcessInfo processInfo].arguments containsObject:@"--marker-native-debug"]){Mat bgr;cvtColor(rgb,bgr,COLOR_RGB2BGR);NSString* path=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/marker-native-debug-rgb.png"];imwrite(path.UTF8String,bgr);debugWritten=true;}
// Dense colored L codes lose their classified core below9px^2 at960px; keep optical detail without relaxing identity/component gates.
 double limit=[mode isEqualToString:@"dots"]?1920.:960.;double scale=std::min(1.,limit/std::max(w,h));if(scale<1){resize(gray,gray,cv::Size(),scale,scale,INTER_AREA);if(!rgb.empty())resize(rgb,rgb,cv::Size(),scale,scale,INTER_AREA);}Mat K=(Mat_<double>(3,3)<<fx*scale,0,cx*scale,0,fy*scale,cy*scale,0,0,1);NSMutableArray *result=[NSMutableArray array];std::vector<std::vector<Point2f>> corners;std::vector<int> ids;
 if([mode isEqualToString:@"aruco"]){aruco::DetectorParameters parameters;parameters.cornerRefinementMethod=aruco::CORNER_REFINE_SUBPIX;aruco::ArucoDetector detector(aruco::getPredefinedDictionary(aruco::DICT_4X4_50),parameters);detector.detectMarkers(gray,corners,ids);}
 if([mode isEqualToString:@"dots"]){auto decoded=decodedDots(rgb);const Point2f centers[4]={{0,0},{1,0},{1,1},{0,1}},us[4]={{1,0},{0,1},{-1,0},{0,-1}},vs[4]={{0,1},{-1,0},{0,-1},{1,0}};for(int id:{7,8}){std::vector<Point2f> image;std::vector<Point3f> metric;NSMutableArray *observedCenters=[NSMutableArray array],*observedCornerIDs=[NSMutableArray array];int observed=0;for(int corner=0;corner<4;corner++){auto found=std::find_if(decoded.begin(),decoded.end(),[&](const auto&d){return d.id==id&&d.corner==corner;});if(found==decoded.end())continue;observed++;[observedCenters addObject:@[@(found->members[0].point.x),@(found->members[0].point.y)]];[observedCornerIDs addObject:@(corner)];for(int k=0;k<7;k++){float du=k<4?k:0,dv=k>=4?k-3:0;Point2f m=float(extent)*centers[corner]+float(extent/15)*(du*us[corner]+dv*vs[corner]);metric.push_back({m.x-float(extent/2),m.y-float(extent/2),0});image.push_back(found->members[k].point);}}if(observed<3)continue;double ms=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-started).count();NSDictionary *p=poseResult(image,id,K,extent,ms,metric);if(p){NSMutableDictionary *q=[p mutableCopy];q[@"imagePoints"]=p[@"corners"];q[@"corners"]=observedCenters;q[@"observedCornerIDs"]=observedCornerIDs;q[@"decodedCorners"]=@(observed);q[@"observedDots"]=@(image.size());q[@"recoveryMode"]=observed==3?@"three-independently-decoded-corners":@"four-independently-decoded-corners";[result addObject:q];}}}
 double ms=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-started).count();for(size_t i=0;i<ids.size();i++){if(ids[i]!=7&&ids[i]!=8)continue; // Shared marker-contract IDs; unrelated dictionary codes must not replace the page.
 NSDictionary *p=poseResult(corners[i],ids[i],K,extent,ms);if(p)[result addObject:p];}NSMutableArray *full=[NSMutableArray array];for(NSDictionary *p in result){NSMutableDictionary *d=[p mutableCopy];NSMutableArray *cs=[NSMutableArray array];for(NSArray *v in p[@"corners"])[cs addObject:@[@([v[0] doubleValue]/scale),@([v[1] doubleValue]/scale)]];d[@"corners"]=cs;if(p[@"imagePoints"]){NSMutableArray *points=[NSMutableArray array];for(NSArray *v in p[@"imagePoints"])[points addObject:@[@([v[0] doubleValue]/scale),@([v[1] doubleValue]/scale)]];d[@"imagePoints"]=points;}d[@"reprojectionPixels"]=@([p[@"reprojectionPixels"] doubleValue]/scale);d[@"detectorScale"]=@(scale);[full addObject:d];}return full;
}
@end

#else
@implementation MarkerVision
+ (NSArray<NSDictionary *> *)detect:(CVPixelBufferRef)b mode:(NSString*)mode fx:(double)fx fy:(double)fy cx:(double)cx cy:(double)cy extent:(double)extent {return @[];}
@end
#endif
