import {writeFile} from 'node:fs/promises'
const tabs=await fetch('http://localhost:9222/json/list').then(r=>r.json())
const tab=tabs.find(t=>t.url.includes('127.0.0.1:5173')||t.url.includes('accuracy-talented-singles-place.trycloudflare.com'))
if(!tab)throw Error('Phone demo tab missing')
const ws=new WebSocket(tab.webSocketDebuggerUrl);await new Promise((r,j)=>{ws.onopen=r;ws.onerror=j})
let id=0;const pending=new Map()
ws.onmessage=e=>{const m=JSON.parse(e.data);if(m.id){const p=pending.get(m.id);pending.delete(m.id);m.error?p?.reject(Error(JSON.stringify(m.error))):p?.resolve(m.result)}}
function call(method,params={}){return new Promise((resolve,reject)=>{const n=++id;pending.set(n,{resolve,reject});ws.send(JSON.stringify({id:n,method,params}));setTimeout(()=>{if(pending.has(n)){pending.delete(n);reject(Error(`Timeout ${method}`))}},15000).unref()})}
async function evaluate(expression){const r=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));return r.result.value}
const expr=`({url:location.href,status:document.querySelector('#status')?.textContent,detail:document.querySelector('#detail')?.textContent,secureContext:isSecureContext,cameraApi:!!navigator.mediaDevices?.getUserMedia,diagnostics:window.demoDiagnostics,ua:navigator.userAgent})`
let before=await evaluate(expr); if(before.secureContext){try {const old=JSON.parse(await (await import('node:fs/promises')).readFile('evidence/physical-phone-runtime.json','utf8'));before=old.before}catch{}} console.log('BEFORE',JSON.stringify(before))
await call('Page.navigate',{url:'https://accuracy-talented-singles-place.trycloudflare.com/'})
let ready
for(let i=0;i<60;i++){await new Promise(r=>setTimeout(r,1000));try{ready=await evaluate(expr);if(ready?.diagnostics?.engineLoaded)break}catch{}}
console.log('HTTPS',JSON.stringify(ready))
let camera
try {
 await call('Browser.setPermission',{permission:{name:'camera'},setting:'granted',origin:'https://accuracy-talented-singles-place.trycloudflare.com'})
 await evaluate(`(()=>{window.phoneFrameCheck={count:0}; XR8.addCameraPipelineModule({name:'usb-camera-frame-check',onProcessGpu:({frameStartResult:f})=>{if(f?.textureWidth && !f.repeatFrame){window.phoneFrameCheck.count++;window.phoneFrameCheck.size={width:f.textureWidth,height:f.textureHeight}}}}); return true})()`)
 await call('Runtime.evaluate',{expression:`document.querySelector('#start').click()`,userGesture:true})
 for(let i=0;i<25;i++){await new Promise(r=>setTimeout(r,1000));camera=await evaluate(`({status:document.querySelector('#status').textContent,detail:document.querySelector('#detail').textContent,diagnostics:window.demoDiagnostics,frames:window.phoneFrameCheck})`);if(camera.frames?.count>30 || camera.diagnostics?.errors.length)break}
 console.log('CAMERA',JSON.stringify(camera))
} catch(error){camera={error:error.message};console.log('CAMERA ERROR',error.message)}
await writeFile('evidence/physical-phone-runtime.json',JSON.stringify({device:'USB-authorized Pixel 8 Pro',before,ready,camera,physicalCameraTrackingVerified:!!camera?.diagnostics?.found},null,2)+'\n')
ws.close()
