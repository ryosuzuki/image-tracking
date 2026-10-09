import * as THREE from 'three'
import {Line2} from 'three/addons/lines/Line2.js'
import {LineGeometry} from 'three/addons/lines/LineGeometry.js'
import {LineMaterial} from 'three/addons/lines/LineMaterial.js'
// Keep intermediate shape deviations below one thousandth of target height.
// Removing redundant straight segments avoids repeated translucent cap blending.
function simplify(points,epsilon=.001){if(points.length<3)return points;const a=points[0],b=points.at(-1),dx=b.x-a.x,dy=b.y-a.y,dz=(b.z??0)-(a.z??0),n=dx*dx+dy*dy+dz*dz;let far=-1,max=epsilon*epsilon;for(let i=1;i<points.length-1;i++){const p=points[i],t=n?Math.max(0,Math.min(1,((p.x-a.x)*dx+(p.y-a.y)*dy+((p.z??0)-(a.z??0))*dz)/n)):0,d=(p.x-a.x-t*dx)**2+(p.y-a.y-t*dy)**2+((p.z??0)-(a.z??0)-t*dz)**2;if(d>max){far=i;max=d}}return far<0?[a,b]:[...simplify(points.slice(0,far+1),epsilon).slice(0,-1),...simplify(points.slice(far),epsilon)]}
export function strokeGeometry(line,points){return line.isLine2?new LineGeometry().setPositions(simplify(points).flatMap(p=>[p.x,p.y,p.z??.009])):new THREE.BufferGeometry().setFromPoints(points)}
export function createStrokeLine(points,{color,width=3,opacity=1}={}){const line=new Line2(new LineGeometry().setPositions(simplify(points).flatMap(p=>[p.x,p.y,p.z??.009])),new LineMaterial({color,linewidth:width,opacity,transparent:true,depthTest:false}));return line}
export function replaceStrokePoints(line,points){line.geometry.dispose();line.geometry=strokeGeometry(line,points)}
export function contourStroke(stroke,start,count){if(stroke.line.isLine2){replaceStrokePoints(stroke.line,Array.from({length:Math.max(2,count)},(_,i)=>stroke.points[(start+i)%stroke.points.length]));stroke.partial=true}else stroke.line.geometry.setDrawRange(start,count)}
export function restoreStroke(stroke){if(stroke.partial){replaceStrokePoints(stroke.line,stroke.points);stroke.partial=false}else stroke.line.geometry.setDrawRange(0,Infinity)}
