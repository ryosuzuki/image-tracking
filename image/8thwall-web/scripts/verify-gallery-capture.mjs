import {readFile,writeFile} from 'node:fs/promises'
import assert from 'node:assert/strict'
import {resolve} from 'node:path'
const session=process.argv[2],stateFile=process.argv[3]
if(!session||!stateFile)throw Error('Usage: node scripts/verify-gallery-capture.mjs SESSION STATE_REPORT')
assert.match(session,/^[a-zA-Z0-9_-]{8,80}$/)
const dir=resolve('../../work/captures',session),meta=JSON.parse(await readFile(resolve(dir,'meta.json'))),state=JSON.parse(await readFile(stateFile)),events=(await readFile(resolve(dir,'events.jsonl'),'utf8')).trim().split('\n').map(JSON.parse)
let end,endBound
try{end=JSON.parse(await readFile(resolve(dir,'end.json'))).macUnixMs;endBound='Explicit capture end.json'}catch{end=state.states.at(-1).unixMs;endBound='Last measured test state; legacy capture predates explicit end.json'}
const switches=events.filter(e=>e.name==='presentertarget'&&e.unixMs<=end).sort((a,b)=>a.unixMs-b.unixMs),base=meta.startedUnixMs+meta.clockOffsetMs
let startIndex=-1
for(let i=0;i+20<switches.length;i++)if(new Set(switches.slice(i,i+20).map(e=>e.target)).size===20){startIndex=i;break}
assert.ok(startIndex>=0,'A complete 20-target cycle with following boundary must exist')
const cycle=switches.slice(startIndex,startIndex+21),rows=cycle.slice(0,20).map((a,i)=>{const b=cycle[i+1],samples=events.filter(e=>['imagefound','imageupdated'].includes(e.name)&&e.macUnixMs>=a.unixMs+250&&e.macUnixMs<b.unixMs);return{target:a.target,number:a.number,startSeconds:(a.unixMs-base)/1000,durationSeconds:(b.unixMs-a.unixMs)/1000,correctFound:samples.filter(e=>e.name==='imagefound'&&e.target===a.target).length,correctUpdates:samples.filter(e=>e.name==='imageupdated'&&e.target===a.target).length,wrongTargetEvents:samples.filter(e=>e.target!==a.target).length}})
const report={session,source:'Native physical C920 camera, compact original-source presenter',nativeResolution:[meta.settings[0].width,meta.settings[0].height],cycleStartSeconds:(cycle[0].unixMs-base)/1000,cycleDurationSeconds:(cycle[20].unixMs-cycle[0].unixMs)/1000,actualPresentedTargets:20,correctRecognizedTargets:rows.filter(r=>r.correctUpdates>0).length,transitionGraceMs:250,wrongTargetEvents:rows.reduce((n,r)=>n+r.wrongTargetEvents,0),rows,errors:state.pageErrors,endBound}
await writeFile('evidence/gallery-c920-complete.json',JSON.stringify(report,null,2));console.log(JSON.stringify({presented:20,recognized:report.correctRecognizedTargets,wrongTargetEvents:report.wrongTargetEvents,duration:report.cycleDurationSeconds}))
