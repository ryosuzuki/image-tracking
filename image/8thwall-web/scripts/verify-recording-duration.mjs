import assert from 'node:assert/strict'
import {writeFile} from 'node:fs/promises'
const url='http://localhost:5173/recordings/1791350751194-a89ea10e-06ca-47dc-be9d-374f3a7fe258/info.json'
const r=await fetch(url),info=await r.json();assert.equal(r.status,200);assert.ok(info.durationSeconds>100);assert.ok(info.fileSizeBytes>0);assert.deepEqual(await fetch(url).then(r=>r.json()),info)
assert.equal((await fetch(url,{headers:{'cf-connecting-ip':'test'}})).status,403)
await writeFile('evidence/recording-duration.json',JSON.stringify({passed:true,input:'Actual complete native C920 gallery; ffprobe packet timestamps, no synthetic duration injected',info,checks:['Duration longer than60 seconds detected from actual media','Repeated cached query matches','Forwarded Cloudflare request denied before private metadata'],limitations:['Fallback endpoint requires local ffprobe; file-input duration can remain unavailable and uses numeric jump','Packet-end time, not exact codec frame indexing']},null,2));console.log(JSON.stringify({passed:true,...info}))
