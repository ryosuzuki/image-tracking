// Display-only, fresh geometry. Never reads or carries IDs; raw q references stay intact.
const valid=q=>Array.isArray(q)&&q.length===4&&q.every(p=>Array.isArray(p)&&p.length===2&&p.every(Number.isFinite));
const size=q=>Math.sqrt(Math.abs(q.reduce((s,p,i)=>s+p[0]*q[(i+1)%4][1]-p[1]*q[(i+1)%4][0],0))/2);
const distance=(a,b)=>Math.sqrt(a.reduce((s,p,i)=>s+(p[0]-b[i][0])**2+(p[1]-b[i][1])**2,0)/4)/Math.max(1,Math.min(size(a),size(b)));
export class GeometryDisplaySmoother {
 constructor({alpha=.4,maxDistance=.15,maxScaleRatio=1.2,ambiguityMargin=.04,maxGapMs=300}={}){Object.assign(this,{alpha,maxDistance,maxScaleRatio,ambiguityMargin,maxGapMs});this.reset();}
 reset(){this.previous=[];this.time=null;}
 update(geometry,now,{sceneChanged=false}={}){
  if(!Number.isFinite(now)||sceneChanged||this.time!==null&&(now<=this.time||now-this.time>this.maxGapMs))this.reset();
  const items=geometry.map(g=>g?.q??g).filter(valid),previous=this.previous;
  const costs=items.map(q=>previous.map(p=>{const ratio=size(q)/Math.max(1,size(p.raw));return ratio<1/this.maxScaleRatio||ratio>this.maxScaleRatio?Infinity:distance(q,p.raw);}));
  const best=costs.map(row=>{const order=row.map((d,i)=>({d,i})).sort((a,b)=>a.d-b.d);return order[0]&&order[0].d<this.maxDistance&&(!order[1]||order[1].d-order[0].d>this.ambiguityMargin)?order[0].i:-1;});
  const result=items.map((q,i)=>{
   const j=best[i];let safe=j>=0&&best.filter(x=>x===j).length===1;
   if(safe){const column=costs.map((row,k)=>({d:row[j],k})).sort((a,b)=>a.d-b.d);safe=column[0].k===i&&(!column[1]||column[1].d-column[0].d>this.ambiguityMargin);}
   const displayQ=safe?q.map((p,k)=>p.map((v,l)=>this.alpha*v+(1-this.alpha)*previous[j].display[k][l])):q.map(p=>p.slice());
   return {q,displayQ,smoothed:safe};
  });
  this.previous=result.map(r=>({raw:r.q.map(p=>p.slice()),display:r.displayQ.map(p=>p.slice())}));this.time=Number.isFinite(now)?now:null;
  return result;
 }
}
