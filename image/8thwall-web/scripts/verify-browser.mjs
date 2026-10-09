import {chromium} from 'playwright'
import {resolve} from 'node:path'
import {writeFile, mkdir} from 'node:fs/promises'
const base = process.env.DEMO_URL || 'http://localhost:5173'
const testUrl = `${base.replace(/\/$/, '')}/?evidence=synthetic`
const browser = await chromium.launch({headless:true,args:[
  '--use-fake-ui-for-media-stream','--use-fake-device-for-media-stream',
  `--use-file-for-fake-video-capture=${resolve('.test-fixtures/math-card.y4m')}`,
  '--enable-webgl','--use-angle=swiftshader','--enable-unsafe-swiftshader',
]})
await mkdir('evidence',{recursive:true}); await mkdir('.test-recordings/frames',{recursive:true})
const context = await browser.newContext({viewport:{width:960,height:720},ignoreHTTPSErrors:true,})
const page = await context.newPage()
const consoleErrors = [], pageErrors = [], requests = []; let recording = false, captureTask, frameNumber = 0
page.on('console', x => {if (x.type()==='error') consoleErrors.push(x.text())})
page.on('pageerror', x => pageErrors.push(x.message))
page.on('requestfailed', r => requests.push({url:r.url(),error:r.failure()}))
try {
  await page.goto(testUrl)
  await page.waitForFunction(() => window.demoDiagnostics?.engineLoaded, null, {timeout:90000})
  console.log('ENGINE READY'); await page.locator('#start').click()
  await page.waitForFunction(() => window.demoDiagnostics?.cameraStarted, null, {timeout:30000}); console.log('CAMERA STARTED')
  await page.waitForFunction(() => window.demoDiagnostics.found > 0, null, {timeout:90000})
  console.log('TRACKING FOUND'); await page.screenshot({path:'evidence/tracking-found.png'}); recording = true; captureTask = (async()=>{while(recording){await page.screenshot({path:`.test-recordings/frames/frame-${String(frameNumber++).padStart(5,'0')}.png`}); await new Promise(r=>setTimeout(r,200))}})()
  await page.waitForFunction(() => window.demoDiagnostics.lost > 0, null, {timeout:90000})
  console.log('TRACKING LOST'); await page.screenshot({path:'evidence/tracking-lost.png'})
  await page.waitForFunction(() => window.demoDiagnostics.found >= 2, null, {timeout:90000})
  console.log('REACQUIRED'); await new Promise(r=>setTimeout(r,2000)); recording = false; await captureTask; await page.locator('#stop').click()
  await page.waitForFunction(() => window.demoDiagnostics.state === 'Stopped')
} catch(e) {pageErrors.push(e.message); await page.screenshot({path:'evidence/failure.png'})}
recording = false; if(captureTask) await captureTask; const result = {capturedFrames:frameNumber,date:new Date().toISOString(), input:'Generated flat image, translated in synthetic Chromium camera; no physical camera', base, diagnostics:await page.evaluate(()=>window.demoDiagnostics), canvas:await page.locator('#camera').evaluate(c=>({width:c.width,height:c.height,clientWidth:c.clientWidth,clientHeight:c.clientHeight})), consoleErrors,pageErrors,failedRequests:requests}
await writeFile('evidence/browser-verification.json',JSON.stringify(result,null,2)+'\n')
console.log(JSON.stringify(result,null,2))
await context.close()

await browser.close()
if (!result.diagnostics?.found || !result.diagnostics?.lost || result.diagnostics.found < 2 || pageErrors.length || result.diagnostics.errors.length) process.exitCode=1
