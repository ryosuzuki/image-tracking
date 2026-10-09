// Convex collision outline of nontransparent printed pixels inside a manual source crop.
// Row extrema preserve the whole pixel hull while avoiding sorting every ink pixel.
export function inkConvexHull({data,width,height}){
 const points=[]
 for(let y=0;y<height;y++){
  let left=width,right=-1
  for(let x=0;x<width;x++)if(data[(y*width+x)*4+3]>0){left=Math.min(left,x);right=x}
  if(right>=left)for(const [x,py]of [[left,y],[right+1,y],[left,y+1],[right+1,y+1]])points.push({x,y:py})
 }
 points.sort((a,b)=>a.x-b.x||a.y-b.y)
 const unique=points.filter((p,i)=>!i||p.x!==points[i-1].x||p.y!==points[i-1].y)
 if(unique.length<3)return []
 const cross=(a,b,c)=>(b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x),lower=[],upper=[]
 for(const p of unique){while(lower.length>1&&cross(lower.at(-2),lower.at(-1),p)<=0)lower.pop();lower.push(p)}
 for(const p of [...unique].reverse()){while(upper.length>1&&cross(upper.at(-2),upper.at(-1),p)<=0)upper.pop();upper.push(p)}
 return lower.slice(0,-1).concat(upper.slice(0,-1))
}

// Follow clockwise pixel edges. Right turns keep diagonally touching islands separate.
export function inkContours({data,width,height}){
 const edges=[],starts=new Map(),on=(x,y)=>x>=0&&y>=0&&x<width&&y<height&&data[(y*width+x)*4+3]>0
 const add=(x,y,tx,ty,dir)=>{const e={x,y,tx,ty,dir,used:false},key=`${x},${y}`;edges.push(e);if(!starts.has(key))starts.set(key,[]);starts.get(key).push(e)}
 for(let y=0;y<height;y++)for(let x=0;x<width;x++)if(on(x,y)){
  if(!on(x,y-1))add(x,y,x+1,y,0)
  if(!on(x+1,y))add(x+1,y,x+1,y+1,1)
  if(!on(x,y+1))add(x+1,y+1,x,y+1,2)
  if(!on(x-1,y))add(x,y+1,x,y,3)
 }
 const loops=[]
 for(const first of edges){if(first.used)continue;const loop=[];let edge=first
  while(edge&&!edge.used){edge.used=true;loop.push({x:edge.x,y:edge.y});if(edge.tx===first.x&&edge.ty===first.y)break;const next=(starts.get(`${edge.tx},${edge.ty}`)||[]).filter(e=>!e.used);const priority=d=>[1,0,3,2].indexOf(d);next.sort((a,b)=>priority((a.dir-edge.dir+4)%4)-priority((b.dir-edge.dir+4)%4));edge=next[0]}
  if(loop.length<3)continue
  const simple=loop.filter((p,i)=>{const a=loop[(i+loop.length-1)%loop.length],b=loop[(i+1)%loop.length];return (p.x-a.x)*(b.y-p.y)-(p.y-a.y)*(b.x-p.x)!==0})
  const area=simple.reduce((sum,p,i)=>{const n=simple[(i+1)%simple.length];return sum+p.x*n.y-n.x*p.y},0)/2
  if(simple.length>=3&&area)loops.push({points:simple,area})
 }
 const inside=(p,poly)=>{let hit=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const a=poly[i],b=poly[j];if((a.y>p.y)!==(b.y>p.y)&&p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x)hit=!hit}return hit}
 const components=loops.filter(l=>l.area>0).map(l=>({outer:l.points,area:l.area,holes:[]}))
 for(const hole of loops.filter(l=>l.area<0)){const owner=components.filter(c=>inside(hole.points[0],c.outer)).sort((a,b)=>a.area-b.area)[0];if(owner)owner.holes.push(hole.points)}
 return components
}
