import test from 'node:test';
import assert from 'node:assert/strict';
import {BlackEvidenceTracker} from './black-evidence-tracker.mjs';
import {BLACK_ROBUST_BOOK} from './black-line-robust-book.mjs?v=black-20261010-e';
import {BLACK_BCH126_BOOK} from './black-line-bch126-book.mjs?v=black-20261010-e';

const q=(x=0,size=100)=>[[x,0],[x+size,0],[x+size,140],[x,140]];
const all=Array.from({length:16},(_,i)=>i);
const observe=(word,indices=all,x=0)=>({q:q(x),bits:word.bits.map((b,i)=>indices.includes(i)?b:null),conflict:false});
const books=[['robust30',BLACK_ROBUST_BOOK,8,10],['bch126',BLACK_BCH126_BOOK,6,12]];

test('actual dictionary distance and one-error current minimum are computed, not trusted',()=>{
 for(const [,book,d,minimum] of books){const tracker=new BlackEvidenceTracker({book});assert.equal(tracker.minimumDistance,d);assert.equal(tracker.minimumCurrent,minimum);}
});
test('complementary fresh observations recover every registered word, with zero correction and <=3 merged erasures',()=>{
 for(const [,book,,minimum] of books)for(const word of book){
  const tracker=new BlackEvidenceTracker({book}),first=all.slice(0,3),current=all.slice(3,3+minimum);
  assert.equal(tracker.update([observe(word,first)],0)[0].temporalId,null);
  const result=tracker.update([observe(word,current)],500)[0];
  assert.equal(result.temporalId,word.id);assert.equal(result.temporalUsed,true);assert.equal(result.temporalSamples,2);assert.equal(result.temporalKnown,minimum+3);assert.equal(result.temporalAgeMs,500);
 }
});
test('a unique weak current word cannot bypass the normal merged <=3-erasure budget',()=>{
 for(const [,book,,minimum] of books){const t=new BlackEvidenceTracker({book}),word=book[0];assert.equal(t.update([observe(word,all.slice(0,minimum))],0)[0].temporalId,null);assert.equal(t.update([observe(word,all.slice(0,minimum))],1)[0].temporalId,null);}
});
test('all ordered paper swaps at identical geometry reject old IDs, including indistinguishable shared bits',()=>{
 for(const [,book,,minimum] of books)for(const old of book)for(const current of book){if(old.id===current.id)continue;
  const shared=all.filter(i=>old.bits[i]===current.bits[i]),different=all.filter(i=>old.bits[i]!==current.bits[i]);
  const t=new BlackEvidenceTracker({book});t.update([observe(old)],0);
  assert.equal(t.update([observe(current,shared)],100)[0].temporalId,null);
  const known=[...shared,...different.slice(0,minimum-shared.length)],sample=observe(current,known);sample.bits[different[0]]=old.bits[different[0]];
  t.reset();t.update([observe(old)],0);const out=t.update([sample],100)[0];assert.ok(out.temporalId===null||out.temporalId===current.id);
  t.reset();t.update([observe(old)],0);assert.equal(t.update([observe(current)],100)[0].temporalId,current.id);
 }
});
test('the old 9/11-known one-error swap counterexample is rejected for all nearest-word pairs',()=>{
 for(const [,book,d,minimum] of books){let checked=0;for(const old of book)for(const current of book){if(old.id===current.id)continue;
  const shared=all.filter(i=>old.bits[i]===current.bits[i]);if(shared.length!==16-d)continue;
  const different=all.filter(i=>old.bits[i]!==current.bits[i]),sample=observe(current,[...shared,different[0]]);sample.bits[different[0]]=old.bits[different[0]];
  assert.equal(sample.bits.filter(b=>b!==null).length,minimum-1);assert.ok(sample.bits.every((b,i)=>b===null||b===old.bits[i]));
  const t=new BlackEvidenceTracker({book});t.update([observe(old)],0);assert.equal(t.update([sample],100)[0].temporalId,null);checked++;
 }assert.ok(checked>0);}
});
test('distance proof: even one current substitution cannot create enough agreement with any other word',()=>{
 for(const [,book,,minimum] of books)for(const a of book)for(const b of book)if(a.id!==b.id){const shared=all.filter(i=>a.bits[i]===b.bits[i]).length;assert.ok(shared+1<minimum);}
});
test('known contradiction removes all older samples; no majority or corrected detector ID fills a bit',()=>{
 const word=BLACK_ROBUST_BOOK[0],t=new BlackEvidenceTracker();t.update([observe(word)],0);t.update([observe(word)],100);
 const bad=observe(word,all.slice(0,10));bad.bits[0]^=1;bad.id=word.id;
 const out=t.update([bad],200)[0];assert.equal(out.temporalId,null);assert.equal(out.temporalSamples,1);assert.equal(out.temporalKnown,10);
 const corrected=observe(word,all.slice(6));assert.equal(t.update([corrected],300)[0].temporalId,null);
});
test('fresh supplied IDs are consistency checks, never additional bit evidence',()=>{
 const [a,b]=BLACK_ROBUST_BOOK,t=new BlackEvidenceTracker();const out=t.update([{...observe(a),id:b.id}],0)[0];assert.equal(out.temporalId,null);assert.equal(t.tracks.length,0);
 assert.equal(t.update([{...observe(a,all.slice(6)),id:a.id}],100)[0].temporalId,null);
 t.reset();t.update([observe(a)],200);assert.equal(t.update([{...observe(a,all.slice(0,13)),id:a.id}],300)[0].temporalUsed,false);
 assert.equal(t.update([observe(a,all.slice(0,13))],400)[0].temporalUsed,false);
});
test('scene, explicit conflicts, all-null and all-white frames reset historical identity',()=>{
 const word=BLACK_ROBUST_BOOK[0];for(const kind of ['scene','conflict','null','white']){
  const t=new BlackEvidenceTracker();t.update([observe(word,all.slice(0,3))],0);
  if(kind!=='scene')t.update([{...observe(word),...(kind==='conflict'?{conflict:true}:kind==='null'?{bits:Array(16).fill(null)}:{bits:Array(16).fill(0)})}],100);
  const out=t.update([observe(word,all.slice(3,13))],200,{sceneChanged:kind==='scene'})[0];assert.equal(out.temporalId,null);
 }
 const t=new BlackEvidenceTracker();t.update([observe(word)],0);for(let i=1;i<100;i++)assert.equal(t.update([{q:q(),bits:Array(16).fill(null)}],i)[0].temporalId,null);
});
test('no fresh geometry, held observations or invalid observations can keep or restore evidence',()=>{
 const word=BLACK_ROBUST_BOOK[0];for(const missing of [[],[{...observe(word),held:true}],[{...observe(word),fresh:false}],[{q:null,bits:word.bits}],[null]]){
  const t=new BlackEvidenceTracker();t.update([observe(word,all.slice(0,3))],0);t.update(missing,100);assert.equal(t.tracks.length,0);assert.equal(t.update([observe(word,all.slice(3,13))],200)[0].temporalId,null);
 }
 for(const bits of [[],Array(16),Array(15).fill(0),[2,...Array(15).fill(0)],[undefined,...Array(15).fill(0)]]){const t=new BlackEvidenceTracker();t.update([observe(word)],0);assert.equal(t.update([{q:q(),bits}],100)[0].temporalId,null);assert.equal(t.tracks.length,0);}
});
test('TTL expires individual bit samples even when more recent geometry refreshes the track',()=>{
 const word=BLACK_ROBUST_BOOK[0];for(const elapsed of [800,801]){const t=new BlackEvidenceTracker();t.update([observe(word,all.slice(0,3))],0);assert.equal(t.update([observe(word,all.slice(3,13))],elapsed)[0].temporalId,elapsed===800?word.id:null);}
 const t=new BlackEvidenceTracker();t.update([observe(word,all.slice(0,3))],0);t.update([observe(word,[3])],600);const out=t.update([observe(word,all.slice(3,13))],900)[0];assert.equal(out.temporalId,null);assert.equal(out.temporalKnown,10);
});
test('backwards or duplicate timestamps and invalid time cannot replay prior bits',()=>{
 const word=BLACK_ROBUST_BOOK[0];for(const now of [100,99]){const t=new BlackEvidenceTracker();t.update([observe(word,all.slice(0,3))],100);assert.equal(t.update([observe(word,all.slice(3,13))],now)[0].temporalId,null);}
 const t=new BlackEvidenceTracker();t.update([observe(word)],0);assert.throws(()=>t.update([],NaN),TypeError);assert.equal(t.tracks.length,0);assert.throws(()=>t.update(null,100),TypeError);
});
test('adjacent papers stay independent despite input-order changes and cyclic corner ordering',()=>{
 const [a,b]=BLACK_ROBUST_BOOK,t=new BlackEvidenceTracker();t.update([observe(a,all.slice(0,3),0),observe(b,all.slice(0,3),110)],0);
 const left=observe(a,all.slice(3,13),0);left.q=[left.q[2],left.q[1],left.q[0],left.q[3]];
 const out=t.update([observe(b,all.slice(3,13),110),left],100);assert.deepEqual(out.map(o=>o.temporalId),[b.id,a.id]);
});
test('strict mutual one-to-one rejects duplicated, many-to-one and one-to-many geometry',()=>{
 const word=BLACK_ROBUST_BOOK[0],first=all.slice(0,3),current=all.slice(3,13);
 for(const [old,now] of [[[observe(word,first)],[observe(word,current),observe(word,current)]],[[observe(word,first,0),observe(word,first,8)],[observe(word,current,4)]],[[observe(word,first,0),observe(word,first,20)],[observe(word,current,0),observe(word,current,10)]]]){
  const t=new BlackEvidenceTracker();t.update(old,0);assert.ok(t.update(now,100).every(o=>o.temporalId===null));
 }
});
test('distance, size, degeneracy and nonfinite corner guards fail closed',()=>{
 const word=BLACK_ROBUST_BOOK[0];for(const quad of [q(13),q(0,130),[[0,0],[0,0],[100,140],[0,140]],[[0,0],[100,0],[50,10],[0,140]],[[0,0],[100,0],[100,140],[NaN,140]],Array(4)]){
  const t=new BlackEvidenceTracker();t.update([observe(word,all.slice(0,3))],0);assert.equal(t.update([{...observe(word,all.slice(3,13)),q:quad}],100)[0].temporalId,null);
 }
});
test('book switching, content mutations and explicit reader revisions clear samples',()=>{
 const word=BLACK_ROBUST_BOOK[0],book=BLACK_ROBUST_BOOK.map(w=>({...w,bits:w.bits.slice()}));
 const t=new BlackEvidenceTracker({book});t.update([observe(word,all.slice(0,3))],0);book[0].id='renamed';assert.equal(t.update([observe(word,all.slice(3,13))],100)[0].temporalId,null);
 t.reset();t.update([observe(word,all.slice(0,3))],200);assert.equal(t.update([observe(word,all.slice(3,13))],300,{revision:'orientation-v2'})[0].temporalId,null);
 t.reset();t.update([observe(word,all.slice(0,3))],310);for(const w of book)w.bits[0]^=1;
 assert.equal(t.update([observe(book[0],all.slice(3,13))],320)[0].temporalId,null);
 t.reset();t.update([observe(word,all.slice(0,3))],400);t.setBook(BLACK_BCH126_BOOK,{revision:'capacity-v1'});assert.equal(t.minimumCurrent,12);assert.equal(t.update([observe(word,all.slice(3,15))],500)[0].temporalId,null);
});
test('sample memory is bounded and caller-owned bits/geometry are not retained by reference',()=>{
 const word=BLACK_ROBUST_BOOK[0],t=new BlackEvidenceTracker(),sample=observe(word,all.slice(0,3));t.update([sample],0);sample.bits.fill(null);sample.q[0][0]=999;
 assert.equal(t.update([observe(word,all.slice(3,13))],100)[0].temporalId,word.id);
 for(let now=101;now<201;now++)t.update([observe(word)],now);assert.equal(t.tracks[0].samples.length,32);
});
test('constructor and malformed dictionaries reject unsafe settings',()=>{
 for(const options of [{windowMs:801},{windowMs:0},{windowMs:NaN},{maxDistanceRatio:.21},{maxSizeRatio:1.6},{revision:{}},{book:[]},{book:[BLACK_ROBUST_BOOK[0],BLACK_ROBUST_BOOK[0]]},{book:[{id:'blank',bits:Array(16).fill(0)},BLACK_ROBUST_BOOK[0]]}])assert.throws(()=>new BlackEvidenceTracker(options));
 const book=BLACK_ROBUST_BOOK.map(w=>({...w,bits:w.bits.slice()})),t=new BlackEvidenceTracker({book});t.update([observe(book[0])],0);book[0].bits[0]=null;assert.throws(()=>t.update([],100),TypeError);assert.equal(t.tracks.length,0);
 const invalidRevision=new BlackEvidenceTracker();invalidRevision.update([observe(BLACK_ROBUST_BOOK[0])],0);assert.throws(()=>invalidRevision.update([],100,{revision:{}}),TypeError);assert.equal(invalidRevision.tracks.length,0);
});
