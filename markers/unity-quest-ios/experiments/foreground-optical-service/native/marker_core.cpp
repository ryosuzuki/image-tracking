#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/calib3d.hpp>
#include <opencv2/objdetect/aruco_detector.hpp>
#include <algorithm>
#include <cmath>
#include <vector>
struct Blob{cv::Point2f p;float radius;int color;};
// Independent implementation of the shared four-color seven-dot L contract.
static int classify(int r,int g,int b){int hi=std::max(r,std::max(g,b)),lo=std::min(r,std::min(g,b));if(hi>=40&&hi-lo>=hi*.06){if(r>g*1.20&&r>b*1.16)return 0;if(g>r*1.035&&g>b*1.015&&hi<130)return 1;if(b>r*1.15&&b>g*1.09)return 2;}if(hi>=55&&hi<=120&&g+3>=r&&g+3>=b)return 1;if(hi<55)return 3;return -1;}
static std::vector<Blob> blobs(const cv::Mat& rgba){
 // Detect complete silhouettes first; classifying individual dark pixels fragmented
 // real LCD dots under Quest camera white balance and lost their measured centers.
 cv::Mat gray,mask,labels,stats,centers;cv::cvtColor(rgba,gray,cv::COLOR_RGBA2GRAY);
 cv::adaptiveThreshold(gray,mask,255,cv::ADAPTIVE_THRESH_GAUSSIAN_C,cv::THRESH_BINARY_INV,31,12);
 int n=cv::connectedComponentsWithStats(mask,labels,stats,centers,4);std::vector<Blob> found;
 for(int i=1;i<n;i++){
  int area=stats.at<int>(i,cv::CC_STAT_AREA),w=stats.at<int>(i,cv::CC_STAT_WIDTH),h=stats.at<int>(i,cv::CC_STAT_HEIGHT),x=stats.at<int>(i,cv::CC_STAT_LEFT),y=stats.at<int>(i,cv::CC_STAT_TOP);
  if(area<6||area>=2500||w>=100||h>=100||w<3||h<3||x<=0||y<=0||x+w>=rgba.cols||y+h>=rgba.rows||double(w)/h<.35||double(w)/h>2.8||double(area)/(w*h)<.40)continue;
  cv::Point2f center(centers.at<double>(i,0),centers.at<double>(i,1));int rr=0,gg=0,bb=0,samples=0;float radius=std::sqrt(area/CV_PI);
  for(int py=y;py<y+h;py++)for(int px=x;px<x+w;px++){
   auto d=cv::Point2f(px,py)-center;if(d.dot(d)>radius*radius*.40f||labels.at<int>(py,px)!=i)continue;
   auto value=rgba.at<cv::Vec4b>(py,px);rr+=value[0];gg+=value[1];bb+=value[2];samples++;
  }
  if(!samples)continue;int color=classify(rr/samples,gg/samples,bb/samples);if(color<0)continue;
  found.push_back({center,radius,color});
 }
 if(found.size()>512)found.resize(512);return found;
}
struct Corner{int marker,corner;std::vector<int> members;};
struct Observation{int id;std::vector<cv::Point2f> image;std::vector<cv::Point3f> object;cv::Point2f corners[4];bool observed[4];int decoded=0,blobCount=0,cornerCandidates=0;};
static bool dotObservation(const cv::Mat& rgba,const int* ids,int markers,const double* xy,const int* words,int count,double width,double height,Observation& output){
 if(!xy||!words||count!=28||markers<1||markers>32)return false;auto bs=blobs(rgba);output.blobCount=bs.size();std::vector<Corner> matches;
 for(int i=0;i<(int)bs.size();i++){const auto& c=bs[i];std::vector<std::pair<float,int>> near;for(int j=0;j<(int)bs.size();j++)if(j!=i){auto d=bs[j].p-c.p;float squared=d.dot(d);if(squared>c.radius*c.radius*2.1&&squared<c.radius*c.radius*100)near.push_back({squared,j});}std::sort(near.begin(),near.end());if(near.size()>10)near.resize(10);
  for(auto u:near)for(auto v:near){if(u.second==v.second)continue;auto a=bs[u.second].p-c.p,b=bs[v.second].p-c.p;float la=std::sqrt(u.first),lb=std::sqrt(v.first);if(a.x*b.y-a.y*b.x<=0||std::abs(a.dot(b)/(la*lb))>.78||la/lb<.25||la/lb>4)continue;std::vector<int> members={i};bool valid=true;
   for(auto arm:{a,b})for(int k=1;k<=3;k++){auto target=c.p+arm*float(k);int best=-1;float error=arm.dot(arm)*.36f*.36f;for(int j=0;j<(int)bs.size();j++)if(std::find(members.begin(),members.end(),j)==members.end()){auto d=bs[j].p-target;float e=d.dot(d);if(e<error){best=j;error=e;}}if(best<0){valid=false;break;}members.push_back(best);}if(!valid||members.size()!=7)continue;
   for(int m=0;m<markers;m++)for(int corner=0;corner<4;corner++){bool equal=true;for(int k=0;k<7;k++)if(bs[members[k]].color!=words[m*28+corner*7+k]){equal=false;break;}if(equal)matches.push_back({m,corner,members});}
  }
 }
 output.cornerCandidates=matches.size();double bestError=1e30;bool found=false;
 for(int m=0;m<markers;m++){std::vector<const Corner*> chosen(4,nullptr);for(auto& corner:matches)if(corner.marker==m&&!chosen[corner.corner])chosen[corner.corner]=&corner;int decoded=0;for(auto* c:chosen)if(c)decoded++;if(decoded<3)continue;
  Observation obs;obs.id=ids[m];obs.decoded=decoded;obs.blobCount=bs.size();obs.cornerCandidates=matches.size();std::vector<cv::Point2f> metric;
  for(int corner=0;corner<4;corner++)if(chosen[corner])for(int k=0;k<7;k++){int p=corner*7+k;cv::Point2f q{float(xy[p*2]),float(xy[p*2+1])};metric.push_back(q);obs.object.push_back({q.x,q.y,0});obs.image.push_back(bs[chosen[corner]->members[k]].p);}
  auto H=cv::findHomography(metric,obs.image,0);if(H.empty())continue;std::vector<cv::Point2f> projected;cv::perspectiveTransform(metric,projected,H);double error=0;for(int i=0;i<(int)metric.size();i++){auto d=projected[i]-obs.image[i];error+=d.dot(d);}error=std::sqrt(error/metric.size());if(!std::isfinite(error)||error>3.5)continue;
  std::vector<cv::Point2f> corners={cv::Point2f(-width*.5,-height*.5),cv::Point2f(width*.5,-height*.5),cv::Point2f(width*.5,height*.5),cv::Point2f(-width*.5,height*.5)};cv::perspectiveTransform(corners,projected,H);
  for(int c=0;c<4;c++){obs.observed[c]=chosen[c]!=nullptr;obs.corners[c]=chosen[c]?bs[chosen[c]->members[0]].p:projected[c];}if(std::abs(cv::contourArea(projected))<900)continue;
  if(error<bestError){bestError=error;output=obs;found=true;}
 }
 return found;
}
extern "C" int ml_track_multi(const unsigned char* data,int width,int height,const double* calibration,int mode,const int* ids,int markers,double boardWidth,double boardHeight,const double* dotXY,const int* dotWords,int dotsPerMarker,float* output){
 try{
  if(!data||!calibration||!output||!ids||markers<1||width<16||height<16||boardWidth<=0||boardHeight<=0)return -1;
  cv::Mat rgba(height,width,CV_8UC4,const_cast<unsigned char*>(data));Observation obs;
  if(mode==0){cv::Mat gray;cv::cvtColor(rgba,gray,cv::COLOR_RGBA2GRAY);static cv::aruco::ArucoDetector detector(cv::aruco::getPredefinedDictionary(cv::aruco::DICT_4X4_50));std::vector<std::vector<cv::Point2f>> corners;std::vector<int> detected;detector.detectMarkers(gray,corners,detected);int index=-1;for(int i=0;i<(int)detected.size();i++)if(std::find(ids,ids+markers,detected[i])!=ids+markers){index=i;break;}if(index<0)return 0;obs.id=detected[index];obs.image=corners[index];float x=boardWidth*.5,y=boardHeight*.5;obs.object={{-x,-y,0},{x,-y,0},{x,y,0},{-x,y,0}};for(int i=0;i<4;i++){obs.corners[i]=obs.image[i];obs.observed[i]=true;}obs.decoded=4;
  }else if(!dotObservation(rgba,ids,markers,dotXY,dotWords,dotsPerMarker,boardWidth,boardHeight,obs)){output[32]=obs.blobCount;output[33]=obs.cornerCandidates;return 0;}
  cv::Mat K=(cv::Mat_<double>(3,3)<<calibration[0],0,calibration[2],0,calibration[1],calibration[3],0,0,1),rotation,translation;
  bool ok=cv::solvePnP(obs.object,obs.image,K,cv::Mat(),rotation,translation,false,cv::SOLVEPNP_IPPE);if(!ok||translation.at<double>(2)<=.03||translation.at<double>(2)>10)return 0;std::vector<cv::Point2f> projected;cv::projectPoints(obs.object,rotation,translation,K,cv::Mat(),projected);double error=0;for(int i=0;i<(int)projected.size();i++){auto d=projected[i]-obs.image[i];error+=d.dot(d);}error=std::sqrt(error/projected.size());if(!std::isfinite(error)||error>4)return 0;
  cv::Mat R;cv::Rodrigues(rotation,R);std::fill(output,output+34,0);output[0]=obs.id;output[1]=error;for(int c=0;c<3;c++)for(int r=0;r<3;r++)output[2+c*4+r]=R.at<double>(r,c);for(int r=0;r<3;r++)output[14+r]=translation.at<double>(r);output[17]=1;for(int i=0;i<4;i++){output[18+i*2]=obs.corners[i].x;output[19+i*2]=obs.corners[i].y;output[28+i]=obs.observed[i]?1:0;}output[26]=obs.decoded;output[27]=obs.object.size();output[32]=obs.blobCount;output[33]=obs.cornerCandidates;return 1;
 }catch(const cv::Exception&){return -2;}catch(...){return -3;}
}
extern "C" int ml_track(const unsigned char* data,int width,int height,const double* calibration,int mode,int id,double boardWidth,double boardHeight,const double* xy,const int* words,int count,float* output){return ml_track_multi(data,width,height,calibration,mode,&id,1,boardWidth,boardHeight,xy,words,count,output);}
