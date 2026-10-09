import assert from 'node:assert/strict'
import {readFile,writeFile} from 'node:fs/promises'
const session=`lifecycle-${Date.now()}`,base='http://localhost:5173',startedUnixMs=Date.now()
const post=async(path,data)=>{const r=await fetch(base+path,{method:'POST',body:JSON.stringify(data)});assert.equal(r.status,200)}
await post(`/api/captures/${session}/meta.json`,{session,startedUnixMs})
await post('/api/presenter-event',{target:'original-01',number:1,unixMs:Date.now(),intervalSeconds:5})
const endedUnixMs=Date.now()
await post(`/api/captures/${session}/end.json`,{session,endedUnixMs})
await post('/api/presenter-event',{target:'original-02',number:2,unixMs:Date.now(),intervalSeconds:5})
const events=(await readFile(`../../work/captures/${session}/events.jsonl`,'utf8')).trim().split('\n').map(JSON.parse)
assert.equal(events.length,1);assert.equal(events[0].target,'original-01')
assert.equal(JSON.parse(await readFile(`../../work/captures/${session}/end.json`)).endedUnixMs,endedUnixMs)
await writeFile('evidence/capture-lifecycle.json',JSON.stringify({passed:true,session,beforeEndEvents:1,afterEndEvents:0},null,2));console.log('Capture end prevents further presenter events')
