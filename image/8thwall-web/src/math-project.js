import {canvasTarget} from './canvas-project.js'
import {parseExpression} from './math-semantics.js'
import {polynomial2} from './math-polynomial.js'
import {isShiftedPower} from './math-power.js'
const numericIds=['h','k','r','a','b','math-exponent','sample-x','sum-n','graph-unit']
const parameters=c=>Object.fromEntries(['h','k','r','a','b','n'].map(key=>[key,c[key==='n'?'math-exponent':key].value]))
const finite=(n,limit=1e6)=>typeof n==='number'&&Number.isFinite(n)&&Math.abs(n)<=limit
const fail=message=>{throw Error(message)}
function expressionValid(expression,family,p){
 if(typeof expression!=='string'||expression.length>1024)fail('Invalid graph expression')
 parseExpression(expression)({...p,x:0})
 const compact=expression.replace(/\s/g,'')
 if(!['function','quadratic','circle','triangle','power'].includes(family))fail('Unsupported graph family')
 if(family==='power'&&!isShiftedPower(expression))fail('Power family needs its shifted-power expression')
 if(family==='quadratic'){const polynomial=polynomial2(expression,p);if(!polynomial||polynomial.xx===0||polynomial.y||polynomial.yy||polynomial.xy)fail('Quadratic family needs a degree-two polynomial')}
 if(family==='circle'&&compact!=='sqrt(r^2-(x-h)^2)+k')fail('Circle family needs its supported upper branch')
 if(family==='triangle'&&compact!=='sqrt(a^2+b^2)')fail('Triangle family needs its supported hypotenuse expression')
}
export function validateMathProject(value,target){
 if(!value||value.format!=='augmented-math-project'||value.version!==1)fail('Unsupported Math project format')
 if(JSON.stringify(value).length>100000)fail('Math project file is too large')
 const expected=canvasTarget(target);for(const key of ['name','aspect','sourceImage','sourceRevision','referenceRevision','sourceSHA256'])if(value.target?.[key]!==expected[key])fail('Project source does not match the currently tracked image revision')
 const controls=value.controls;if(!controls||Object.keys(controls).length!==numericIds.length||!numericIds.every(id=>Object.hasOwn(controls,id)))fail('Invalid Math controls')
 for(const id of numericIds){const c=controls[id];if(!c||!finite(c.value)||!finite(c.min)||!finite(c.max)||c.min>=c.max||c.value<c.min||c.value>c.max||!(c.step==='any'||finite(c.step)&&c.step>0))fail('Invalid numeric control '+id)}
 for(const [id,low,high]of [['math-exponent',1,6],['sample-x',-6,3],['sum-n',1,20],['graph-unit',.001,.2]]){const c=controls[id];if(c.min<low||c.max>high)fail('Unsupported range for '+id)}
 for(const id of ['r','a','b'])if(controls[id].min<=0)fail('Positive geometry lengths required')
 const graph=value.graph;if(graph&&Object.keys(graph).some(k=>!['originX','originY','unit','family','coefficients','sourceEquation'].includes(k)))fail('Unexpected graph property')
 if(!graph||!finite(graph.originX,100)||!finite(graph.originY,100)||!finite(graph.unit)||graph.unit<.001||graph.unit>.2||graph.unit!==controls['graph-unit'].value)fail('Invalid graph placement or units')
 if(graph.coefficients!==null&&(!graph.coefficients||Object.keys(graph.coefficients).length!==3||!['a','b','c'].every(k=>finite(graph.coefficients[k]))||graph.coefficients.a===0))fail('Invalid quadratic coefficients')
 if(graph.sourceEquation!==null&&(typeof graph.sourceEquation!=='string'||graph.sourceEquation.length>4096))fail('Invalid source formula metadata')
 expressionValid(value.expression,graph.family,parameters(controls))
 if(value.tools&&Object.keys(value.tools).some(k=>!['highlight','step','curveDragging'].includes(k)))fail('Unexpected Math tool property')
 if(value.tools?.curveDragging!==undefined&&typeof value.tools.curveDragging!=='boolean')fail('Invalid curve dragging state')
 if(!value.tools||typeof value.tools.highlight!=='boolean'||!Number.isInteger(value.tools.step)||value.tools.step<0||value.tools.step>3)fail('Invalid relationship or hint state')
 if(!Array.isArray(value.comparisons)||value.comparisons.length>8)fail('Invalid comparison curve count')
 const ids=new Set();for(const entry of value.comparisons){if(entry?.binding!==undefined&&!['shared','frozen'].includes(entry.binding))fail('Invalid comparison value binding');if(!entry||!Number.isSafeInteger(entry.id)||entry.id<1||entry.id>1e9||ids.has(entry.id)||typeof entry.enabled!=='boolean'||!/^#[0-9a-f]{6}$/i.test(entry.color))fail('Invalid comparison identity or appearance');ids.add(entry.id);if(!entry.parameters||Object.keys(entry.parameters).length!==6||!['h','k','r','a','b','n'].every(k=>finite(entry.parameters[k]))||['r','a','b'].some(k=>entry.parameters[k]<=0)||entry.parameters.n<1||entry.parameters.n>6)fail('Invalid comparison parameters');expressionValid(entry.expression,entry.family,entry.parameters)}
 return JSON.parse(JSON.stringify(value))
}
export function installMathProject({getTarget,getAnchor,mathTools,sourceMath,mathSymbols,comparison,redraw,recordEvent,diagnostics}){
 document.querySelector('#math-controls').insertAdjacentHTML('beforeend','<details id="math-project"><summary>Save or reopen this Math graph</summary><p>Save authored formulas, values, graph placement and kept curves for this source image.</p><button id="save-math-project">Save Math project</button><label>Load Math project <input id="load-math-project" type="file" accept="application/json,.json"></label><p id="math-project-status"></p></details>')
 const status=document.querySelector('#math-project-status'),input=document.querySelector('#load-math-project')
 function target(){const t=getTarget();if(!t?.graph||!getAnchor()?.visible||document.querySelector('#mode').value!=='math')fail('Track the matching source image in Math mode first');return t}
 function snapshot(){const t=target();return{format:'augmented-math-project',version:1,target:canvasTarget(t),graph:{originX:t.graph.originX,originY:t.graph.originY,unit:t.graph.unit,family:t.graph.family,coefficients:t.graph.coefficients??null,sourceEquation:t.graph.sourceEquation??null},expression:document.querySelector('#math-expression').value,controls:Object.fromEntries(numericIds.map(id=>{const e=document.querySelector('#'+id);return[id,{value:+e.value,min:+e.min,max:+e.max,step:e.step==='any'?'any':+e.step||1}]})),tools:mathTools.snapshot(),comparisons:comparison.snapshot()}}
 function load(value){const t=target(),data=validateMathProject(value,t);sourceMath.cancel();sourceMath.clearHints();mathTools.cancel();mathSymbols.cancel();for(const id of numericIds){const e=document.querySelector('#'+id),c=data.controls[id];e.min=c.min;e.max=c.max;e.step=c.step;e.value=c.value}document.querySelector('#math-expression').value=data.expression;Object.assign(t.graph,data.graph);delete t.graph.sourceFigure;comparison.restore(data.comparisons);mathTools.restore(data.tools);redraw();diagnostics.mathProject={loaded:true,target:t.name,curves:data.comparisons.length};recordEvent({name:'mathprojectload',at:performance.now(),target:t.name,project:data});return data}
 document.querySelector('#save-math-project').onclick=()=>{try{const data=validateMathProject(snapshot(),target()),url=URL.createObjectURL(new Blob([JSON.stringify(data,null,2)],{type:'application/json'})),a=document.createElement('a');a.href=url;a.download=data.target.name+'-math-project.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);recordEvent({name:'mathprojectsave',at:performance.now(),target:data.target.name,project:data});status.textContent='Saved this authored graph and '+data.comparisons.length+' comparison curves.'}catch(e){status.textContent=e.message}}
 input.onchange=async()=>{try{const file=input.files[0];if(!file)return;if(file.size>100000)fail('Math project file is too large');const data=load(JSON.parse(await file.text()));status.textContent='Loaded authored graph and '+data.comparisons.length+' kept curves. Verify their correspondence to the printed figure.'}catch(e){status.textContent=e.message}finally{input.value=''}}
 window.demoMathProject={snapshot,load};window.demoMathProjectSnapshot=()=>{try{return validateMathProject(snapshot(),target())}catch{return null}}
}
