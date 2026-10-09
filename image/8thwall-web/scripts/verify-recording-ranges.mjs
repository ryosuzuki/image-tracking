import assert from 'node:assert/strict'
import {readFile,writeFile} from 'node:fs/promises'
const url='http://localhost:5173/recordings/body-motion-official-fixture/raw.webm',local=await readFile('../../work/captures/body-motion-official-fixture/raw.webm')
for(const [range,start,end]of [['bytes=10-99',10,99],['bytes=-100',local.length-100,local.length-1]]){const r=await fetch(url,{headers:{Range:range}});assert.equal(r.status,206);assert.deepEqual(Buffer.from(await r.arrayBuffer()),local.subarray(start,end+1));assert.equal(r.headers.get('content-range'),`bytes ${start}-${end}/${local.length}`)}
for(const range of ['bytes=999999999-','bytes=100-10','bytes=-0','bytes=0-9,10-19'])assert.equal((await fetch(url,{headers:{Range:range}})).status,416)
assert.equal((await fetch(url,{headers:{'cf-connecting-ip':'test',Range:'bytes=0-9'}})).status,403)
await writeFile('evidence/recording-ranges.json',JSON.stringify({passed:true,checks:['Exact bounded byte content and Content-Range','Exact suffix byte content','Out-of-range, reversed, empty suffix, multipart rejected','Cloudflare-forwarded request blocked before range response'],input:'Official moving-video composite file stored on localhost'},null,2));console.log('Recording range delivery and localhost restriction passed')
