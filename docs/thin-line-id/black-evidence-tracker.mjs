import {BLACK_ROBUST_BOOK} from './black-line-robust-book.mjs?v=black-20261010-f';

// Standalone experiment: caller supplies ONLY this frame's detector geometry and
// uncorrected, orientation-normalized bits, never display/held tracks. A detector
// ID is only a consistency check; corrected bits/IDs are not historical evidence.
// If the current paper belongs to the book and has <=1 erroneous known bit,
// n-d+2 current known bits exclude every other word, including a swapped old ID.
// Arbitrarily many classification errors have no such guarantee.
export class BlackEvidenceTracker {
 constructor({book=BLACK_ROBUST_BOOK,revision=0,windowMs=800,maxDistanceRatio=.12,maxSizeRatio=1.2}={}){
  if(!Number.isFinite(windowMs)||windowMs<=0||windowMs>800)throw new RangeError('windowMs must be in (0, 800]');
  if(!Number.isFinite(maxDistanceRatio)||maxDistanceRatio<=0||maxDistanceRatio>.2)throw new RangeError('maxDistanceRatio must be in (0, .2]');
  if(!Number.isFinite(maxSizeRatio)||maxSizeRatio<1||maxSizeRatio>1.5)throw new RangeError('maxSizeRatio must be in [1, 1.5]');
  if(!validRevision(revision))throw new TypeError('revision must be a string or finite number');
  Object.assign(this,{book,revision,windowMs,maxDistanceRatio,maxSizeRatio});
  this.tracks=[];this.lastTime=-Infinity;this._syncBook();
 }
 reset(){this.tracks=[];this.lastTime=-Infinity;}
 setBook(book,{revision=this.revision}={}){this.reset();if(!validRevision(revision))throw new TypeError('revision must be a string or finite number');this.book=book;this.revision=revision;this._syncBook();}
 _syncBook(){
  let signature;try{signature=JSON.stringify(this.book);}catch(error){this.reset();throw error;}
  if(signature===this._signature)return;
  this.reset();const words=validateBook(this.book);
  let d=16;for(let i=0;i<words.length;i++)for(let j=i+1;j<words.length;j++)d=Math.min(d,words[i].bits.reduce((n,b,k)=>n+(b!==words[j].bits[k]),0));
  if(d<3)throw new RangeError('A minimum distance >=3 is required for the one-error current-evidence guard');
  this._words=words;this.minimumDistance=d;this.minimumCurrent=16-d+2;this._signature=signature;
 }
 update(observations,now,{sceneChanged=false,revision=this.revision}={}){
  if(!Number.isFinite(now)){this.reset();throw new TypeError('now must be finite milliseconds');}
  if(!Array.isArray(observations)){this.reset();throw new TypeError('observations must be an array of fresh detector observations');}
  if(!validRevision(revision)){this.reset();throw new TypeError('revision must be a string or finite number');}
  this._syncBook();
  if(sceneChanged||now<=this.lastTime||revision!==this._activeRevision)this.reset();
  this.revision=revision;this._activeRevision=revision;this.lastTime=now;
  const prior=this.tracks.filter(t=>now-t.last<=this.windowMs),shapes=observations.map(o=>shape(o?.q));
  // Both degrees must be exactly one. Duplicate/nearby detections are ambiguity,
  // not nearest-neighbour tie breakers or independent votes for one old paper.
  const candidates=shapes.map(s=>s?prior.filter(t=>associated(s,t.shape,this)):[]),degrees=new Map();
  for(const list of candidates)for(const track of list)degrees.set(track,(degrees.get(track)||0)+1);
  const next=[];
  const result=observations.map((o,index)=>{
   const out={...o,temporalId:null,temporalUsed:false,temporalSamples:0,temporalKnown:0,temporalAgeMs:0},s=shapes[index];
   if(!s||!o||o.held||o.fresh===false||o.conflict||!validBits(o.bits)||o.bits.every(b=>b===null))return out;
   const old=candidates[index].length===1&&degrees.get(candidates[index][0])===1?candidates[index][0]:null;
   let samples=old?old.samples.filter(sample=>now-sample.time<=this.windowMs):[];
   if(samples.some(sample=>o.bits.some((b,k)=>b!==null&&sample.bits[k]!==null&&b!==sample.bits[k]))||(o.id&&old?.id&&o.id!==old.id))samples=[];
   // Bound memory even at unrealistically high call rates; dropping evidence is
   // conservative. Non-increasing timestamps cannot replay the same frame.
   samples=[...samples,{time:now,bits:o.bits.slice()}].slice(-32);
   const combined=Array.from({length:16},(_,k)=>samples.findLast(sample=>sample.bits[k]!==null)?.bits[k]??null),known=o.bits.filter(b=>b!==null).length;
   const matches=this._words.filter(word=>combined.every((b,k)=>b===null||b===word.bits[k]));
   // Match the fresh reader's <=3-erasure budget, with exactly ZERO bit errors.
   // Weak current evidence may be retained, but can never keep an old ID alive.
   const combinedKnown=combined.filter(b=>b!==null).length,id=matches.length===1&&combinedKnown>=13?matches[0].id:null;
   if(o.id&&id&&o.id!==id)return out;
   next.push({shape:s,last:now,samples,id});
   out.temporalKnown=combinedKnown;out.temporalSamples=samples.length;out.temporalAgeMs=now-samples[0].time;
   out.temporalId=known>=this.minimumCurrent?id:null;
   // A fresh/exact current ID is not a temporal recovery, even if history adds
   // redundant bits. Keep instrumentation honest about genuinely rescued IDs.
   out.temporalUsed=!!out.temporalId&&!o.id&&known<13&&combinedKnown>known;
   return out;
  });
  // TTL is not permission to hold unseen geometry through a missing/blank frame.
  this.tracks=next;return result;
 }
}
export default BlackEvidenceTracker;
function validBits(bits){return Array.isArray(bits)&&bits.length===16&&Array.from(bits).every(b=>b===null||b===0||b===1);}
function validRevision(revision){return typeof revision==='string'||Number.isFinite(revision);}
function validateBook(book){
 if(!Array.isArray(book)||book.length<2)throw new TypeError('book must contain at least two distinct 16-bit words');
 const ids=new Set();return book.map(word=>{
  if(typeof word?.id!=='string'||!word.id||ids.has(word.id)||!validBits(word.bits)||word.bits.some(b=>b===null)||!word.bits.includes(0)||!word.bits.includes(1))throw new TypeError('book needs unique IDs and nonconstant, complete binary words');
  ids.add(word.id);return {id:word.id,bits:word.bits.slice()};
 });
}
function shape(q){
 if(!Array.isArray(q)||q.length!==4||Array.from(q).some(p=>!Array.isArray(p)||p.length!==2||Array.from(p).some(v=>!Number.isFinite(v))))return null;
 const center=[0,1].map(k=>q.reduce((s,p)=>s+p[k]/4,0)),points=q.map(p=>p.slice()).sort((a,b)=>Math.atan2(a[1]-center[1],a[0]-center[0])-Math.atan2(b[1]-center[1],b[0]-center[0]));
 const lengths=points.map((p,i)=>Math.hypot(p[0]-points[(i+1)%4][0],p[1]-points[(i+1)%4][1])),scale=Math.min(...lengths);
 const cross=points.map((p,i)=>{const b=points[(i+1)%4],c=points[(i+2)%4];return (b[0]-p[0])*(c[1]-b[1])-(b[1]-p[1])*(c[0]-b[0]);});
 if(scale<=0||!cross.every(x=>x>0)&&!cross.every(x=>x<0))return null;
 const area=Math.abs(points.reduce((s,p,i)=>s+p[0]*points[(i+1)%4][1]-p[1]*points[(i+1)%4][0],0))/2;
 return area>0?{center,points,scale,area}:null;
}
function associated(a,b,{maxDistanceRatio,maxSizeRatio}){
 if(Math.max(a.area,b.area)/Math.min(a.area,b.area)>maxSizeRatio**2||Math.max(a.scale,b.scale)/Math.min(a.scale,b.scale)>maxSizeRatio)return false;
 const limit=Math.min(a.scale,b.scale)*maxDistanceRatio;
 return Math.hypot(a.center[0]-b.center[0],a.center[1]-b.center[1])<=limit&&a.points.every((p,i)=>Math.hypot(p[0]-b.points[i][0],p[1]-b.points[i][1])<=limit);
}
