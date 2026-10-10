export class OverlayTracker{
 constructor({alpha=.4,holdMs=300}={}){this.alpha=alpha;this.holdMs=holdMs;this.items=new Map()}
 reset(){this.items.clear()}
 update(raw,now,{sceneChanged=false}={}){
  if(sceneChanged)this.reset();const seen=new Set();
  const center=q=>q.reduce((s,p)=>[s[0]+p[0]/4,s[1]+p[1]/4],[0,0]);const size=q=>Math.hypot(q[1][0]-q[0][0],q[1][1]-q[0][1]);
  for(const m of raw){let old=this.items.get(m.id),c=center(m.q),w=size(m.q);for(const [id,t]of this.items)if(id!==m.id&&Math.hypot(...center(t.q).map((v,k)=>v-c[k]))<w*.45)this.items.delete(id);
   const jump=old&&Math.max(...m.q.map((p,i)=>Math.hypot(p[0]-old.q[i][0],p[1]-old.q[i][1])))>Math.max(12,w*.2);const q=old&&!jump&&now-old.last<=this.holdMs?m.q.map((p,i)=>p.map((v,k)=>this.alpha*v+(1-this.alpha)*old.q[i][k])):m.q.map(p=>p.slice());
   this.items.set(m.id,{id:m.id,q,rawQ:m.q,last:now,fresh:true,ageMs:0});seen.add(m.id);
  }
  for(const [id,t]of this.items)if(!seen.has(id)){const age=now-t.last;if(age>this.holdMs)this.items.delete(id);else{t.fresh=false;t.ageMs=age}}
  return [...this.items.values()].map(t=>({...t,q:t.q.map(p=>p.slice())}));
 }
}
