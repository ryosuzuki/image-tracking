#include <jni.h>
#include <vector>
#include <algorithm>
extern "C" int ml_track_multi(const unsigned char*,int,int,const double*,int,const int*,int,double,double,const double*,const int*,int,float*);
static int clamp(double x){return std::max(0,std::min(255,int(x+.5)));}
extern "C" JNIEXPORT jbyteArray JNICALL Java_org_openclaw_questmarkerserviceprobe_MainActivity_rgbaFromYuv(JNIEnv* e,jclass,jobject y,jobject u,jobject v,jint w,jint h,jint yr,jint yp,jint ur,jint up,jint vr,jint vp,jint ds){
 auto Y=(unsigned char*)e->GetDirectBufferAddress(y),U=(unsigned char*)e->GetDirectBufferAddress(u),V=(unsigned char*)e->GetDirectBufferAddress(v);
 if(!Y||!U||!V)return nullptr;
 std::vector<unsigned char> out(w*h*4);bool limited=((ds>>27)&7)==2;bool bt709=((ds>>16)&63)==1;
 for(int j=0;j<h;j++)for(int i=0;i<w;i++){
  double a=Y[j*yr+i*yp],b=U[(j/2)*ur+(i/2)*up]-128.,c=V[(j/2)*vr+(i/2)*vp]-128.;
  if(limited){a=(a-16)*255./219.;b*=255./224.;c*=255./224.;}
  int p=(j*w+i)*4;out[p]=clamp(a+(bt709?1.5748:1.402)*c);out[p+1]=clamp(a-(bt709?.187324:.344136)*b-(bt709?.468124:.714136)*c);out[p+2]=clamp(a+(bt709?1.8556:1.772)*b);out[p+3]=255;
 }
 auto result=e->NewByteArray(out.size());e->SetByteArrayRegion(result,0,out.size(),(jbyte*)out.data());return result;
}
extern "C" JNIEXPORT jfloatArray JNICALL Java_org_openclaw_questmarkerserviceprobe_MainActivity_trackBoth(JNIEnv* e,jclass,jbyteArray rgba,jint w,jint h,jdoubleArray k,jdoubleArray xy,jintArray words,jdouble bw){
 auto data=e->GetByteArrayElements(rgba,nullptr);auto K=e->GetDoubleArrayElements(k,nullptr);auto X=e->GetDoubleArrayElements(xy,nullptr);auto W=e->GetIntArrayElements(words,nullptr);int ids[]={7,8};float output[70]{};double xs[56];for(int i=0;i<56;i++)xs[i]=X[i]*bw/.12;
 output[0]=ml_track_multi((unsigned char*)data,w,h,K,0,ids,2,bw,bw,xs,W,28,output+2);
 output[1]=ml_track_multi((unsigned char*)data,w,h,K,1,ids,2,bw,bw,xs,W,28,output+36);
 e->ReleaseByteArrayElements(rgba,data,JNI_ABORT);e->ReleaseDoubleArrayElements(k,K,JNI_ABORT);e->ReleaseDoubleArrayElements(xy,X,JNI_ABORT);e->ReleaseIntArrayElements(words,W,JNI_ABORT);
 auto result=e->NewFloatArray(70);e->SetFloatArrayRegion(result,0,70,output);return result;
}
