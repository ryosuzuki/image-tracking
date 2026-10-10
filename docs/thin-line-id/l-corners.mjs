// Uncoded four-bracket geometry. No white-paper segmentation or identity claims.
const unit=v=>{const n=Math.hypot(...v);return v.map(x=>x/n)};
const alignment=(a,b)=>a[0]*b[0]+a[1]*b[1];
export function groupCorners(candidates){
 const c=[...candidates].sort((a,b)=>b.extent-a.extent).slice(0,80),found=[],seen=new Set();
 const accepts=(i,j,arm)=>{const d=[c[j].point[0]-c[i].point[0],c[j].point[1]-c[i].point[1]];return c[j].extent/c[i].extent>.45&&c[j].extent/c[i].extent<2.3&&Math.hypot(...d)>c[i].extent*1.4&&alignment(unit(d),c[i].arms[arm])>.90};
 for(let i=0;i<c.length;i++){
  const neighbors=[0,1].map(arm=>c.map((_,j)=>j).filter(j=>j!==i&&accepts(i,j,arm)).sort((a,b)=>Math.hypot(...c[a].point.map((v,k)=>v-c[i].point[k]))-Math.hypot(...c[b].point.map((v,k)=>v-c[i].point[k]))).slice(0,5));
  for(const j of neighbors[0])for(const l of neighbors[1])for(let k=0;k<c.length;k++){
   const ids=[i,j,k,l];if(new Set(ids).size!==4)continue;
   const key=[...ids].sort((a,b)=>a-b).join(',');if(seen.has(key))continue;
   let score=0,valid=true;
   for(let z=0;z<4;z++){const here=c[ids[z]],prev=c[ids[(z+3)%4]],next=c[ids[(z+1)%4]],a=unit(prev.point.map((v,n)=>v-here.point[n])),b=unit(next.point.map((v,n)=>v-here.point[n]));const fit=Math.max(Math.min(alignment(a,here.arms[0]),alignment(b,here.arms[1])),Math.min(alignment(a,here.arms[1]),alignment(b,here.arms[0])));if(fit<.90||here.extent/prev.extent>2.3||here.extent/prev.extent<.45){valid=false;break}score+=fit}
   if(!valid)continue;const q=ids.map(id=>c[id].point);const sides=q.map((p,z)=>Math.hypot(p[0]-q[(z+1)%4][0],p[1]-q[(z+1)%4][1]));if(Math.max(sides[0]/sides[2],sides[2]/sides[0],sides[1]/sides[3],sides[3]/sides[1])>1.45)continue;const crosses=q.map((p,z)=>{const a=q[(z+1)%4],b=q[(z+2)%4];return (a[0]-p[0])*(b[1]-a[1])-(a[1]-p[1])*(b[0]-a[0])});if(!(crosses.every(x=>x>0)||crosses.every(x=>x<0)))continue;
   const area=Math.abs(q.reduce((s,p,z)=>s+p[0]*q[(z+1)%4][1]-p[1]*q[(z+1)%4][0],0))/2;if(area<700)continue;
   seen.add(key);found.push({ids,q,area,score});
  }
 }
 // Prefer local sheets over large cross-sheet combinations. A corner belongs to one sheet.
 found.sort((a,b)=>a.area-b.area||b.score-a.score);const used=new Set(),out=[];for(const f of found)if(f.ids.every(i=>!used.has(i))){f.ids.forEach(i=>used.add(i));out.push(f.q)}return out;
}
export function detectLCandidates(gray){
 const mask=new cv.Mat(),cs=new cv.MatVector(),hier=new cv.Mat();cv.threshold(gray,mask,0,255,cv.THRESH_BINARY_INV|cv.THRESH_OTSU);cv.findContours(mask,cs,hier,cv.RETR_LIST,cv.CHAIN_APPROX_SIMPLE);const candidates=[];
 for(let i=0;i<cs.size();i++){const contour=cs.get(i),area=cv.contourArea(contour);if(area<15||area>gray.rows*gray.cols*.025){contour.delete();continue}const hull=new cv.Mat(),poly=new cv.Mat();cv.convexHull(contour,hull);const solidity=area/cv.contourArea(hull);const perimeter=cv.arcLength(contour,true);
 // Preserve thin arms: a perimeter-only epsilon can erase the inner notch.
 const epsilon=solidity>=.25 ? .025*perimeter : Math.min(.025*perimeter,Math.max(1.2,area/perimeter*.65));
 cv.approxPolyDP(contour,poly,epsilon,true);
 if(poly.rows>=5&&poly.rows<=9&&solidity>.07&&solidity<.83){const p=Array.from({length:poly.rows},(_,j)=>[poly.data32S[2*j],poly.data32S[2*j+1]]),signed=p.reduce((s,v,j)=>s+v[0]*p[(j+1)%p.length][1]-v[1]*p[(j+1)%p.length][0],0);let best=null,bc=-4;
 for(let j=0;j<p.length;j++){const a=p[(j+p.length-1)%p.length],b=p[j],d=p[(j+1)%p.length],cr=((b[0]-a[0])*(d[1]-b[1])-(b[1]-a[1])*(d[0]-b[0]))*Math.sign(signed);if(cr<bc){bc=cr;best={point:b,arms:[unit(a.map((v,n)=>v-b[n])),unit(d.map((v,n)=>v-b[n]))],extent:Math.sqrt(area)}}}if(best)candidates.push(best)}hull.delete();poly.delete();contour.delete();}
 mask.delete();cs.delete();hier.delete();return candidates;
}

export function detectLCorners(gray){return groupCorners(detectLCandidates(gray));}
