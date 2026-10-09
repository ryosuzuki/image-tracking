#import <ARKit/ARKit.h>
#import <CoreVideo/CoreVideo.h>
#import <QuartzCore/QuartzCore.h>
#include <opencv2/imgproc.hpp>
extern "C" int ml_track_multi(const unsigned char*,int,int,const double*,int,const int*,int,double,double,const double*,const int*,int,float*);
// ARKit provider6.3.1 Includes~/UnityXRNativePtrs.h documented ABI; guard version before dereference.
struct NativeSessionV1 { int version;void* sessionPtr; };
extern "C" int ml_ios_current_frame(const void* ptr,int mode,const int* ids,int markers,double width,double height,const double* xy,const int* colors,int count,float* result,float* cameraWorld,double* metadata){
 @autoreleasepool {
  if(!ptr||!result||!cameraWorld||!metadata)return -10;const auto* native=(const NativeSessionV1*)ptr;if(native->version!=1||!native->sessionPtr)return -11;
  ARSession* session=(__bridge ARSession*)native->sessionPtr;ARFrame* frame=session.currentFrame;if(!frame||frame.camera.trackingState!=ARTrackingStateNormal)return -12;
  CVPixelBufferRef buffer=frame.capturedImage;if(!buffer)return -13;CVPixelBufferLockBaseAddress(buffer,kCVPixelBufferLock_ReadOnly);
  int status=-14;
  try {
   int w=(int)CVPixelBufferGetWidth(buffer),h=(int)CVPixelBufferGetHeight(buffer);cv::Mat rgba;
   if(CVPixelBufferGetPixelFormatType(buffer)==kCVPixelFormatType_420YpCbCr8BiPlanarFullRange||CVPixelBufferGetPixelFormatType(buffer)==kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange){
    cv::Mat y(h,w,CV_8UC1,CVPixelBufferGetBaseAddressOfPlane(buffer,0),CVPixelBufferGetBytesPerRowOfPlane(buffer,0));cv::Mat uv(h/2,w/2,CV_8UC2,CVPixelBufferGetBaseAddressOfPlane(buffer,1),CVPixelBufferGetBytesPerRowOfPlane(buffer,1));if(CVPixelBufferGetPixelFormatType(buffer)==kCVPixelFormatType_420YpCbCr8BiPlanarFullRange){
     rgba.create(h,w,CV_8UC4);auto matrix=CVBufferGetAttachment(buffer,kCVImageBufferYCbCrMatrixKey,nullptr);bool bt709=matrix&&CFEqual(matrix,kCVImageBufferYCbCrMatrix_ITU_R_709_2);
     float rv=bt709?1.5748f:1.402f,gu=bt709?.187324f:.344136f,gv=bt709?.468124f:.714136f,bu=bt709?1.8556f:1.772f;
     for(int row=0;row<h;row++){auto* luminance=y.ptr<unsigned char>(row);auto* chroma=uv.ptr<unsigned char>(row/2);auto* pixels=rgba.ptr<cv::Vec4b>(row);for(int col=0;col<w;col++){float yy=luminance[col],u=chroma[(col/2)*2]-128.f,v=chroma[(col/2)*2+1]-128.f;pixels[col]={cv::saturate_cast<unsigned char>(yy+rv*v),cv::saturate_cast<unsigned char>(yy-gu*u-gv*v),cv::saturate_cast<unsigned char>(yy+bu*u),255};}}
    }else cv::cvtColorTwoPlane(y,uv,rgba,cv::COLOR_YUV2RGBA_NV12);
   } else if(CVPixelBufferGetPixelFormatType(buffer)==kCVPixelFormatType_32BGRA){cv::Mat bgra(h,w,CV_8UC4,CVPixelBufferGetBaseAddress(buffer),CVPixelBufferGetBytesPerRow(buffer));cv::cvtColor(bgra,rgba,cv::COLOR_BGRA2RGBA);}
   if(!rgba.empty()){
    auto k=frame.camera.intrinsics;double calibration[]={k.columns[0][0],k.columns[1][1],k.columns[2][0],k.columns[2][1]};status=ml_track_multi(rgba.data,w,h,calibration,mode,ids,markers,width,height,xy,colors,count,result);
    auto t=frame.camera.transform;for(int c=0;c<4;c++)for(int r=0;r<4;r++)cameraWorld[c*4+r]=t.columns[c][r]*(r==2?-1:1)*(c==2?-1:1);
    metadata[7]=CACurrentMediaTime()-frame.timestamp;metadata[0]=frame.timestamp;metadata[1]=w;metadata[2]=h;for(int i=0;i<4;i++)metadata[3+i]=calibration[i];
   }
  }catch(...){status=-15;}
  CVPixelBufferUnlockBaseAddress(buffer,kCVPixelBufferLock_ReadOnly);return status;
 }
}
