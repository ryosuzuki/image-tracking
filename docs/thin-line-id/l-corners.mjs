// Uncoded four-bracket geometry. No white-paper segmentation or identity claims.
const unit=v=>{const n=Math.hypot(...v);return v.map(x=>x/n)};
const alignment=(a,b)=>a[0]*b[0]+a[1]*b[1];
// Cache pair distances and arm alignments once; geometric acceptance is unchanged.
export function groupCorners(candidates){
 const c=[...candidates].sort((a,b)=>b.extent-a.extent).slice(0,80),n=c.length,found=[],seen=new Set();
 const distance=Array.from({length:n},()=>Array(n)),dirs=Array.from({length:n},()=>Array(n)),align=Array.from({length:n},()=>[Array(n),Array(n)]);
 for(let i=0;i<n;i++)for(let j=0;j<n;j++)if(i!==j){const dx=c[j].point[0]-c[i].point[0],dy=c[j].point[1]-c[i].point[1],len=Math.hypot(dx,dy);distance[i][j]=len;dirs[i][j]=[dx/len,dy/len];for(let a=0;a<2;a++)align[i][a][j]=dirs[i][j][0]*c[i].arms[a][0]+dirs[i][j][1]*c[i].arms[a][1];}
 const accepts=(i,j,a)=>c[j].extent/c[i].extent>.45&&c[j].extent/c[i].extent<2.3&&distance[i][j]>c[i].extent*1.4&&align[i][a][j]>.65;
 const fit=(i,j,k)=>Math.max(Math.min(align[i][0][j],align[i][1][k]),Math.min(align[i][1][j],align[i][0][k]));
 for(let i=0;i<n;i++){
  const neighbors=[0,1].map(a=>c.map((_,j)=>j).filter(j=>j!==i&&accepts(i,j,a)).sort((a,b)=>distance[i][a]-distance[i][b]).slice(0,5));
  for(const j of neighbors[0])for(const l of neighbors[1])for(let k=0;k<n;k++){
   const ids=[i,j,k,l];if(new Set(ids).size!==4)continue;const key=[...ids].sort((a,b)=>a-b).join(',');if(seen.has(key))continue;
   let score=0,valid=true;
   for(let z=0;z<4;z++){const here=ids[z],prev=ids[(z+3)%4],next=ids[(z+1)%4],f=fit(here,prev,next);if(f<.65||c[here].extent/c[prev].extent>2.3||c[here].extent/c[prev].extent<.45){valid=false;break;}score+=f;}
   if(!valid)continue;const q=ids.map(id=>c[id].point),sides=ids.map((id,z)=>distance[id][ids[(z+1)%4]]);
   if(Math.max(sides[0]/sides[2],sides[2]/sides[0],sides[1]/sides[3],sides[3]/sides[1])>1.25)continue;
   const scale=Math.min(...sides)/(ids.reduce((s,id)=>s+c[id].extent,0)/4);if(scale<9||scale>35)continue;
   const aspect=(sides[0]+sides[2])/(sides[1]+sides[3]);if(!((aspect>.48&&aspect<.92)||(aspect>1/.92&&aspect<1/.48)))continue;
   const crosses=q.map((p,z)=>{const a=q[(z+1)%4],b=q[(z+2)%4];return(a[0]-p[0])*(b[1]-a[1])-(a[1]-p[1])*(b[0]-a[0]);});if(!(crosses.every(x=>x>0)||crosses.every(x=>x<0)))continue;
   const area=Math.abs(q.reduce((s,p,z)=>s+p[0]*q[(z+1)%4][1]-p[1]*q[(z+1)%4][0],0))/2;if(area<700)continue;
   const crossesSheet=c.some((candidate,index)=>!ids.includes(index)&&q.some((a,z)=>{const b=q[(z+1)%4],dx=b[0]-a[0],dy=b[1]-a[1],length=Math.hypot(dx,dy),px=candidate.point[0]-a[0],py=candidate.point[1]-a[1],t=(px*dx+py*dy)/(length*length);return t>.12&&t<.88&&Math.abs(px*dy-py*dx)/length<Math.min(candidate.extent*1.5,length*.04);}));if(crossesSheet)continue;
   seen.add(key);found.push({ids,q,area,score});
  }
 }
 found.sort((a,b)=>b.score-a.score||a.area-b.area);const used=new Set(),out=[];for(const f of found)if(f.ids.every(i=>!used.has(i))){f.ids.forEach(i=>used.add(i));out.push(f.q);}return out;
}

