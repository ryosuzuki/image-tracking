import {detectLCorners} from './l-corners.mjs?v=l3';
import {ColoredDotsTracker} from './colored-dots.mjs';
const contract=await(await fetch('./contract.json')).json(),dots=new ColoredDotsTracker(contract);
const video=document.querySelector('#video'),view=document.querySelector('#view'),ctx=view.getContext('2d'),status=document.querySelector('#status'),start=document.querySelector('#start');let stream,running=false,last=0,starting=false,session=0;
export function detectFrame(canvas,mode='l'){const rgba=cv.imread(canvas),gray=new cv.Mat(),white=new cv.Mat(),cs=new cv.MatVector(),hier=new cv.Mat(),kernel=cv.Mat.ones(5,5,cv.CV_8U);cv.cvtColor(rgba,gray,cv.COLOR_RGBA2GRAY);if(mode==='l'){const quads=detectLCorners(gray);for(const m of [rgba,gray,white,cs,hier,kernel])m.delete();return quads}cv.threshold(gray,white,125,255,cv.THRESH_BINARY);cv.morphologyEx(white,white,cv.MORPH_CLOSE,kernel);cv.findContours(white,cs,hier,cv.RETR_EXTERNAL,cv.CHAIN_APPROX_SIMPLE);const quads=[];for(let i=0;i<cs.size();i++){const c=cs.get(i),a=cv.contourArea(c);if(a>1500&&a<500000){const b=cv.boundingRect(c),x=Math.max(0,b.x-2),y=Math.max(0,b.y-2),w=Math.min(canvas.width-x,b.width+4),h=Math.min(canvas.height-y,b.height+4),image=canvas.getContext('2d').getImageData(x,y,w,h);for(const o of dots.detect(image))quads.push(o.corners.map(p=>[p.x+x,p.y+y]))}c.delete()}for(const m of [rgba,gray,white,cs,hier,kernel])m.delete();return quads}
window.detectTestCanvas=detectFrame;
await window.cvReadyPromise;start.disabled=false;start.textContent='Start rear camera';status.textContent='Ready. Tap Start rear camera.';
start.onclick=async()=>{
 if(starting||running)return;
 const token=++session;starting=true;start.disabled=true;
 let acquired;
 try{
  acquired=await navigator.mediaDevices.getUserMedia({video:{facingMode:{ideal:'environment'},width:{ideal:1280},height:{ideal:720}},audio:false});
  if(token!==session){acquired.getTracks().forEach(t=>t.stop());return}
  stream=acquired;video.srcObject=stream;
  await video.play();
  if(token!==session)return;
  running=true;requestAnimationFrame(loop);status.textContent='Camera active';
 }catch(e){
  acquired?.getTracks().forEach(t=>t.stop());
  if(token!==session)return;
  video.srcObject=null;stream=null;
  status.textContent=e.name==='NotAllowedError'?'Camera permission denied. Allow camera access in the browser.':`Camera start failed: ${e.name}: ${e.message}. Tap Start to retry.`;
 }finally{if(token===session){starting=false;start.disabled=running}}
};
document.querySelector('#stop').onclick=()=>{++session;running=false;starting=false;stream?.getTracks().forEach(t=>t.stop());stream=null;video.pause();video.srcObject=null;start.disabled=false;status.textContent='Camera stopped'};
function loop(t){if(!running)return;requestAnimationFrame(loop);if(t-last<120||!video.videoWidth)return;last=t;view.width=Math.min(960,video.videoWidth);view.height=Math.round(video.videoHeight*view.width/video.videoWidth);ctx.drawImage(video,0,0,view.width,view.height);const before=performance.now();let qs;try{qs=detectFrame(view,document.querySelector('#mode').value)}catch(e){status.textContent=`Detector error: ${e.message}`;return}ctx.strokeStyle='#1f6';ctx.lineWidth=3;for(const q of qs){ctx.beginPath();q.forEach((p,i)=>i?ctx.lineTo(...p):ctx.moveTo(...p));ctx.closePath();ctx.stroke();q.forEach(p=>{ctx.beginPath();ctx.arc(...p,4,0,Math.PI*2);ctx.stroke()})}status.textContent=`${qs.length} paper regions | ${view.width}×${view.height} processing | ${Math.round(performance.now()-before)} ms | ${document.querySelector('#mode').value}`}
