import {canvasTarget} from './canvas-project.js'
import {validateObjectGraph} from './sketch-objects-model.js'
import {parseExpression} from './math-semantics.js'
const fail=s=>{throw Error(s)},point=p=>p&&Number.isFinite(p.x)&&Number.isFinite(p.y)&&Math.abs(p.x)<=100&&Math.abs(p.y)<=100
const settings=['object-auto-bind','object-auto-perpendicular','object-auto-angle','object-auto-area','object-proximity','objects-plot','objects-plot-x','objects-plot-y','objects-plot-width','objects-plot-height']
export function validateSketchProject(value,target){
 if(!value||value.format!=='reality-sketch-project'||value.version!==1||JSON.stringify(value).length>4_000_000)fail('Unsupported or oversized Sketch project')
 const expected=canvasTarget(target);for(const key of ['name','aspect','sourceImage','sourceRevision','referenceRevision','sourceSHA256'])if(value.target?.[key]!==expected[key])fail('Sketch project source does not match the tracked image revision')
 if(!Array.isArray(value.measurements)||value.measurements.length>200||!Array.isArray(value.colors)||value.colors.length>6)fail('Invalid measurement or RGB input count')
 const colorIds=new Set();for(const c of value.colors){if(!/^rgb:[a-zA-Z0-9-]{1,80}$/.test(c.id)||colorIds.has(c.id)||typeof c.label!=='string'||c.label.length>80||!Array.isArray(c.rgb)||c.rgb.length!==3||!c.rgb.every(n=>Number.isInteger(n)&&n>=0&&n<=255))fail('Invalid RGB input');colorIds.add(c.id)}
 const rgb=v=>Array.isArray(v)&&v.length===3&&v.every(n=>Number.isInteger(n)&&n>=0&&n<=255)
 if(value.colorBinding!==null&&(!rgb(value.colorBinding?.rgb)||!Array.isArray(value.colorBinding.origin)||value.colorBinding.origin.length!==3||!value.colorBinding.origin.every(n=>Number.isFinite(n)&&Math.abs(n)<=100)))fail('Invalid selected color binding')
 const binding=b=>typeof b==='string'&&(b==='fixed'||/^(0|[1-9]|[12][0-9]|3[0-2])$/.test(b)||/^line:\d+:[01]$/.test(b)||colorIds.has(b)||b==='color'&&!!value.colorBinding)
 let count=0;for(const [i,o]of value.measurements.entries()){
  if(!o||o.id!==i||typeof o.name!=='string'||o.name.length>40||!['line','area','angle'].includes(o.kind)||!['length','angle','area'].includes(o.parameter)||!Array.isArray(o.points)||!o.points.every(point)||o.points.length>10000||!/^#[0-9a-f]{6}$/i.test(o.color)||!Number.isFinite(o.opacity)||o.opacity<.05||o.opacity>1||!binding(o.startBinding)||!binding(o.endBinding))fail('Invalid measurement geometry, style or binding')
  count+=o.points.length;for(const key of ['lengthExpression','angleExpression'])if(o[key]!==undefined&&(typeof o[key]!=='string'||o[key].length>1024))fail('Invalid constraint expression')
  if(o.kind==='line'&&(o.points.length!==2||!['length','angle'].includes(o.parameter)))fail('A line needs two endpoints')
  if(o.kind==='angle'&&(!Array.isArray(o.references)||o.references.length!==2||o.references[0]===o.references[1]||!o.references.every(id=>Number.isInteger(id)&&value.measurements[id]?.kind==='line')))fail('Angle needs two line references')
  if(o.kind==='area'){if(o.edgePath){if(!Array.isArray(o.edgePath)||o.edgePath.length<3||o.edgePath.length>8||!o.edgePath.every(e=>Array.isArray(e)&&e.length===3&&Number.isInteger(e[0])&&value.measurements[e[0]]?.kind==='line'&&[0,1].includes(e[1])&&[0,1].includes(e[2])&&e[1]!==e[2])||!Array.isArray(o.references)||JSON.stringify(o.references)!==JSON.stringify(o.edgePath.map(e=>e[0]))||!Number.isFinite(o.closureRadius)||o.closureRadius<=0||o.closureRadius>.2)fail('Invalid enclosed area references')}else if(o.points.length<3)fail('Polygon needs three points')}
  if(o.perpendicularTo!=null&&(!Number.isInteger(o.perpendicularTo)||![-1,1].includes(o.perpendicularSign)))fail('Invalid perpendicular reference')
  if((o.lengthExpression||o.angleExpression||o.perpendicularTo!=null)&&(o.kind!=='line'||o.endBinding!=='fixed'))fail('Constraint needs a fixed derived line endpoint')
 }
 if(count>100000)fail('Too many measurement points');validateObjectGraph(value.measurements)
 if(!point(value.plotOrigin)||!Number.isInteger(value.selected)||value.selected<0||value.selected>=Math.max(1,value.measurements.length))fail('Invalid plot origin or selected measurement')
 if(!value.settings||Object.keys(value.settings).length!==settings.length||!settings.every(k=>Object.hasOwn(value.settings,k)))fail('Invalid Sketch settings')
 for(const id of settings){const v=value.settings[id];if(['object-auto-bind','object-auto-perpendicular','object-auto-angle','object-auto-area','objects-plot'].includes(id)){if(typeof v!=='boolean')fail('Invalid inference or plot setting')}else if(typeof v!=='string'||v.length>4096)fail('Invalid plot setting')}
 for(const [id,min,max]of [['object-proximity',.001,.2],['objects-plot-width',.05,1],['objects-plot-height',.05,1]])if(!Number.isFinite(+value.settings[id])||+value.settings[id]<min||+value.settings[id]>max)fail('Out-of-range Sketch setting')
 const scope={t:0,...Object.fromEntries(value.measurements.map(o=>[o.name,1]))},ys=value.settings['objects-plot-y'].split(',').map(s=>s.trim()).filter(Boolean);if(ys.length>8)fail('Too many plot series');for(const expression of [value.settings['objects-plot-x'],...ys]){if(expression.length>1024)fail('Plot expression is too long');const evaluate=parseExpression(expression);if(value.settings['objects-plot'])evaluate(scope)}
 if(typeof value.bodyTracking!=='boolean'||typeof value.targetHeight!=='string'||value.targetHeight!==''&&(!Number.isFinite(+value.targetHeight)||+value.targetHeight<=0||+value.targetHeight>1e6))fail('Invalid body or assumed height setting')
 return JSON.parse(JSON.stringify(value))
}
