import { CODEBOOK, CODEBOOK_REVISION, decodeObserved } from './color-code.mjs?v=iter-20261010-j';

// Inputs must be fresh detector observations, never held/display tracks. Geometry
// alone cannot prove identity: blank frames and contradictory colors break history.
export class EvidenceTracker {
 constructor({windowMs=800,maxDistanceRatio=.12,maxSizeRatio=1.2}={}) {
  if(!Number.isFinite(windowMs)||windowMs<=0||windowMs>2500)throw new RangeError('windowMs must be in (0, 2500]');
  if(!Number.isFinite(maxDistanceRatio)||maxDistanceRatio<=0||maxDistanceRatio>.2)throw new RangeError('maxDistanceRatio must be in (0, .2]');
  if(!Number.isFinite(maxSizeRatio)||maxSizeRatio<1||maxSizeRatio>1.5)throw new RangeError('maxSizeRatio must be in [1, 1.5]');
  Object.assign(this,{windowMs,maxDistanceRatio,maxSizeRatio});this.tracks=[];this.lastTime=-Infinity;this.book=CODEBOOK_REVISION;
 }
 reset(){this.tracks=[];this.lastTime=-Infinity;this.book=CODEBOOK_REVISION;}
 update(observations,now,{sceneChanged=false}={}){
  if(!Number.isFinite(now))throw new TypeError('now must be finite milliseconds');
  if(sceneChanged||now<this.lastTime||this.book!==CODEBOOK_REVISION)this.reset();this.lastTime=now;
  const count=CODEBOOK[0].symbols.length;// Current evidence must distinguish this dictionary even after a position swap.
  let minimumDistance=count;for(let i=0;i<CODEBOOK.length;i++)for(let j=i+1;j<CODEBOOK.length;j++){let d=0;for(let k=0;k<count;k++)d+=CODEBOOK[i].symbols[k]!==CODEBOOK[j].symbols[k];minimumDistance=Math.min(minimumDistance,d);}const minimumCurrent=count-minimumDistance+1;
  const prior=this.tracks.filter(t=>now-t.last<=this.windowMs);
  const shapes=observations.map(o=>shape(o.q));
  const candidates=shapes.map(s=>s?prior.filter(t=>associated(s,t.shape,this)):[]);
  const useCount=new Map();for(const c of candidates)if(c.length===1)useCount.set(c[0],(useCount.get(c[0])||0)+1);
  const next=[];
  const result=observations.map((o,index)=>{
   const output={...o,temporalId:null};const s=shapes[index];
   if(!s||o.conflict||!Array.isArray(o.symbols)||o.symbols.length!==CODEBOOK[0].symbols.length||Array.from(o.symbols).some(x=>x!==null&&(!Number.isInteger(x)||x<0||x>3))||o.symbols.every(x=>x===null))return output;
   let old=candidates[index].length===1&&useCount.get(candidates[index][0])===1?candidates[index][0]:null;
   let samples=old?old.samples.filter(sample=>now-sample.time<=this.windowMs):[];
   const disagrees=samples.some(sample=>o.symbols.some((x,i)=>x!==null&&sample.symbols[i]!==null&&x!==sample.symbols[i]));
   if(disagrees||(o.id&&old?.id&&o.id!==old.id))samples=[];
   samples=[...samples,{time:now,symbols:o.symbols.slice()}];
   const combined=Array.from({length:CODEBOOK[0].symbols.length},(_,i)=>samples.findLast(sample=>sample.symbols[i]!==null)?.symbols[i]??null);
   const matches=CODEBOOK.filter(c=>combined.every((x,i)=>x===null||x===c.symbols[i]));
   const decoded=decodeObserved(combined);
   const id=matches.length===1&&decoded?.id===matches[0].id?decoded.id:null;
   // A supplied detector ID is a consistency check, not extra color evidence.
   if(o.id&&id&&o.id!==id)return output;
   next.push({shape:s,last:now,samples,id});output.temporalId=o.symbols.filter(x=>x!==null).length>=minimumCurrent?id:null;return output;
  });
  // No held geometry or colors survive a frame without a fresh observation.
  this.tracks=next;return result;
 }
}
export default EvidenceTracker;
function shape(q){
 if(!Array.isArray(q)||q.length!==4||q.some(p=>!Array.isArray(p)||p.length!==2||p.some(v=>!Number.isFinite(v))))return null;
 const center=[0,1].map(k=>q.reduce((sum,p)=>sum+p[k]/4,0));
 const points=q.map(p=>p.slice()).sort((a,b)=>Math.atan2(a[1]-center[1],a[0]-center[0])-Math.atan2(b[1]-center[1],b[0]-center[0]));
 const lengths=points.map((p,i)=>Math.hypot(p[0]-points[(i+1)%4][0],p[1]-points[(i+1)%4][1]));
 const scale=Math.min(...lengths);if(scale<=0)return null;
 const area=Math.abs(points.reduce((sum,p,i)=>sum+p[0]*points[(i+1)%4][1]-p[1]*points[(i+1)%4][0],0))/2;
 return area>0?{center,points,scale,area}:null;
}
function associated(a,b,{maxDistanceRatio,maxSizeRatio}){
 if(Math.max(a.area,b.area)/Math.min(a.area,b.area)>maxSizeRatio**2||Math.max(a.scale,b.scale)/Math.min(a.scale,b.scale)>maxSizeRatio)return false;
 const limit=Math.min(a.scale,b.scale)*maxDistanceRatio;
 return Math.hypot(a.center[0]-b.center[0],a.center[1]-b.center[1])<=limit&&a.points.every((p,i)=>Math.hypot(p[0]-b.points[i][0],p[1]-b.points[i][1])<=limit);
}
