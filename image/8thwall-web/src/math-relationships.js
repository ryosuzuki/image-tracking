import * as THREE from 'three'
import {Line2} from 'three/addons/lines/Line2.js'
import {LineGeometry} from 'three/addons/lines/LineGeometry.js'
import {LineMaterial} from 'three/addons/lines/LineMaterial.js'
import {parseExpression} from './math-semantics.js'
export function relationshipSegment(symbol,graph,p,expression){
 if(!graph||![graph.originX,graph.originY,graph.unit,...Object.values(p)].every(Number.isFinite)||graph.unit<=0)return null
 const point=(x,y)=>({x:graph.originX+x*graph.unit,y:graph.originY+y*graph.unit}),segment=(a,b,value,label)=>({symbol,points:[point(...a),point(...b)],value,label})
 if(graph.family==='triangle'){if(symbol==='a')return segment([0,0],[p.a,0],p.a,'a: horizontal leg');if(symbol==='b')return segment([0,0],[0,p.b],p.b,'b: vertical leg');if(symbol==='c')return segment([p.a,0],[0,p.b],Math.hypot(p.a,p.b),'c: computed hypotenuse')}
 if(graph.family==='circle'){if(symbol==='r')return segment([p.h,p.k],[p.h+p.r,p.k],p.r,'r: radius');if(symbol==='h')return segment([0,p.k],[p.h,p.k],p.h,'h: center horizontal coordinate');if(symbol==='k')return segment([p.h,0],[p.h,p.k],p.k,'k: center vertical coordinate')}
 if(!['x','y'].includes(symbol)||graph.family==='triangle')return null
 let y;try{y=parseExpression(expression)(p)}catch{return null}if(!Number.isFinite(y)||y< -2||y>8||p.x< -6||p.x>3)return null
 return symbol==='x'?segment([p.x,0],[p.x,y],p.x,'x: selected input and vertical projection'):segment([0,y],[p.x,y],y,'y: computed output and horizontal projection')
}
export function installMathRelationships({getTarget,getAnchor,diagnostics,recordEvent}){
 let focus=null,line,anchor,key
 document.querySelector('#math-controls').insertAdjacentHTML('beforeend','<p id="symbol-relationship-status">Hover or hold a symbol in the authored equation to highlight its figure relationship.</p>')
 const status=document.querySelector('#symbol-relationship-status')
 function setFocus(symbol){const t=getTarget(),a=getAnchor(),expression=document.querySelector('#math-expression').value;if(focus?.symbol===symbol&&focus.target===t?.name&&focus.expression===expression&&focus.anchor===a)return;if(!symbol){focus=null;return}focus={symbol,target:t?.name,anchor:a,expression,family:t?.graph?.family};recordEvent({name:'mathrelationshipfocus',at:performance.now(),target:t?.name,symbol,method:'Authored symbol correspondence'})}
 function tick(){const t=getTarget(),a=getAnchor();if(focus&&(focus.target!==t?.name||focus.anchor!==a||focus.expression!==document.querySelector('#math-expression').value||focus.family!==t?.graph?.family||!a?.visible||document.querySelector('#mode').value!=='math'))focus=null
 const p=Object.fromEntries(['h','k','r','a','b'].map(id=>[id,+document.querySelector('#'+id).value]));p.x=+document.querySelector('#sample-x').value;p.n=+document.querySelector('#math-exponent').value
 const relation=focus?relationshipSegment(focus.symbol,t.graph,p,focus.expression):null
 if(relation){if(anchor!==a){line=new Line2(new LineGeometry(),new LineMaterial({color:'#ffff55',linewidth:5,depthTest:false,transparent:true,opacity:.95}));line.renderOrder=20;a.add(line);anchor=a;key=null}line.material.resolution.set(innerWidth,innerHeight);const next=JSON.stringify(relation.points);if(next!==key){line.geometry.setPositions(relation.points.flatMap(q=>[q.x,q.y,.045]));key=next}line.visible=true;status.textContent=`${relation.label}: ${Number(relation.value.toPrecision(5))}`}else{if(line)line.visible=false;status.textContent='Hover or hold a symbol in the authored equation to highlight its figure relationship.'}
 diagnostics.mathRelationship={target:t?.name,symbol:focus?.symbol??null,visible:!!relation,relation,method:'Explicit supported correspondence on authored graph, not printed-symbol localization'}
 }
 return{focus:setFocus,tick,reset:()=>{focus=null;line=null;anchor=null;key=null}}
}
