import {selectCubicFallbackCandidates,mergeCubicFallback,readCubicFallback} from './cubic-fallback.mjs?v=iter-20261010-g';
import {detectLCorners,detectLCornersConsensus} from './l-corners.mjs?v=iter-20261010-g';
import {observeRectified,decodeObserved,READER_OPTIONS} from './color-code.mjs?v=iter-20261010-g';
// Allocate transform copies: Embind Mat.clone() aliases the same native Mat.
export const GEOMETRY_OPTIONS={strips:true,consensus:false,rankSkew:0};
let fallbackFrame=0;
export function inspect(canvas){
 const started=performance.now(),src=cv.imread(canvas),gray=new cv.Mat(),matches=[],geometry=[],observations=[];
 try{cv.cvtColor(src,gray,cv.COLOR_RGBA2GRAY);
  for(let raw of (GEOMETRY_OPTIONS.consensus?detectLCornersConsensus(gray):detectLCorners(gray,GEOMETRY_OPTIONS))){
   const center=raw.reduce((s,p)=>[s[0]+p[0]/4,s[1]+p[1]/4],[0,0]);
   const ordered=raw.slice().sort((a,b)=>Math.atan2(a[1]-center[1],a[0]-center[0])-Math.atan2(b[1]-center[1],b[0]-center[0]));
   let observation=null,q=ordered;
   orientations:for(const rev of [ordered,[...ordered].reverse()])for(let shift=0;shift<4;shift++){
    const candidate=[...rev.slice(shift),...rev.slice(0,shift)],a=cv.matFromArray(4,1,cv.CV_32FC2,candidate.flat()),b=cv.matFromArray(4,1,cv.CV_32FC2,[35,35,605,35,605,845,35,845]),H=cv.getPerspectiveTransform(a,b),dst=new cv.Mat(),crop=document.createElement('canvas');
    try{if(GEOMETRY_OPTIONS.strips){crop.width=640;crop.height=880;const ctx=crop.getContext('2d'),tile=document.createElement('canvas');ctx.fillStyle='white';ctx.fillRect(0,0,640,880);cv.warpPerspective(src,dst,H,new cv.Size(640,100));cv.imshow(tile,dst);ctx.drawImage(tile,0,0);const shifted=cv.matFromArray(3,3,cv.CV_64F,Array.from(H.data64F));try{const data=shifted.data64F;for(let i=0;i<3;i++)data[3+i]-=780*data[6+i];cv.warpPerspective(src,dst,shifted,new cv.Size(640,100));cv.imshow(tile,dst);ctx.drawImage(tile,0,780);}finally{shifted.delete();}if(READER_OPTIONS.useSides){cv.warpPerspective(src,dst,H,new cv.Size(100,880));tile.width=100;tile.height=880;cv.imshow(tile,dst);ctx.drawImage(tile,0,0);const right=cv.matFromArray(3,3,cv.CV_64F,Array.from(H.data64F));try{const data=right.data64F;for(let i=0;i<3;i++)data[i]-=530*data[6+i];cv.warpPerspective(src,dst,right,new cv.Size(110,880));tile.width=110;tile.height=880;cv.imshow(tile,dst);ctx.drawImage(tile,530,0);}finally{right.delete();}}}else{cv.warpPerspective(src,dst,H,new cv.Size(640,880));cv.imshow(crop,dst);}const observed=observeRectified(crop);if(observed){observation=observed;q=candidate;break orientations;}}
    finally{[a,b,H,dst].forEach(m=>m.delete());}
   }
   const item=observation&&!observation.conflict?decodeObserved(observation.symbols):null;
   const g={q,id:item?.id||null};geometry.push(g);
   if(observation)observations.push({...g,...observation});
   if(item)matches.push({...item,...observation,q,erasures:observation.symbols.filter(x=>x===null).length});
  }
  let fallbackMetrics={};
  if(READER_OPTIONS.useCubicFallback){
   let fallbackAttempt=0,fallbackUsed=0,fallbackErrors=0;
   for(const observation of observations)Object.assign(observation,{fallbackAttempt:false,fallbackUsed:false});
   for(const match of matches)Object.assign(match,{fallbackAttempt:false,fallbackUsed:false});
   for(const observation of selectCubicFallbackCandidates(observations,fallbackFrame++)){
    observation.fallbackAttempt=true;fallbackAttempt++;
    let cubic;try{cubic=readCubicFallback(src,observation.q);}catch{fallbackErrors++;continue;}
    const merged=mergeCubicFallback(observation,cubic);if(!merged)continue;
    Object.assign(observation,merged);fallbackUsed++;
    const g=geometry.find(g=>g.q===observation.q);if(g)g.id=observation.id;
    const item=decodeObserved(observation.symbols);
    matches.push({...item,...observation,erasures:observation.symbols.filter(x=>x===null).length});
   }
   fallbackMetrics={fallbackAttempt,fallbackUsed,fallbackErrors};
  }
  return {matches,geometry,observations,...fallbackMetrics,processingMs:performance.now()-started};
 }finally{src.delete();gray.delete();}
}
export function recognize(canvas){return inspect(canvas).matches;}
