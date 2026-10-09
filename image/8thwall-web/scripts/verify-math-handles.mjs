import assert from 'node:assert/strict'
import {chromium} from 'playwright'
import {writeFile} from 'node:fs/promises'
import {graphHandles,handleValues} from '../src/math-manipulation.js'
const graph={family:'circle',originX:.1,originY:-.2,unit:.05},values={h:2,k:-1,r:3,a:3,b:4}
assert.deepEqual(graphHandles(graph,values).map(x=>x.control),['center','radius'])
assert.ok(Math.abs(handleValues('radius',{x:.2,y:0},graph,values).r-5)<1e-10)
assert.deepEqual(handleValues('leg-a',{x:.35,y:4},graph,values),{a:4.999999999999999})
assert.deepEqual(graphHandles({...graph,family:'function'},values),[])
assert.equal(handleValues('radius',{x:NaN,y:0},graph,values),null)
const browser=await chromium.launch({headless:true,args:['--use-angle=metal','--autoplay-policy=no-user-gesture-required']}),page=await browser.newPage({viewport:{width:960,height:720}}),errors=[]
page.on('pageerror',e=>errors.push(e.message))
try{
 await page.goto('http://localhost:5173/?target=original-01&roi=display&replay=1791345833299-84ae80d1-f7d8-4d92-b5d0-e1ad6f49c34e&record=1')
 await page.waitForFunction(()=>window.demoDiagnostics?.engineLoaded);await page.locator('#start').click()
 await page.waitForFunction(()=>demoDiagnostics.found>0&&demoDiagnostics.overlayVisible,null,{timeout:40000})
 await page.locator('#replay-pause').click();await page.locator('#replay-seek').evaluate(e=>{e.value=2;e.dispatchEvent(new Event('input'))})
 await page.waitForFunction(()=>!demoReplayVideo.seeking&&Math.abs(demoReplayVideo.currentTime-2)<.03);await page.waitForTimeout(700)
 await page.locator('#source-math').evaluate(e=>e.open=true)
 await page.locator('#camera-ocr-equation').fill('(x-h)^2+(y-k)^2=r^2');await page.locator('#camera-ocr-bind').click()
 await page.locator('#graph-unit').evaluate(e=>{e.value=.06;e.dispatchEvent(new Event('input'))})
 await page.locator('#toggle-controls').click()
 async function projected(point){return page.evaluate(p=>{const world=demoAnchor.localToWorld(new THREE.Vector3(p.x,p.y,.007)).project(XR8.Threejs.xrScene().camera);return{x:(world.x+1)*innerWidth/2,y:(1-world.y)*innerHeight/2}},point)}
 async function drag(control,dx,dy){const h=await page.evaluate(c=>demoDiagnostics.mathHandles.handles.find(h=>h.control===c),control);const from=await projected(h),to=await projected({x:h.x+dx,y:h.y+dy});await page.mouse.move(from.x,from.y);await page.mouse.down();await page.mouse.move(to.x,to.y,{steps:8});await page.mouse.up();await page.waitForTimeout(300);return page.evaluate(()=>demoDiagnostics.mathTools)}
 const radius=await drag('radius',.09,0);assert.ok(Math.abs(radius.r-3.5)<.15,JSON.stringify(radius))
 const center=await drag('center',.06,-.03);assert.ok(Math.abs(center.h-1)<.15);assert.ok(Math.abs(center.k+.5)<.15)
 assert.ok(Math.abs(center.r-radius.r)<.001)
 await page.waitForTimeout(1800);await page.screenshot({path:'../math-circle-direct-drag.png'})
 await page.locator('#toggle-controls').click();await page.locator('#camera-ocr-equation').fill('a^2+b^2=c^2');await page.locator('#camera-ocr-bind').click();await page.locator('#toggle-controls').click()
 const a=await drag('leg-a',.09,.04);assert.ok(Math.abs(a.a-4.5)<.15);assert.equal(a.b,4)
 const b=await drag('leg-b',.03,.06);assert.ok(Math.abs(b.b-5)<.15);assert.equal(b.a,a.a);assert.ok(Math.abs(b.c-Math.hypot(b.a,b.b))<1e-10)
 const geometry=await page.evaluate(()=>{const p=demoAnchor.children[0].geometry.attributes.position,g=demoTarget.graph;return{count:p.count,a:(p.getX(1)-g.originX)/g.unit,b:(p.getY(3)-g.originY)/g.unit}})
 assert.equal(geometry.count,6);assert.ok(Math.abs(geometry.a-b.a)<1e-6);assert.ok(Math.abs(geometry.b-b.b)<1e-6)
 await page.waitForTimeout(1800);await page.screenshot({path:'../math-triangle-direct-drag.png'})
 // A mode change while a pointer is held must cancel the Math edit.
 const point=await page.evaluate(()=>demoDiagnostics.mathHandles.handles[0]),screen=await projected(point);await page.mouse.move(screen.x,screen.y);await page.mouse.down();await page.locator('#mode').evaluate(e=>{e.value='canvas';e.dispatchEvent(new Event('change'))});await page.mouse.move(screen.x+30,screen.y+20);await page.mouse.up();assert.equal(await page.locator('#a').inputValue(),String(b.a));await page.locator('#mode').evaluate(e=>{e.value='math';e.dispatchEvent(new Event('change'))})
 const d=await page.evaluate(()=>({session:demoCaptureSession,found:demoDiagnostics.found,updated:demoDiagnostics.updated,errors:demoDiagnostics.errors,inputProvenance:demoInputProvenance}))
 await page.locator('#stop').evaluate(e=>e.click());await page.waitForFunction(()=>!demoDiagnostics.cameraStarted)
 assert.deepEqual(errors,[]);assert.deepEqual(d.errors,[])
 await writeFile('evidence/math-handles.json',JSON.stringify({input:'Unmodified actual C920 source01 camera replay through official SDK. Circle and triangle formulas explicitly manually entered on that source; no automatic diagram extraction claim.',radius,center,triangleA:a,triangleB:b,geometry,...d,pageErrors:errors,verified:['Circle radius handle changes r and preserves center','Circle center handle changes h/k and preserves radius','Triangle endpoints change independent a/b, hypotenuse and rendered vertices','Mode switch cancels unfinished Math drag'],limitations:['Image-plane interaction, user graph origin/unit; no independent metric validation','Manually entered formulas on source01; automatic circle/triangle correspondence remains pending']},null,2));console.log(JSON.stringify({passed:true,r:radius.r,center:[center.h,center.k],triangle:[b.a,b.b,b.c],...d}))
}finally{try{await page.locator('#stop').evaluate(e=>e.click())}catch{}await browser.close()}
