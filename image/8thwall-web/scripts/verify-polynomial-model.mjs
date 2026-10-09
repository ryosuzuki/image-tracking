import assert from 'node:assert/strict'
import {polynomial2} from '../src/math-polynomial.js'
import {chromium} from 'playwright'
import {writeFile} from 'node:fs/promises'
import {identifyEquation} from '../src/math-source-model.js'
assert.deepEqual(polynomial2('(x-2)^2+(y+3)^2-25'),{constant:-12,x:-4,y:6,xx:1,xy:0,yy:1})
assert.equal(identifyEquation('(x-2)^2+(y+3)^2=25').r,5)
assert.equal(identifyEquation('(x-h)^2+(y-k)^2=r^2').family,'circle')
assert.equal(identifyEquation('y=2x^2-7x+3').a,2)
assert.equal(identifyEquation('y=x^2+x*(x-1)*(x+1)*(x-2)').family,'function','Four coincident samples cannot prove a quadratic')
assert.equal(identifyEquation('x^2+y^2+x*(x^2-1)*(x^2-4)=4').family,'algebra','Five coincident x samples cannot prove a circle')
assert.equal(identifyEquation('x^2+2*x*y+y^2=1').family,'algebra')
assert.equal(identifyEquation('x^2+2*y^2=1').family,'algebra')
assert.equal(identifyEquation('(x-h)^2+(y-k)^2+x^3=r^2').family,'algebra')
assert.equal(identifyEquation('2*x+3*y=12').expression,'-0.6666666666666666*x+4')
assert.equal(identifyEquation('y=sin(2x)').family,'function');assert.equal(identifyEquation('y=unknown+x').family,'unsupported');assert.equal(identifyEquation('a^2+b^2=c^2+x^3').family,'algebra')
for(const expression of ['1/x','x^3','x*y*y','x/(x+1)','sqrt(x)','x^2^2','alert(x)','x;process.exit()'])assert.equal(polynomial2(expression),null,expression)
const functionValue=identifyEquation('y=x^2+x*(x-1)*(x+1)*(x-2)');assert.equal(functionValue.expression,'x^2+x*(x-1)*(x+1)*(x-2)')
console.log('Structural degree-two recognition, exact circle coefficient constraints and high-degree alias rejection pass; general functions retain their actual expressions')

const browser=await chromium.launch({headless:true,args:['--use-angle=metal','--autoplay-policy=no-user-gesture-required']}),page=await browser.newPage({viewport:{width:960,height:720}}),errors=[];page.on('pageerror',e=>errors.push(e.message))
try{
 await page.goto('http://localhost:5173/?target=original-01&roi=display&replay=1791345833299-84ae80d1-f7d8-4d92-b5d0-e1ad6f49c34e');await page.waitForFunction(()=>window.demoDiagnostics?.engineLoaded);await page.locator('#start').click();await page.waitForFunction(()=>demoDiagnostics.overlayVisible&&demoDiagnostics.found>0,null,{timeout:40000});await page.locator('#source-math').evaluate(e=>e.open=true)
 async function bind(formula){await page.locator('#camera-ocr-equation').fill(formula);await page.locator('#camera-ocr-bind').click();return page.evaluate(()=>({family:demoTarget.graph.family,expression:document.querySelector('#math-expression').value,h:+document.querySelector('#h').value,k:+document.querySelector('#k').value,r:+document.querySelector('#r').value,math:demoDiagnostics.mathTools}))}
 const alias=await bind('y=x^2+x*(x-1)*(x+1)*(x-2)');assert.equal(alias.family,'function');await page.locator('#sample-x').evaluate(e=>{e.value=1.5;e.dispatchEvent(new Event('input'))});assert.equal(await page.evaluate(()=>demoDiagnostics.mathTools.y),1.3125)
 await bind('y=1/x');const poleGeometry=await page.evaluate(()=>{const p=demoAnchor.children[0].geometry.attributes.position,g=demoTarget.graph;return Array.from({length:p.count/2},(_,i)=>[(p.getX(i*2)-g.originX)/g.unit,(p.getX(i*2+1)-g.originX)/g.unit])});assert.ok(poleGeometry.length>30);for(const [a,b]of poleGeometry)assert.equal(Math.sign(a),Math.sign(b),'Active curve cannot bridge its pole');const rejected=await bind('y=unknown+x');assert.equal(await page.evaluate(()=>demoDiagnostics.sourceMath.binding.family),'unsupported');
 const quadratic=await bind('y=2x^2-7x+3');assert.equal(quadratic.h,-1.75);assert.equal(quadratic.k,-3.125);assert.equal(quadratic.math.y,2*1.5**2-7*1.5+3);assert.equal(quadratic.math.expanded.linear,-7);assert.equal(quadratic.math.expanded.constant,3)
 const circle=await bind('(x-2)^2+(y+3)^2=5');assert.equal(circle.h,2);assert.equal(circle.k,-3);assert.equal(circle.r,Math.sqrt(5))
 await bind('y=2x^2-7x+3');await page.locator('#math-expression').fill('(x+h)^2+k');await page.locator('#bind-equation').click();const custom=await page.evaluate(()=>demoDiagnostics.mathTools);assert.equal(custom.expanded.quadratic,1);assert.equal(custom.y,(custom.x+custom.h)**2+custom.k)
 const d=await page.evaluate(()=>({found:demoDiagnostics.found,updated:demoDiagnostics.updated,errors:demoDiagnostics.errors}));await page.locator('#stop').click();assert.deepEqual(errors,[]);assert.deepEqual(d.errors,[]);await writeFile('evidence/polynomial-model.json',JSON.stringify({input:'Actual C920 source01 replay with explicitly manually entered formulas; no OCR or automatic correspondence claim',alias,poleGeometry,rejected,quadratic,circle,custom,...d,pageErrors:errors,verified:['Structural degree-two recognition rejects finite-sample aliases','Active curve line segments do not bridge1/x pole; unknown symbols reject without engine errors','Non-quadratic function keeps actual expression and numeric values','Nonmonic quadratic retains exact fractional vertex values','Irrational circle radius is not quantized by range controls','Direct expression binding clears prior source coefficient metadata'],limitations:['Supported structural polynomial degree at most two; other explicit functions retain expression, unsupported implicit equations remain algebra','Image-plane authored graph; no new physical acquisition']},null,2));console.log(JSON.stringify({passed:true,...d}))
}finally{try{await page.locator('#stop').click({timeout:1000})}catch{}await browser.close()}
