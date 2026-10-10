import {CODEBOOK,decodeObserved,observeRectified,stripeLayout,READER_OPTIONS} from './color-code.mjs?v=iter-20261010-i';

// A unique existing-color agreement is an ambiguity guard, never guessed ink.
// The original dictionary has distance3; merely one-or-more candidates is unsafe.
export function eligibleCubicFallback(observation){
 const symbols=observation?.symbols,count=CODEBOOK[0].symbols.length;
 if(observation?.id||observation?.conflict||!Array.isArray(symbols)||symbols.length!==count||symbols.some(x=>x!==null&&(!Number.isInteger(x)||x<0||x>3))||symbols.filter(x=>x!==null).length<4)return null;
 const compatible=CODEBOOK.filter(item=>symbols.every((x,i)=>x===null||x===item.symbols[i]));
 return compatible.length===1?compatible[0]:null;
}
export function selectCubicFallbackCandidates(observations,frame=0){
 const candidates=observations.filter(o=>eligibleCubicFallback(o)&&Array.isArray(o.q)&&o.q.length===4&&o.q.every(p=>Array.isArray(p)&&p.length===2&&p.every(Number.isFinite)));
 const center=q=>q.reduce((s,p)=>[s[0]+p[0]/4,s[1]+p[1]/4],[0,0]);
 candidates.sort((a,b)=>{const ac=center(a.q),bc=center(b.q);return ac[1]-bc[1]||ac[0]-bc[0];});
 const start=candidates.length&&Number.isFinite(frame)?Math.max(0,Math.floor(frame))%candidates.length:0;
 return [...candidates.slice(start),...candidates.slice(0,start)].slice(0,2);
}
export function mergeCubicFallback(baseline,cubic){
 const compatible=eligibleCubicFallback(baseline);
 if(!compatible||!cubic||cubic.conflict||!Array.isArray(cubic.symbols)||cubic.symbols.length!==baseline.symbols.length||baseline.symbols.some((x,i)=>x!==null&&cubic.symbols[i]!==x))return null;
 const symbols=baseline.symbols.map((x,i)=>x===null?cubic.symbols[i]:x),item=decodeObserved(symbols);
 // Failed fallback evidence never enters temporal history.
 return item?.id===compatible.id?{...baseline,...cubic,symbols,id:item.id,fallbackAttempt:true,fallbackUsed:true}:null;
}

// Only pixels consumed by the existing reader, including its orientation marks.
// Sampling every edge retains all disagreement checks, even after a valid ID.
export function cubicReaderPatches(layout=stripeLayout(),useSides=READER_OPTIONS.useSides){
 const patches=[[70,47,24,34],[526,47,22,34],[70,797,24,34],[526,797,22,34]];
 for(let i=0;i<layout.count;i++){
  const x=Math.round(layout.center(i)-layout.sampleWidth/2);
  patches.push([x,42,layout.sampleWidth,48],[x,792,layout.sampleWidth,48]);
  if(useSides){const y=Math.round(160+i*560/(layout.count-1)-layout.sampleWidth/2);patches.push([39,y,48,layout.sampleWidth],[553,y,48,layout.sampleWidth]);}
 }
 return patches;
}
export function readCubicFallback(src,q){
 const owned=[],own=mat=>{owned.push(mat);return mat;};
 try{
  const a=own(cv.matFromArray(4,1,cv.CV_32FC2,q.flat())),b=own(cv.matFromArray(4,1,cv.CV_32FC2,[35,35,605,35,605,845,35,845]));
  const H=own(cv.getPerspectiveTransform(a,b)),dst=own(new cv.Mat()),crop=document.createElement('canvas'),tile=document.createElement('canvas');
  crop.width=640;crop.height=880;const context=crop.getContext('2d');context.fillStyle='white';context.fillRect(0,0,640,880);
  for(const [x,y,width,height] of cubicReaderPatches()){
   // Embind Mat.clone() aliases its native Mat; allocate each transform copy.
   const shifted=cv.matFromArray(3,3,cv.CV_64F,Array.from(H.data64F));
   try{
    const data=shifted.data64F;
    for(let i=0;i<3;i++){data[i]-=x*data[6+i];data[3+i]-=y*data[6+i];}
    cv.warpPerspective(src,dst,shifted,new cv.Size(width,height),cv.INTER_CUBIC);
    tile.width=width;tile.height=height;cv.imshow(tile,dst);context.drawImage(tile,x,y);
   }finally{shifted.delete();}
  }
  return observeRectified(crop);
 }finally{for(const mat of owned.reverse())mat.delete();}
}
