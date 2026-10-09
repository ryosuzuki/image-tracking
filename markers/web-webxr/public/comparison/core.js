export const devices=['iPhone','Quest'];
export const runtimes=['swift-arkit','unity','web-camera-overlay','webxr-raw-camera'];
export const names={'swift-arkit':'Swift / ARKit','unity':'Unity native','web-camera-overlay':'Web camera overlay','webxr-raw-camera':'Immersive WebXR + raw camera'};
const median=a=>quantile(a,.5);
const finite=a=>a.filter(x=>Number.isFinite(x)&&x>=0);
export function quantile(a,p){a=finite(a).sort((x,y)=>x-y);if(!a.length)return null;const n=(a.length-1)*p,i=Math.floor(n);return a[i]+(a[Math.min(i+1,a.length-1)]-a[i])*(n-i)}
export function normalize(input,mapping={}){
 if(!input||typeof input!=='object')throw Error('Expected a JSON object');
 const device=input.device||mapping.device,runtime=input.runtime||mapping.runtime;if(!devices.includes(device)||!runtimes.includes(runtime))throw Error('Choose an explicit iPhone/Quest and runtime mapping. No platform is inferred from screenshots.');
 if(device==='Quest'&&runtime==='swift-arkit')throw Error('Swift ARKit on Quest is not an executable platform combination.');
 const raw=Array.isArray(input.framesDetail)?input.framesDetail:Array.isArray(input.frames)?input.frames:null;
 if(!raw)throw Error('Per-frame records required. A status report or aggregate count cannot supply missing measurements.');
 const records=raw.map((f,i)=>{
  const tracker=f.tracker||input.tracker;if(!['dots','aruco'].includes(tracker))throw Error(`Frame ${i} requires explicit tracker dots/aruco`);
  if(typeof f.tracked!=='boolean'||!Number.isFinite(f.at))throw Error(`Frame ${i} requires finite at(ms) and boolean tracked`);
  const frameRuntime=f.runtime||runtime;if(!runtimes.includes(frameRuntime))throw Error(`Frame ${i} has unknown runtime`);if(device==='Quest'&&frameRuntime==='swift-arkit')throw Error(`Frame ${i}: ARKit Quest N/A`);return {...f,tracker,runtime:frameRuntime};
 });
 return {schema:'marker-comparison-v1',device,runtime,frames:records,conditions:input.conditions||[],events:input.events||[],actions:input.actions||[],evidence:input.evidence||{},provenance:input.provenance||'Unspecified; imported report is not independently verified here',mappingWasManual:!input.device||!input.runtime,sourceSha256:input.sourceSha256||null,importedAt:new Date().toISOString()};
}
export function summaries(dataset){return runtimes.flatMap(runtime=>['dots','aruco'].map(tracker=>{
 const frames=dataset.frames.filter(f=>f.tracker===tracker&&(f.runtime||dataset.runtime)===runtime);if(!frames.length)return null;
 const physical=frames.filter(f=>['real-getUserMedia','experimental-XRCamera','native-arkit-frame','native-quest-pca-frame'].includes(f.source));
 const synthetic=frames.filter(f=>f.source==='synthetic-fixture');
 const unknown=frames.length-physical.length-synthetic.length;
 // Synthetic detector data never silently enters the physical comparison.
 const used=physical,tracked=used.filter(f=>f.tracked),latency=finite(used.map(f=>f.detectMs)),knownIds=tracked.filter(f=>Number.isInteger(f.expectedId)),wrongIds=knownIds.filter(f=>f.id!==f.expectedId);
 const epochs=new Set(used.map(f=>f.epoch).filter(Number.isInteger));const relevantEvents=used.length?dataset.events.filter(e=>{if(e.source==='synthetic-fixture')return false;if(e.tracker||e.runtime)return (!e.tracker||e.tracker===tracker)&&(!e.runtime||e.runtime===runtime);if(!Number.isInteger(e.epoch)||!epochs.has(e.epoch))return false;const routes=new Set(dataset.frames.filter(f=>f.epoch===e.epoch&&['real-getUserMedia','experimental-XRCamera','native-arkit-frame','native-quest-pca-frame'].includes(f.source)).map(f=>`${f.runtime||dataset.runtime}:${f.tracker}`));return routes.size===1&&routes.has(`${runtime}:${tracker}`)}):[];const reacq=[];let lostAt=null,lostEpoch=null;for(const e of relevantEvents){if(e.type==='invalidated'){lostAt=null;lostEpoch=null}else if(e.type==='lost'){lostAt=e.at;lostEpoch=e.epoch}else if(e.type==='found'&&lostAt!==null&&e.epoch===lostEpoch&&e.at>=lostAt){reacq.push(e.at-lostAt);lostAt=null;lostEpoch=null}}
 const conditions=dataset.conditions.map((c,i)=>{
  const fs=used.filter(f=>f.at>=c.at&&f.at<(dataset.conditions[i+1]?.at??Infinity)),xy=fs.filter(f=>f.tracked&&Array.isArray(f.center)&&f.center.length===2&&f.center.every(Number.isFinite)).map(f=>f.center),avg=xy.length?xy.reduce((s,p)=>[s[0]+p[0]/xy.length,s[1]+p[1]/xy.length],[0,0]):null;
  return {label:c.label||'Unnamed condition',manuallyEntered:c.manuallyEntered??null,stationary:c.stationary===true,frames:fs.length,trackedFrames:fs.filter(f=>f.tracked).length,jitterPx:c.stationary===true&&xy.length>1?Math.sqrt(xy.reduce((s,p)=>s+(p[0]-avg[0])**2+(p[1]-avg[1])**2,0)/xy.length):null};
 });
 const frameIds=used.map(f=>{const id=f.videoMetadata?.presentedFrames??f.frameId;return id===undefined?undefined:`${f.videoMetadata?.cameraSessionId??f.sessionId??'undeclared-session'}:${id}`}).filter(x=>x!==undefined);
 const independentError=finite(used.map(f=>f.physicalRegistrationErrorMm));
 return {device:dataset.device,runtime,tracker,reportedPhysicalFrames:used.length,syntheticFrames:synthetic.length,unknownSourceFrames:unknown,trackedFrames:tracked.length,detectionFraction:used.length?tracked.length/used.length:null,medianMs:median(latency),p95Ms:quantile(latency,.95),wrongIds:knownIds.length?wrongIds.length:null,knownIdFrames:knownIds.length,medianReacquisitionMs:median(reacq),reacquisitions:reacq.length,distinctFrameIds:frameIds.length?new Set(frameIds).size:null,medianIndependentRegistrationErrorMm:median(independentError),conditions,provenance:dataset.provenance,evidence:dataset.evidence,mappingWasManual:dataset.mappingWasManual,label:used.length?'Reported real camera records — not independently audited by this viewer':synthetic.length?'Synthetic-only records — no physical comparison':'No recognized real-camera provenance — unknown'};
 }).filter(Boolean))}
