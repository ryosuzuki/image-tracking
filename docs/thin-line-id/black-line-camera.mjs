import {BlackEvidenceTracker} from './black-evidence-tracker.mjs?v=black-20261010-e';
import {BLACK_BCH126_OPTIONS} from './black-line-bch126-book.mjs?v=black-20261010-e';
import {inspectBlackLine} from './black-line-detector.mjs?v=black-20261010-e';
import {BLACK_ROBUST_OPTIONS} from './black-line-robust-book.mjs?v=black-20261010-e';
import {BLACK_LINE_BOOK} from './black-line-code.mjs?v=black-20261010-e';
const query=new URLSearchParams(location.search),temporalRequested=query.get('temporal')==='1',bookKind=query.get('book')||'robust30',readerOptions={...(bookKind==='126'?BLACK_BCH126_OPTIONS:bookKind==='870'?{book:BLACK_LINE_BOOK,minDistance:4,maxErasures:3}:BLACK_ROBUST_OPTIONS),lowMassFallback:query.get('lowMass')==='1',rankSkew:query.has('geometryRank')?Number(query.get('geometryRank')):0,...(query.has('orientationRatio')?{orientationRatio:Number(query.get('orientationRatio'))}:{})};document.querySelector('h1').textContent='Black L + black lines: '+readerOptions.book.length+' ID prototype';document.querySelector('h1+p').textContent=bookKind==='126'?'16 slots / 126 IDs / distance 6. Maximum 1 bit correction and 3 erasures. Existing 30 IDs unchanged. With no erasures, 2–4 bit flips cannot become another ID;5 or more can misdecode. Experimental capacity, not a device reliability guarantee. No temporal carry or held display. Normal camera 2D.':bookKind==='870'?'16 slots / 870 IDs / distance 4. One-bit correction, two-bit rejection without erasures. Three or more bit errors can misdecode. No temporal carry or held display. Normal camera 2D.':'16 slots / 30 IDs / distance 8. Maximum 1 bit correction and 3 erasures. With no erasures, 2–6 bit flips cannot become another ID. Green geometry even for unknown IDs. No temporal carry or held display. Normal camera 2D.';if(temporalRequested&&[30,126].includes(readerOptions.book.length))document.querySelector('h1+p').textContent=document.querySelector('h1+p').textContent.replace('No temporal carry or held display.','Exact temporal fusion enabled (within 800ms, no bit correction); no held display.');if(readerOptions.lowMassFallback)document.querySelector('h1+p').textContent+=' Missing-bit low-mass fallback enabled; current-frame supplemental reading only.';document.title=document.querySelector('h1').textContent;document.querySelector('a').href='black-line-targets.html?book='+bookKind;
const $=s=>document.querySelector(s),video=$('#video'),view=$('#view'),raw=document.createElement('canvas');
let running=false,stream=null,lastFrame=0,raf=null,recording=null,startGeneration=0;
let evidenceTracker=null,lastCamera=null,rawFrameTime=null,lastEvidenceTime=null;
const temporalEnabled=()=>temporalRequested&&[30,126].includes(readerOptions.book?.length);
function clearEvidence(){evidenceTracker?.reset();lastCamera=null;rawFrameTime=null;lastEvidenceTime=null;if(window.blackLineCamera)window.blackLineCamera.last=emptyState();}
function resetEvidence(){clearEvidence();if(raw.width&&raw.height){view.width=raw.width;view.height=raw.height;view.getContext('2d').drawImage(raw,0,0);}}
function trackFrame(observations,captureTimeMs){
 if(!temporalEnabled()||!Number.isFinite(captureTimeMs)){evidenceTracker?.reset();return [];}
 const source=video.srcObject,track=source?.getVideoTracks?.()[0]??null,device=track?.getSettings?.().deviceId??'';
 if(lastCamera&&(source!==lastCamera.source||track!==lastCamera.track||device!==lastCamera.device))evidenceTracker?.reset();
 lastCamera={source,track,device};
 const {book,...settings}=readerOptions,revision=JSON.stringify(settings);
 if(!evidenceTracker)evidenceTracker=new BlackEvidenceTracker({book,revision});
 else if(evidenceTracker.book!==book)evidenceTracker.setBook(book,{revision});
 return evidenceTracker.update(observations,captureTimeMs,{revision});
}
function emptyState(){return {time:video.currentTime,captureTimeMs:null,acquisitionTime:null,geometry:[],matches:[],tracks:[],temporal:[],lowMass:[],observations:[],temporalObservations:[],processingMs:0,detectorProcessingMs:0,temporalProcessingMs:0,held:0};}
function stop(){startGeneration++;running=false;clearEvidence();if(raf!==null)cancelAnimationFrame(raf);raf=null;stream?.getTracks().forEach(t=>t.stop());stream=null;video.srcObject=null;if(recording?.state==='recording')recording.stop();if(raw.width&&raw.height){view.width=raw.width;view.height=raw.height;view.getContext('2d').drawImage(raw,0,0);}if(window.blackLineCamera)window.blackLineCamera.last=emptyState();$('#status').textContent='Camera stopped';}
function drawLabel(c,q,id,note='',color='#20ff80'){const center=q.reduce((s,p)=>[s[0]+p[0]/4,s[1]+p[1]/4],[0,0]),short=Math.min(...q.map((p,i)=>Math.hypot(p[0]-q[(i+1)%4][0],p[1]-q[(i+1)%4][1]))),size=Math.max(12,Math.min(24,short*.12));c.save();c.fillStyle=color;c.textAlign='center';c.textBaseline='middle';c.font=`bold ${size}px sans-serif`;c.fillText(id,center[0],center[1]-(note?size*.45:0),short*.86);if(note){c.font=`bold ${Math.max(10,size*.8)}px sans-serif`;c.fillText(note,center[0],center[1]+size*.65,short*.86);}c.restore();}
// Timestamp ownership belongs to raw acquisition, never an analyze() argument.
// Manual calls while running acquire the current video; offline injected canvases
// have no authenticated video clock and cannot contribute temporal evidence.
function acquireRawFrame(){
 if(!running||video.readyState<2||!video.videoWidth){rawFrameTime=null;return false;}
 const acquired=video.currentTime*1000;
 raw.width=Math.min(video.videoWidth,1280);raw.height=Math.round(video.videoHeight*raw.width/video.videoWidth);
 raw.getContext('2d').drawImage(video,0,0,raw.width,raw.height);
 rawFrameTime=Number.isFinite(acquired)?acquired:null;return true;
}
function analyze(){
 if(running&&!acquireRawFrame()){clearEvidence();return [];}
 const captureTimeMs=running?rawFrameTime:null;
 if(!raw.width||!raw.height){clearEvidence();return [];}
 const detection=inspectBlackLine(raw,readerOptions),matches=detection.matches;
 const observations=detection.geometry.map(g=>({...g,...g.observation}));
 let temporalObservations=[],temporalProcessingMs=0;
 if(temporalEnabled()&&captureTimeMs!==null&&captureTimeMs!==lastEvidenceTime){
  lastEvidenceTime=captureTimeMs;const tick=performance.now();temporalObservations=trackFrame(observations.map(o=>({...o,fresh:true})),captureTimeMs);temporalProcessingMs=performance.now()-tick;
 }else if(!temporalEnabled()||captureTimeMs===null){evidenceTracker?.reset();lastEvidenceTime=null;}
 const lowMass=matches.filter(m=>m.lowMassFallbackUsed||detection.geometry.find(g=>g.q===m.q)?.observation?.lowMassFallbackUsed);
 const temporal=temporalObservations.filter(o=>o.temporalUsed&&!o.id).map(o=>({...o,id:o.temporalId,primaryId:o.id,samples:o.temporalSamples,ageMs:o.temporalAgeMs,known:o.temporalKnown,temporal:true}));
 view.width=raw.width;view.height=raw.height;const c=view.getContext('2d');c.drawImage(raw,0,0);
 for(const g of detection.geometry){
  c.strokeStyle='#20ff80';c.lineWidth=3;c.beginPath();g.q.forEach((p,i)=>i?c.lineTo(...p):c.moveTo(...p));c.closePath();c.stroke();
  const item=matches.find(m=>m.q===g.q),fused=temporal.find(m=>m.q===g.q);
  if(!g.id&&fused)drawLabel(c,g.q,fused.id,`時系列 ${fused.samples}枚 / ${Math.round(fused.ageMs)}ms`,'#409cff');
  else drawLabel(c,g.q,g.id??'ID不明',item?[lowMass.includes(item)?'補助読取':'',item.errors?`訂正 ${item.errors}bit`:'',item.erasures?`欠落 ${item.erasures}`:''].filter(Boolean).join(' / '):'');
 }
 const corrected=matches.filter(m=>m.errors>0).length,recovered=matches.filter(m=>m.erasures>0).length,processingMs=detection.processingMs+temporalProcessingMs;
 $('#status').textContent=`Geometry ${detection.geometry.length} / Fresh ${matches.length} / Corrected ${corrected} / Erasure-recovered ${recovered} / Low-mass ${lowMass.length} / Temporal ${temporal.length} / Held 0 / ${Math.round(processingMs)}ms — `+matches.map(m=>m.id).join(' / ');
 window.blackLineCamera.last={time:Number.isFinite(captureTimeMs)?captureTimeMs/1000:video.currentTime,captureTimeMs:Number.isFinite(captureTimeMs)?captureTimeMs:null,acquisitionTime:rawFrameTime,geometry:detection.geometry,matches:matches.map(m=>({id:m.id,q:m.q,errors:m.errors,erasures:m.erasures})),tracks:matches.map(m=>({...m,fresh:true})),temporal,lowMass:lowMass.map(m=>({...m,lowMassFallbackUsed:true})),observations,temporalObservations,processingMs,detectorProcessingMs:detection.processingMs,temporalProcessingMs,held:0};
 return matches;
}
function loop(t){
 if(!running)return;raf=requestAnimationFrame(loop);if(t-lastFrame<200||video.readyState<2||!video.videoWidth)return;lastFrame=t;
 try{analyze();}catch(e){stop();$('#status').textContent=e.name+': '+e.message;}
}
await window.cvReadyPromise;window.blackLineCamera={raw,analyze,inspect:canvas=>inspectBlackLine(canvas,readerOptions),book:readerOptions?.book||BLACK_LINE_BOOK,readerOptions,last:emptyState(),stop,resetEvidence,get temporalEnabled(){return temporalEnabled();},get running(){return running;}};video.addEventListener('loadedmetadata',resetEvidence);$('#start').disabled=false;$('#start').textContent='カメラ開始';$('#status').textContent='準備完了：白黒線プロトタイプ・実機性能未検証';
$('#start').onclick=async()=>{stop();const generation=startGeneration;try{const acquired=await navigator.mediaDevices.getUserMedia({video:{facingMode:{ideal:'environment'},width:{ideal:1280},height:{ideal:720}},audio:false});if(generation!==startGeneration){acquired.getTracks().forEach(t=>t.stop());return;}stream=acquired;video.srcObject=stream;await video.play();if(generation!==startGeneration)return;running=true;lastFrame=0;raf=requestAnimationFrame(loop);}catch(e){if(generation!==startGeneration)return;stop();$('#status').textContent=e.name+': '+e.message;}};
$('#stop').onclick=stop;$('#file').onchange=async e=>{const file=e.target.files[0];if(!file)return;stop();try{const image=await createImageBitmap(file);raw.width=image.width;raw.height=image.height;raw.getContext('2d').drawImage(image,0,0);image.close();analyze();}catch(e){$('#status').textContent=e.name+': '+e.message;}};
$('#record').onclick=()=>{if(!running||recording?.state==='recording')return;if(!window.MediaRecorder){$('#status').textContent='録画非対応';return;}const chunks=[];const capture=view.captureStream(10),rec=new MediaRecorder(capture);recording=rec;rec.ondataavailable=e=>{if(e.data.size)chunks.push(e.data);};rec.onstop=()=>{capture.getTracks().forEach(t=>t.stop());if(!chunks.length)return;const blob=new Blob(chunks,{type:rec.mimeType}),url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='black-line-camera.webm';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);};rec.start();const current=rec;setTimeout(()=>{if(current.state==='recording')current.stop();},10000);};
