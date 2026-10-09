import {comparisonSegments} from './math-comparison.js'
export function canTranslateCurve(graph,expression){const text=expression.replace(/\s/g,'');return graph?.family==='power'&&text==='(x+h)^n+k'||graph?.family==='quadratic'&&/^(?:[+-]?\d+(?:\.\d+)?\*)?\(x\+h\)\^2\+k$/.test(text)}
export function curveHit(point,graph,expression,parameters,tolerance=.012){
 if(!canTranslateCurve(graph,expression)||![point.x,point.y].every(Number.isFinite))return false
 const points=comparisonSegments({family:graph.family,expression,parameters},graph)
 for(let i=0;i<points.length;i+=2){const a=points[i],b=points[i+1],dx=b.x-a.x,dy=b.y-a.y,length=dx*dx+dy*dy,t=length?Math.max(0,Math.min(1,((point.x-a.x)*dx+(point.y-a.y)*dy)/length)):0;if(Math.hypot(point.x-a.x-t*dx,point.y-a.y-t*dy)<=tolerance)return true}return false
}
export function translateCurve(start,current,graph,parameters){if(![start.x,start.y,current.x,current.y,graph?.unit,parameters.h,parameters.k].every(Number.isFinite)||graph.unit<=0)return null;return{h:parameters.h-(current.x-start.x)/graph.unit,k:parameters.k+(current.y-start.y)/graph.unit}}
