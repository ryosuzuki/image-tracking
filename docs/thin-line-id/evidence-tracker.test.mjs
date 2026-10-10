import test from 'node:test';
import assert from 'node:assert/strict';
import {EvidenceTracker} from './evidence-tracker.mjs?v=iter-20261010-f';
import {CODEBOOK,setCodebook} from './color-code.mjs?v=iter-20261010-f';
setCodebook('balanced');
const q=(x=0,size=100)=>[[x,0],[x+size,0],[x+size,140],[x,140]];
const obs=(item,indices,x=0)=>({q:q(x),symbols:item.symbols.map((v,i)=>indices.includes(i)?v:null),conflict:false});
const a=CODEBOOK[0],b=CODEBOOK.find(c=>c.symbols[0]!==a.symbols[0]);
test('complementary fresh partial observations recover a unique code',()=>{
 const t=new EvidenceTracker();assert.equal(t.update([obs(a,[0,1,2])],0)[0].temporalId,null);
 assert.equal(t.update([obs(a,[3,4,5,6])],200)[0].temporalId,a.id);
});
test('conflicting colors discard all older evidence and never decode old paper',()=>{
 const t=new EvidenceTracker();t.update([obs(a,[0,1,2,3,4,5,6])],0);
 assert.equal(t.update([obs(b,[0])],100)[0].temporalId,null);
 assert.equal(t.update([obs(b,[1,2,3,4,5,6])],200)[0].temporalId,b.id);
});
test('explicit conflict and scene change break partial history',()=>{
 for(const scene of [true,false]){const t=new EvidenceTracker();t.update([obs(a,[0,1,2])],0);
 if(!scene)t.update([{...obs(a,[0]),conflict:true}],100);
 assert.equal(t.update([obs(a,[3,4,5,6])],200,{sceneChanged:scene})[0].temporalId,null);}
});
test('evidence expires independently of refreshed geometry',()=>{
 const t=new EvidenceTracker();t.update([obs(a,[0,1,2])],0);t.update([obs(a,[3])],600);
 assert.equal(t.update([obs(a,[4,5,6])],900)[0].temporalId,null);
 const slow=new EvidenceTracker({windowMs:2500});slow.update([obs(a,[0,1,2])],0);
 assert.equal(slow.update([obs(a,[3,4,5,6])],1100)[0].temporalId,a.id);
 assert.throws(()=>new EvidenceTracker({windowMs:2501}),RangeError);
});
test('adjacent papers maintain independent geometry evidence despite reversed input order',()=>{
 const t=new EvidenceTracker();t.update([obs(a,[0,1,2],0),obs(b,[0,1,2],110)],0);
 const result=t.update([obs(b,[3,4,5,6],110),obs(a,[3,4,5,6],0)],100);
 assert.deepEqual(result.map(o=>o.temporalId),[b.id,a.id]);
});
test('blank evidence and disappearance prevent stale identity on a position swap',()=>{
 for(const blank of [[],[{q:q(),symbols:Array(7).fill(null)}]]){const t=new EvidenceTracker();t.update([obs(a,[0,1,2,3,4,5,6])],0);t.update(blank,50);
 assert.equal(t.update([obs(b,[3,4,5,6])],100)[0].temporalId,null);}
 const t=new EvidenceTracker();t.update([obs(a,[0,1,2,3,4,5,6])],0);
 for(let now=1;now<10;now++)assert.equal(t.update([{q:q(),symbols:Array(7).fill(null)}],now)[0].temporalId,null);
});
test('large jumps, scale changes and ambiguous association cannot combine evidence',()=>{
 for(const geometry of [q(20),q(0,130)]){const t=new EvidenceTracker();t.update([obs(a,[0,1,2])],0);assert.equal(t.update([{...obs(a,[3,4,5,6]),q:geometry}],100)[0].temporalId,null);}
 const t=new EvidenceTracker();t.update([obs(a,[0,1,2],0),obs(a,[0,1,2],8)],0);
 assert.equal(t.update([obs(a,[3,4,5,6],4)],100)[0].temporalId,null);
});
test('backwards time, explicit ID change and duplicate detections reset association',()=>{
 const t=new EvidenceTracker();t.update([obs(a,[0,1,2])],100);assert.equal(t.update([obs(a,[3,4,5,6])],0)[0].temporalId,null);
 t.reset();t.update([{...obs(a,[0,1,2,3,4,5,6]),id:a.id}],0);
 assert.equal(t.update([{...obs(a,[3,4,5,6]),id:b.id}],100)[0].temporalId,null);
 t.reset();t.update([obs(a,[0,1,2])],0);assert.deepEqual(t.update([obs(a,[3,4,5,6]),obs(a,[3,4,5,6])],100).map(o=>o.temporalId),[null,null]);
});

test('eight-slot temporal fusion, color conflict and book switching are bounded',async()=>{
 const {setCodebook}=await import('./color-code.mjs?v=iter-20261010-f');
 setCodebook('eight');const item=CODEBOOK[0],t=new EvidenceTracker();
 assert.equal(t.update([obs(item,[0,1,2,3])],0)[0].temporalId,null);
 assert.equal(t.update([obs(item,[4,5,6,7])],100)[0].temporalId,item.id);
 const wrong={...obs(item,[0]),symbols:[(item.symbols[0]+1)%4,null,null,null,null,null,null,null]};
 assert.equal(t.update([wrong],200)[0].temporalId,null);
 t.reset();t.update([obs(item,[0,1,2,3])],0);setCodebook('balanced');setCodebook('eight');
 assert.equal(t.update([obs(item,[4,5,6,7])],50)[0].temporalId,null);
 setCodebook('original');assert.equal(t.update([obs(CODEBOOK[0],[3,4,5,6])],100)[0].temporalId,null);
 setCodebook('eight');assert.equal(t.update([obs(item,[4,5,6,7])],200)[0].temporalId,null);setCodebook();
});

test('weak current colors cannot keep an old ID after an indistinguishable partial swap',async()=>{
 const {setCodebook}=await import('./color-code.mjs?v=iter-20261010-f');
 for(const kind of ['original','balanced','eight']){setCodebook(kind);const first=CODEBOOK[0],second=CODEBOOK.find(c=>c.id!==first.id),common=second.symbols.flatMap((v,i)=>v===first.symbols[i]?[i]:[]),t=new EvidenceTracker();t.update([obs(first,first.symbols.map((_,i)=>i))],0);assert.equal(t.update([obs(second,common)],100)[0].temporalId,null,kind);}
 setCodebook();
});
