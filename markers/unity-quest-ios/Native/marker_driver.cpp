#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>
#include <chrono>
#include <fstream>
#include <iostream>
#include <vector>
extern "C" int ml_track(const unsigned char*,int,int,const double*,int,int,double,double,const double*,const int*,int,float*);
int main(int argc,char** argv){if(argc<4)return 2;std::ifstream f(argv[2]);double width,height;int id,n;f>>width>>height>>id>>n;std::vector<double> xy(2*n);std::vector<int> color(n);for(int i=0;i<n;i++)f>>xy[2*i]>>xy[2*i+1]>>color[i];auto bgr=cv::imread(argv[1]);if(bgr.empty())return 3;cv::Mat rgba;cv::cvtColor(bgr,rgba,cv::COLOR_BGR2RGBA);double K[]={866.61,866.61,rgba.cols*.5,rgba.rows*.5};float output[34];int mode=std::stoi(argv[3]),rc=0,accepted=0;double ms=0;for(int i=0;i<10;i++){auto a=std::chrono::steady_clock::now();rc=ml_track(rgba.data,rgba.cols,rgba.rows,K,mode,id,width,height,xy.data(),color.data(),n,output);if(rc==1)accepted++;ms+=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-a).count();}std::cout<<"{\"iterations\":10,\"accepted\":"<<accepted<<",\"status\":"<<rc<<",\"id\":"<<(rc==1?output[0]:-1)<<",\"rms\":"<<(rc==1?output[1]:-1)<<",\"corners\":"<<(rc==1?output[26]:0)<<",\"observedDots\":"<<(rc==1?output[27]:0)<<",\"ms\":"<<ms/10<<",\"t\":["<<(rc==1?output[14]:0)<<","<<(rc==1?output[15]:0)<<","<<(rc==1?output[16]:0)<<"]}\n";return 0;}
