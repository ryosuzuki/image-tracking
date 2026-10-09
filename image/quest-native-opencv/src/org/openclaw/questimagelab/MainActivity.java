package org.openclaw.questimagelab;

import android.app.Activity;
import android.os.*;
import android.Manifest;
import android.content.pm.PackageManager;
import android.hardware.camera2.*;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.media.*;
import android.graphics.*;
import android.util.*;
import android.view.*;
import android.widget.*;
import java.io.*;
import java.net.*;
import java.nio.ByteBuffer;
import java.util.*;
import org.opencv.android.Utils;
import org.opencv.core.*;
import org.opencv.features2d.*;
import org.opencv.calib3d.Calib3d;
import org.opencv.imgproc.Imgproc;

/** Genuine on-device Camera2/ORB planar tracking. This is not a world-anchored XR app. */
public class MainActivity extends Activity {
    private static final String TAG="NativeImageLab";
    private HandlerThread worker; private Handler handler;
    private CameraDevice camera; private CameraCaptureSession session; private ImageReader reader;
    private ImageView imageView; private TextView label;
    private volatile byte[] latestJpeg=new byte[0];
    private volatile String state="starting", cameraInfo="", tracking="SEARCHING";
    private volatile int frames=0,inliers=0; private volatile double frameFps=0,processMs=0;
    private long startMs,lastProcessed,lastSeen; private int targetW,targetH;
    private ORB orb; private BFMatcher matcher; private Mat targetDesc; private MatOfKeyPoint targetKeys;
    private Mat lastH; private ServerSocket server; private volatile boolean alive=true;

