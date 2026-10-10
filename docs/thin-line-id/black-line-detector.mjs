// Standalone opt-in black-line prototype, separate from the color pages.
import {detectLCorners} from './l-corners.mjs?v=iter-20261010-g';
import {observeBlackLine,observeBlackLineWithFallback,decodeBlackBits,decodeBlackObservation} from './black-line-code.mjs?v=wall-20261010-a';
export function inspectBlackLine(canvas,options){
 const started=performance.now(),src=cv.imread(canvas),gray=new cv.Mat(),geometry=[],matches=[];
 try{cv.cvtColor(src,gray,cv.COLOR_RGBA2GRAY);
  for(const raw of detectLCorners(gray,options)){
   const center=raw.reduce((sum,p)=>[sum[0]+p[0]/4,sum[1]+p[1]/4],[0,0]),ordered=raw.slice().sort((a,b)=>Math.atan2(a[1]-center[1],a[0]-center[0])-Math.atan2(b[1]-center[1],b[0]-center[0]));let observation=null,q=ordered;
   orientations:for(const rev of [ordered,[...ordered].reverse()])for(let shift=0;shift<4;shift++){
    const candidate=[...rev.slice(shift),...rev.slice(0,shift)],a=cv.matFromArray(4,1,cv.CV_32FC2,candidate.flat()),b=cv.matFromArray(4,1,cv.CV_32FC2,[35,35,605,35,605,845,35,845]),H=cv.getPerspectiveTransform(a,b),dst=new cv.Mat(),crop=document.createElement('canvas');
    try{if(options?.strips!==false){crop.width=640;crop.height=880;const ctx=crop.getContext('2d'),tile=document.createElement('canvas');ctx.fillStyle='white';ctx.fillRect(0,0,640,880);cv.warpPerspective(src,dst,H,new cv.Size(640,100));cv.imshow(tile,dst);ctx.drawImage(tile,0,0);const shifted=cv.matFromArray(3,3,cv.CV_64F,Array.from(H.data64F));try{for(let i=0;i<3;i++)shifted.data64F[3+i]-=780*shifted.data64F[6+i];cv.warpPerspective(src,dst,shifted,new cv.Size(640,100));cv.imshow(tile,dst);ctx.drawImage(tile,0,780);}finally{shifted.delete();}}else{cv.warpPerspective(src,dst,H,new cv.Size(640,880));cv.imshow(crop,dst);}const observed=((options?.lowMassFallback||options?.lowMassCascade)?observeBlackLineWithFallback:observeBlackLine)(crop,options);if(observed){observation=observed;q=candidate;break orientations;}}finally{for(const m of [a,b,H,dst])m.delete();}
   }
   const item=decodeBlackObservation(observation,options);geometry.push({q,id:item?.id||null,observation});if(item)matches.push({...item,...observation,q});
  }
  return {geometry,matches,processingMs:performance.now()-started};
 }finally{gray.delete();src.delete();}
}
