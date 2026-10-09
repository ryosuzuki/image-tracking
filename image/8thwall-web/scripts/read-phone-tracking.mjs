import {writeFile} from 'node:fs/promises'
const tabs=await fetch('http://localhost:9222/json/list').then(r=>r.json())
const tab=tabs.find(t=>t.url.includes('127.0.0.1:5173')||t.url.includes('accuracy-talented-singles-place.trycloudflare.com'))
if(!tab)throw Error('Phone demo tab missing')
const ws=new WebSocket(tab.webSocketDebuggerUrl);await new Promise((r,j)=>{ws.onopen=r;ws.onerror=j})
let id=0;const pending=new Map()
ws.onmessage=e=>{const m=JSON.parse(e.data);if(m.id){const p=pending.get(m.id);pending.delete(m.id);m.error?p?.reject(Error(JSON.stringify(m.error))):p?.resolve(m.result)}}
function call(method,params={}){return new Promise((resolve,reject)=>{const n=++id;pending.set(n,{resolve,reject});ws.send(JSON.stringify({id:n,method,params}));setTimeout(()=>{if(pending.has(n)){pending.delete(n);reject(Error(`Timeout ${method}`))}},15000).unref()})}
async function evaluate(expression){const r=await call('Runtime.evaluate',{expression,returnByValue:true,awaitPromise:true});if(r.exceptionDetails)throw Error(JSON.stringify(r.exceptionDetails));return r.result.value}
const samples=[]
for(let i=0;i<3;i++){samples.push(await evaluate(`({status:document.querySelector('#status').textContent,diagnostics:window.demoDiagnostics,frames:window.phoneFrameCheck})`)); await new Promise(r=>setTimeout(r,1000))}
console.log(JSON.stringify(samples.map(s=>({status:s.status,found:s.diagnostics.found,updated:s.diagnostics.updated,lost:s.diagnostics.lost,frames:s.frames,pose:s.diagnostics.pose})),null,2))
await writeFile('evidence/physical-phone-tracking.json',JSON.stringify({date:new Date().toISOString(),device:'USB-connected Pixel 8 Pro',url:tab.url,input:'Physical back camera looking at the target on the Mac display; no synthetic camera',samples},null,2)+'\n')
ws.close()
