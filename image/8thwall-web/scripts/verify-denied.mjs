import {chromium} from 'playwright'
import {writeFile} from 'node:fs/promises'
const base = process.env.DEMO_URL || 'http://localhost:5173'
const browser = await chromium.launch({headless:true,args:['--use-fake-device-for-media-stream','--use-angle=swiftshader','--enable-unsafe-swiftshader']})
const context = await browser.newContext({ignoreHTTPSErrors:true})
const page = await context.newPage()
const session = await context.newCDPSession(page)
await session.send('Browser.setPermission', {permission:{name:'camera'},setting:'denied',origin:base})
await page.goto(base)
await page.waitForFunction(()=>window.demoDiagnostics?.engineLoaded,null,{timeout:30000})
await page.locator('#start').click()
await page.waitForFunction(()=>window.demoDiagnostics?.errors.length > 0,null,{timeout:15000})
const result = await page.evaluate(()=>({text:document.body.innerText,diagnostics:window.demoDiagnostics}))
await writeFile('evidence/permission-denied.json', JSON.stringify(result,null,2)+'\n')
await page.screenshot({path:'evidence/permission-denied.png'})
console.log(JSON.stringify(result,null,2))
await browser.close()
if (!result.text.includes('browser settings') || result.diagnostics.cameraStarted) process.exitCode=1