    public void onCreate(Bundle b){super.onCreate(b);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);root.setBackgroundColor(Color.BLACK);
        label=new TextView(this);label.setTextColor(Color.WHITE);label.setTextSize(18);label.setPadding(12,8,12,8);
        imageView=new ImageView(this); imageView.setScaleType(ImageView.ScaleType.FIT_CENTER);
        root.addView(label);root.addView(imageView,new LinearLayout.LayoutParams(-1,0,1));setContentView(root);
        worker=new HandlerThread("camera-cv");worker.start();handler=new Handler(worker.getLooper());startMs=SystemClock.elapsedRealtime();
        try{System.loadLibrary("opencv_java4");initTarget();startServer();}catch(Throwable e){fail(e);return;}
        if(checkSelfPermission(Manifest.permission.CAMERA)!=PackageManager.PERMISSION_GRANTED){
            requestPermissions(new String[]{Manifest.permission.CAMERA,"horizonos.permission.HEADSET_CAMERA"},7);
        }else handler.post(()->openCamera());
    }
    public void onRequestPermissionsResult(int r,String[] p,int[] g){super.onRequestPermissionsResult(r,p,g);handler.post(()->openCamera());}
    private void initTarget() throws Exception{
        Bitmap bitmap=BitmapFactory.decodeStream(getAssets().open("target.png"));
        // Keep original target coordinates for overlays; scale target uniformly for matching.
        bitmap=Bitmap.createScaledBitmap(bitmap,800,(int)(800.0*bitmap.getHeight()/bitmap.getWidth()),true);
        targetW=bitmap.getWidth();targetH=bitmap.getHeight();Mat rgba=new Mat(),gray=new Mat();Utils.bitmapToMat(bitmap,rgba);Imgproc.cvtColor(rgba,gray,Imgproc.COLOR_RGBA2GRAY);
        orb=ORB.create(1600,1.2f,8,20,0,2,ORB.HARRIS_SCORE,31,12);matcher=BFMatcher.create(Core.NORM_HAMMING,false);
        targetKeys=new MatOfKeyPoint();targetDesc=new Mat();Mat mask=new Mat();orb.detectAndCompute(gray,mask,targetKeys,targetDesc);
        Log.i(TAG,"targetKeys="+targetKeys.rows()+" target="+targetW+"x"+targetH);rgba.release();gray.release();mask.release();bitmap.recycle();
    }
    private Integer vendorInt(Object v){if(v instanceof Number)return ((Number)v).intValue();if(v instanceof byte[]&&((byte[])v).length>0)return (int)((byte[])v)[0];if(v instanceof int[]&&((int[])v).length>0)return ((int[])v)[0];return null;}
    @SuppressWarnings("MissingPermission") private void openCamera(){try{
        CameraManager mgr=(CameraManager)getSystemService(CAMERA_SERVICE);String chosen=null;StringBuilder info=new StringBuilder();
        for(String id:mgr.getCameraIdList()){
            CameraCharacteristics c=mgr.getCameraCharacteristics(id); Integer source=null,position=null;
            for(CameraCharacteristics.Key<?> k:c.getKeys()){
                if(k.getName().equals("com.meta.extra_metadata.camera_source")) source=vendorInt(c.get((CameraCharacteristics.Key)k));
                if(k.getName().equals("com.meta.extra_metadata.position")) position=vendorInt(c.get((CameraCharacteristics.Key)k));
            }
            info.append(id+":source="+source+",position="+position+" ");
            if(source!=null&&source==0&&(chosen==null||(position!=null&&position==0))) chosen=id;
        }
        cameraInfo=info.toString();Log.i(TAG,"cameras "+cameraInfo);
        if(chosen==null)throw new Exception("No source=0 passthrough camera: "+cameraInfo);
        CameraCharacteristics c=mgr.getCameraCharacteristics(chosen);android.util.Size[] sizes=c.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP).getOutputSizes(ImageFormat.YUV_420_888);
        android.util.Size selected=sizes[0];for(android.util.Size z:sizes) if(z.getWidth()==1280&&z.getHeight()==960)selected=z;
        reader=ImageReader.newInstance(selected.getWidth(),selected.getHeight(),ImageFormat.YUV_420_888,3);
        reader.setOnImageAvailableListener(r->{Image im=r.acquireLatestImage();if(im==null)return;try{long now=SystemClock.elapsedRealtime();if(now-lastProcessed>=100){lastProcessed=now;process(im);}}catch(Throwable e){fail(e);}finally{im.close();}},handler);
        final String cameraId=chosen;
        mgr.openCamera(chosen,new CameraDevice.StateCallback(){
            public void onOpened(CameraDevice d){camera=d;state="camera "+cameraId+" open "+reader.getWidth()+"x"+reader.getHeight();Log.i(TAG,state);try{
                CaptureRequest.Builder b=d.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);b.addTarget(reader.getSurface());
                d.createCaptureSession(Arrays.asList(reader.getSurface()),new CameraCaptureSession.StateCallback(){
                    public void onConfigured(CameraCaptureSession s){session=s;try{s.setRepeatingRequest(b.build(),null,handler);}catch(Exception e){fail(e);}}
                    public void onConfigureFailed(CameraCaptureSession s){state="capture configuration failed";}
                },handler);
            }catch(Exception e){fail(e);}}
            public void onDisconnected(CameraDevice d){state="disconnected";d.close();}
            public void onError(CameraDevice d,int err){state="camera error "+err;Log.e(TAG,state);d.close();}
        },handler);
    }catch(Throwable e){fail(e);}}
    private byte[] plane(Image.Plane p,int w,int h){ByteBuffer b=p.getBuffer();byte[] a=new byte[w*h];int row=p.getRowStride(),pix=p.getPixelStride();for(int y=0;y<h;y++)for(int x=0;x<w;x++)a[y*w+x]=b.get(y*row+x*pix);return a;}
    private void process(Image im){long tick=SystemClock.elapsedRealtime();int w=im.getWidth(),h=im.getHeight();Image.Plane[] ps=im.getPlanes();byte[] y=plane(ps[0],w,h),u=plane(ps[1],w/2,h/2),v=plane(ps[2],w/2,h/2);byte[] nv=new byte[w*h*3/2];System.arraycopy(y,0,nv,0,y.length);for(int i=0;i<u.length;i++){nv[y.length+i*2]=v[i];nv[y.length+i*2+1]=u[i];}
        Mat grayFull=new Mat(h,w,CvType.CV_8UC1);grayFull.put(0,0,y);Mat gray=new Mat();Imgproc.resize(grayFull,gray,new org.opencv.core.Size(960,720));
        Mat desc=new Mat(),mask=new Mat();MatOfKeyPoint keys=new MatOfKeyPoint();orb.detectAndCompute(gray,mask,keys,desc);
        List<MatOfDMatch> matches=new ArrayList<>();int accepted=0;
        Mat candidate=null;inliers=0;
        if(!desc.empty()){
            matcher.knnMatch(targetDesc,desc,matches,2);List<org.opencv.core.Point> src=new ArrayList<>(),dst=new ArrayList<>();KeyPoint[] tk=targetKeys.toArray(),fk=keys.toArray();
            for(MatOfDMatch group:matches){DMatch[] m=group.toArray();if(m.length>=2&&m[0].distance<0.73*m[1].distance){src.add(tk[m[0].queryIdx].pt);dst.add(fk[m[0].trainIdx].pt);}}
            if(src.size()>=12){MatOfPoint2f from=new MatOfPoint2f(),to=new MatOfPoint2f();from.fromList(src);to.fromList(dst);Mat m=new Mat();candidate=Calib3d.findHomography(from,to,Calib3d.RANSAC,3.0,m,2000,0.995);inliers=Core.countNonZero(m);if(!candidate.empty()&&inliers>=10&&inliers>=src.size()*0.35&&validQuad(candidate)){accepted=1;}m.release();from.release();to.release();}
        }
        long now=SystemClock.elapsedRealtime();
        if(accepted==1){if(lastH!=null)lastH.release();lastH=candidate;candidate=null;lastSeen=now;tracking="TRACKED";}
        else if(lastH!=null&&now-lastSeen<650){tracking="BRIEF HOLD";}else{tracking="SEARCHING";}
        if(candidate!=null)candidate.release();
        Mat yuv=new Mat(h+h/2,w,CvType.CV_8UC1),rgba=new Mat();yuv.put(0,0,nv);Imgproc.cvtColor(yuv,rgba,Imgproc.COLOR_YUV2RGBA_NV21);Mat scaled=new Mat();Imgproc.resize(rgba,scaled,new org.opencv.core.Size(960,720));Bitmap bm=Bitmap.createBitmap(960,720,Bitmap.Config.ARGB_8888);Utils.matToBitmap(scaled,bm);
        Canvas canvas=new Canvas(bm);if(!tracking.equals("SEARCHING"))drawOverlay(canvas,lastH,tracking.equals("TRACKED"));
        Paint text=new Paint(3);text.setColor(Color.BLACK);canvas.drawRect(0,0,960,66,text);text.setColor(Color.WHITE);text.setTextSize(21);canvas.drawText("QUEST 3 • native Camera2 + OpenCV • "+tracking,16,28,text);canvas.drawText("Actual passthrough RGB | planar overlay, not world anchor | inliers "+inliers,16,55,text);
        ByteArrayOutputStream bytes=new ByteArrayOutputStream();bm.compress(Bitmap.CompressFormat.JPEG,85,bytes);latestJpeg=bytes.toByteArray();frames++;frameFps=frames*1000.0/(now-startMs);processMs=SystemClock.elapsedRealtime()-tick;
        if(frames%20==0)Log.i(TAG,"frames="+frames+" state="+tracking+" inliers="+inliers+" cvMs="+processMs+" fps="+frameFps);
        runOnUiThread(()->{imageView.setImageBitmap(bm);label.setText(state+" | "+tracking+" | frames="+frames+" | processing="+(int)processMs+"ms");});
        for(MatOfDMatch m:matches)m.release();grayFull.release();gray.release();desc.release();mask.release();keys.release();yuv.release();rgba.release();scaled.release();
    }
    private boolean validQuad(Mat m){MatOfPoint2f src=new MatOfPoint2f(new org.opencv.core.Point(0,0),new org.opencv.core.Point(targetW,0),new org.opencv.core.Point(targetW,targetH),new org.opencv.core.Point(0,targetH)),dst=new MatOfPoint2f();Core.perspectiveTransform(src,dst,m);org.opencv.core.Point[] q=dst.toArray();double area=0;for(int i=0;i<4;i++){org.opencv.core.Point p=q[i],n=q[(i+1)%4];if(!Double.isFinite(p.x)||!Double.isFinite(p.y)||p.x< -300||p.x>1260||p.y< -300||p.y>1020){src.release();dst.release();return false;}area+=p.x*n.y-n.x*p.y;}src.release();dst.release();return Math.abs(area)*.5>1500&&Math.abs(area)*.5<700000;}
    private void drawOverlay(Canvas c,Mat H,boolean confident){Paint p=new Paint(3);p.setColor(confident?Color.CYAN:0xFFFFC04D);p.setStrokeWidth(4);p.setStyle(Paint.Style.STROKE);
        // Draw the target outline and a live sine wave in target-local coordinates.
        List<org.opencv.core.Point> pts=new ArrayList<>();pts.add(new org.opencv.core.Point(0,0));pts.add(new org.opencv.core.Point(targetW,0));pts.add(new org.opencv.core.Point(targetW,targetH));pts.add(new org.opencv.core.Point(0,targetH));pts.add(new org.opencv.core.Point(0,0));
        MatOfPoint2f a=new MatOfPoint2f(),b=new MatOfPoint2f();a.fromList(pts);Core.perspectiveTransform(a,b,H);org.opencv.core.Point[] q=b.toArray();Path outline=new Path();outline.moveTo((float)q[0].x,(float)q[0].y);for(int i=1;i<q.length;i++)outline.lineTo((float)q[i].x,(float)q[i].y);c.drawPath(outline,p);a.release();b.release();
        pts.clear();double t=(SystemClock.elapsedRealtime()-startMs)/1000.0;for(int i=0;i<=100;i++){double x=targetW*(.12+.76*i/100.0);double z=targetH*(.50+.13*Math.sin(i*.12-t*2));pts.add(new org.opencv.core.Point(x,z));}
        a=new MatOfPoint2f();b=new MatOfPoint2f();a.fromList(pts);Core.perspectiveTransform(a,b,H);q=b.toArray();Path wave=new Path();wave.moveTo((float)q[0].x,(float)q[0].y);for(int i=1;i<q.length;i++)wave.lineTo((float)q[i].x,(float)q[i].y);p.setStrokeWidth(6);c.drawPath(wave,p);a.release();b.release();
    }
    private void startServer() throws Exception{server=new ServerSocket(8871,4,InetAddress.getByName("127.0.0.1"));new Thread(()->{while(alive){try{Socket s=server.accept();new Thread(()->serve(s)).start();}catch(Exception e){if(alive)Log.e(TAG,"server",e);}}},"diagnostic-http").start();}
    private void serve(Socket socket){try{socket.setSoTimeout(2000);BufferedReader in=new BufferedReader(new InputStreamReader(socket.getInputStream()));String req=in.readLine();String path=req==null?"":req.split(" ")[1];String type;byte[] body;
        if(path.startsWith("/frame.jpg")){type="image/jpeg";body=latestJpeg;}else{type="application/json";String s="{\"state\":\""+state.replace('"','\'')+"\",\"cameras\":\""+cameraInfo+"\",\"frames\":"+frames+",\"tracking\":\""+tracking+"\",\"inliers\":"+inliers+",\"processMs\":"+processMs+",\"fps\":"+frameFps+"}";body=s.getBytes("UTF-8");}
        OutputStream out=socket.getOutputStream();out.write(("HTTP/1.1 200 OK\r\nContent-Type: "+type+"\r\nContent-Length: "+body.length+"\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n").getBytes("UTF-8"));out.write(body);out.flush();socket.close();
    }catch(Exception e){try{socket.close();}catch(Exception ignored){}}}
    private void fail(Throwable e){state="ERROR "+e;Log.e(TAG,state,e);if(label!=null)runOnUiThread(()->label.setText(state));}
    protected void onDestroy(){alive=false;try{if(server!=null)server.close();}catch(Exception ignored){}if(session!=null)session.close();if(camera!=null)camera.close();if(reader!=null)reader.close();if(worker!=null)worker.quitSafely();super.onDestroy();}
}
