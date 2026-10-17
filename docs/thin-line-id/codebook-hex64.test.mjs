import test from 'node:test';
import assert from 'node:assert/strict';
import {CODEBOOK_HEX64,generateHex64,multiplyGF4} from './codebook-hex64.mjs';
const distance=(a,b)=>a.reduce((n,x,i)=>n+(x!==b[i]),0);
const matches=observed=>CODEBOOK_HEX64.filter(word=>observed.every((v,i)=>v===null||v===word.symbols[i]));
const popcount=n=>n.toString(2).replaceAll('0','').length;
test('GF4 multiplication table and deterministic 64 IDs',()=>{
 assert.deepEqual(Array.from({length:4},(_,a)=>Array.from({length:4},(_,b)=>multiplyGF4(a,b))),[[0,0,0,0],[0,1,2,3],[0,2,3,1],[0,3,1,2]]);
 assert.deepEqual(generateHex64(),CODEBOOK_HEX64);
 assert.equal(CODEBOOK_HEX64.length,64);
 assert.equal(new Set(CODEBOOK_HEX64.map(w=>w.symbols.join(''))).size,64);
 CODEBOOK_HEX64.forEach((w,i)=>assert.equal(w.id,`paper-${String(i+1).padStart(3,'0')}`));
});
test('seven valid colors, compatible weighted checksum, exact distance 4',()=>{
 let minimum=7;
 for(const [i,w] of CODEBOOK_HEX64.entries()){
  assert.equal(w.symbols.length,7);
  assert.ok(w.symbols.every(v=>Number.isInteger(v)&&v>=0&&v<4));
  assert.equal(w.symbols[6],w.symbols.slice(0,6).reduce((sum,x,k)=>sum+x*(k%2?3:1),0)%4);
  for(let j=0;j<i;j++)minimum=Math.min(minimum,distance(w.symbols,CODEBOOK_HEX64[j].symbols));
 }
 assert.equal(minimum,4);
});
test('all known erasures through three positions uniquely identify the original',()=>{
 let count=0;
 for(const w of CODEBOOK_HEX64)for(let mask=0;mask<128;mask++){
  if(popcount(mask)>3)continue;
  const observed=w.symbols.map((v,i)=>mask>>i&1?null:v);
  assert.deepEqual(matches(observed).map(x=>x.id),[w.id]);count++;
 }
 assert.equal(count,4096);
});
test('one wrong observed color with at most two erasures is always rejected',()=>{
 let count=0;
 for(const w of CODEBOOK_HEX64)for(let position=0;position<7;position++)for(let color=0;color<4;color++){
  if(color===w.symbols[position])continue;
  for(let mask=0;mask<128;mask++){
   if(mask>>position&1||popcount(mask)>2)continue;
   const observed=w.symbols.map((v,i)=>mask>>i&1?null:(i===position?color:v));
   assert.equal(matches(observed).length,0);count++;
  }
 }
 assert.equal(count,29568);
});
test('appearance subset has 42 words; full capacity includes monochrome risk',()=>{
 const acceptable=CODEBOOK_HEX64.filter(({symbols:w})=>new Set(w).size===4&&!w.some((v,i)=>i>=2&&v===w[i-1]&&v===w[i-2]));
 assert.equal(acceptable.length,42);
 assert.ok(CODEBOOK_HEX64.some(w=>w.symbols.every(v=>v===0)));
});
