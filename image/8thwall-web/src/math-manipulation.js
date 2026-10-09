// Image-plane handles for the explicitly bound graph family.
export function graphHandles(graph,{h,k,r,a,b}){
 if(!graph||!Number.isFinite(graph.unit)||graph.unit<=0)return []
 const {originX:x,originY:y,unit:u}=graph
 if(graph.family==='circle')return [{control:'center',x:x+h*u,y:y+k*u},{control:'radius',x:x+(h+r)*u,y:y+k*u}]
 if(graph.family==='triangle')return [{control:'leg-a',x:x+a*u,y},{control:'leg-b',x,y:y+b*u}]
 if(graph.family==='power')return [{control:'power-origin',x:x-h*u,y:y+k*u}]
 if(graph.family==='quadratic')return [{control:'vertex',x:x-h*u,y:y+k*u}]
 return []
}
export function handleValues(control,point,graph,values){
 const {originX:x,originY:y,unit:u}=graph
 if(![point.x,point.y,x,y,u].every(Number.isFinite)||u<=0)return null
 if(control==='center')return {h:(point.x-x)/u,k:(point.y-y)/u}
 if(control==='vertex'||control==='power-origin')return {h:-(point.x-x)/u,k:(point.y-y)/u}
 if(control==='radius')return {r:Math.hypot((point.x-x)/u-values.h,(point.y-y)/u-values.k)}
 if(control==='leg-a')return {a:(point.x-x)/u}
 if(control==='leg-b')return {b:(point.y-y)/u}
 return null
}