export function detectLCandidates(gray,{block=0,bias=2}={}){
 const allocated=[],own=mat=>{allocated.push(mat);return mat};
 try{
 const mask=own(new cv.Mat()),cs=own(new cv.MatVector()),hier=own(new cv.Mat());
 if(block)cv.adaptiveThreshold(gray,mask,255,cv.ADAPTIVE_THRESH_GAUSSIAN_C,cv.THRESH_BINARY_INV,block,bias);
 else cv.threshold(gray,mask,0,255,cv.THRESH_BINARY_INV|cv.THRESH_OTSU);
 cv.findContours(mask,cs,hier,cv.RETR_LIST,cv.CHAIN_APPROX_SIMPLE);const candidates=[];
 for(let i=0;i<cs.size();i++){
  const local=[],keep=mat=>{local.push(mat);return mat};
  try{
   const contour=keep(cs.get(i)),area=cv.contourArea(contour);if(area<15||area>gray.rows*gray.cols*.025)continue;
   const hull=keep(new cv.Mat()),poly=keep(new cv.Mat());cv.convexHull(contour,hull);const solidity=area/cv.contourArea(hull),perimeter=cv.arcLength(contour,true);
   // Preserve thin arms: a perimeter-only epsilon can erase the inner notch.
   const epsilon=solidity>=.25 ? .025*perimeter : Math.min(.025*perimeter,Math.max(1.2,area/perimeter*.65));
   cv.approxPolyDP(contour,poly,epsilon,true);
   if(poly.rows>=5&&poly.rows<=9&&solidity>.07&&solidity<.92){const p=Array.from({length:poly.rows},(_,j)=>[poly.data32S[2*j],poly.data32S[2*j+1]]),signed=p.reduce((s,v,j)=>s+v[0]*p[(j+1)%p.length][1]-v[1]*p[(j+1)%p.length][0],0);let best=null,bc=-4;
    for(let j=0;j<p.length;j++){const a=p[(j+p.length-1)%p.length],b=p[j],d=p[(j+1)%p.length],cr=((b[0]-a[0])*(d[1]-b[1])-(b[1]-a[1])*(d[0]-b[0]))*Math.sign(signed);if(cr<bc){bc=cr;best={point:b,arms:[unit(a.map((v,n)=>v-b[n])),unit(d.map((v,n)=>v-b[n]))],extent:Math.sqrt(area)}}}if(best)candidates.push(best);
   }
  }finally{for(const mat of local.reverse())mat.delete();}
 }
 return candidates;
 }finally{for(const mat of allocated.reverse())mat.delete();}
}

export function detectLCorners(gray){return groupCorners(detectLCandidates(gray));}

// Opt-in only. Never mix threshold candidates before grouping: that can invent
// cross-paper rectangles. Require the same four corners in >=2 distinct passes.
export function detectLCornersConsensus(gray){
 const passes=[{block:0},{block:11,bias:2},{block:21,bias:2}];
 return consensusCorners(passes.map(options=>groupCorners(detectLCandidates(gray,options))));
}
export function consensusCorners(groupsByPass,{tolerance=6}={}){
 if(!Number.isFinite(tolerance)||tolerance<=0||tolerance>6)throw new RangeError('tolerance must be in (0,6]');
 const distance=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1]);
 const valid=q=>Array.isArray(q)&&q.length===4&&q.every(p=>Array.isArray(p)&&p.length===2&&p.every(Number.isFinite))&&new Set(q.map(p=>p.join(','))).size===4;
 const matches=(a,b)=>{const mapped=a.map(p=>b.map((r,i)=>({i,d:distance(p,r)})).sort((x,y)=>x.d-y.d)[0]);return mapped.every(m=>m.d<=tolerance)&&new Set(mapped.map(m=>m.i)).size===4;};
 const clusters=[];
 groupsByPass.forEach((groups,pass)=>{for(const q of groups){if(!valid(q))continue;const cluster=clusters.find(c=>matches(q,c.q));if(cluster)cluster.votes.add(pass);else clusters.push({q:q.map(p=>p.slice()),votes:new Set([pass])});}});
 const area=q=>Math.abs(q.reduce((sum,p,i)=>sum+p[0]*q[(i+1)%4][1]-p[1]*q[(i+1)%4][0],0))/2;
 const confirmed=clusters.filter(c=>c.votes.size>=2).sort((a,b)=>b.votes.size-a.votes.size||area(a.q)-area(b.q));
 const accepted=[];for(const c of confirmed)if(!accepted.some(q=>c.q.some(p=>q.some(r=>distance(p,r)<=tolerance))))accepted.push(c.q);
 return accepted;
}
