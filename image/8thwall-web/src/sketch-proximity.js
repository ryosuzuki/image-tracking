export function nearestTrackedBinding(endpoint,candidates,radius=.04){
 if(!Number.isFinite(endpoint?.x)||!Number.isFinite(endpoint?.y)||!Number.isFinite(radius)||radius<=0)return null
 let nearest=null,best=radius
 for(const {id,point}of candidates){if(!Number.isFinite(point?.x)||!Number.isFinite(point?.y))continue;const distance=Math.hypot(endpoint.x-point.x,endpoint.y-point.y);if(distance<=best){best=distance;nearest=id}}
 return nearest
}
export function inferPerpendicular(points,lines,{radius=.04,degrees=10}={}){
 if(points.length<2||!Number.isFinite(radius)||radius<=0||!Number.isFinite(degrees)||degrees<=0||degrees>30)return null
 const a=points[0],b=points.at(-1),vx=b.x-a.x,vy=b.y-a.y,nv=Math.hypot(vx,vy);if(!nv)return null
 const distance=(p,c,d)=>{const dx=d.x-c.x,dy=d.y-c.y,n=dx*dx+dy*dy;if(!n)return Infinity;const t=Math.max(0,Math.min(1,((p.x-c.x)*dx+(p.y-c.y)*dy)/n));return Math.hypot(p.x-c.x-t*dx,p.y-c.y-t*dy)}
 let best=null,score=Infinity
 for(const l of lines){const c=l.points?.[0],d=l.points?.at(-1);if(!c||!d)continue;const ux=d.x-c.x,uy=d.y-c.y,nu=Math.hypot(ux,uy);if(!nu)continue;const cosine=Math.abs((ux*vx+uy*vy)/(nu*nv)),near=Math.min(distance(a,c,d),distance(b,c,d));if(cosine<=Math.sin(degrees*Math.PI/180)&&near<=radius&&near+cosine<score){score=near+cosine;best={id:l.id,sign:ux*vy-uy*vx>=0?1:-1}}}
 return best
}
export function inferAngleGesture(points,lines,radius=.04){
 if(points.length<2||!Number.isFinite(radius)||radius<=0)return null
 const nearest=p=>{let best=null,distance=radius;for(const l of lines){const a=l.points?.[0],b=l.points?.at(-1);if(!a||!b)continue;const x=b.x-a.x,y=b.y-a.y,n=x*x+y*y;if(!n)continue;const t=((p.x-a.x)*x+(p.y-a.y)*y)/n;if(t<=.1||t>=.9)continue;const d=Math.hypot(p.x-a.x-t*x,p.y-a.y-t*y);if(d<=distance){distance=d;best=l}}return best}
 const a=nearest(points[0]),b=nearest(points.at(-1));if(!a||!b||a.id===b.id)return null
 const u={x:a.points.at(-1).x-a.points[0].x,y:a.points.at(-1).y-a.points[0].y},v={x:b.points.at(-1).x-b.points[0].x,y:b.points.at(-1).y-b.points[0].y};if(Math.abs(u.x*v.x+u.y*v.y)/Math.hypot(u.x,u.y)/Math.hypot(v.x,v.y)>.966)return null
 return [a.id,b.id]
}
// Search a short endpoint-connected path closed by the new line.
export function inferClosedRegion(candidate,lines,{radius=.04,maxEdges=8}={}){
 if(!Number.isFinite(radius)||radius<=0||!Number.isInteger(maxEdges)||maxEdges<2||maxEdges>8||candidate.points?.length<2)return null
 const first=candidate.points[0],goal=candidate.points.at(-1),near=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y)<=radius;let visits=0
 const usable=lines.filter(l=>l.points?.length>=2&&Math.hypot(l.points[0].x-l.points.at(-1).x,l.points[0].y-l.points.at(-1).y)>radius/2)
 function search(point,path,vertices,used){if(++visits>2000)return null;if(path.length>=2&&near(point,goal)){const polygon=vertices.map(v=>v.point);let area=0;for(let i=0;i<polygon.length;i++){const a=polygon[i],b=polygon[(i+1)%polygon.length];area+=a.x*b.y-b.x*a.y}if(Math.abs(area)/2>radius*radius/4)return {references:[...path.map(e=>e[0]),candidate.id],edgePath:[...path,[candidate.id,1,0]],closureRadius:radius}}
  if(path.length>=maxEdges)return null
  for(const l of usable){if(used.has(l.id))continue;for(const start of [0,1]){const a=start?l.points.at(-1):l.points[0],b=start?l.points[0]:l.points.at(-1);if(!near(point,a))continue;if(vertices.some(v=>near(v.point,b))&&!near(b,goal))continue;const next=new Set(used);next.add(l.id);const found=search(b,[...path,[l.id,start,1-start]],[...vertices,{point:b}],next);if(found)return found}}
  return null
 }
 return search(first,[],[{point:first}],new Set())
}
