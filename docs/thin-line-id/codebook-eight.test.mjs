import test from 'node:test';
import assert from 'node:assert/strict';
import {CODEBOOK_EIGHT as book,EIGHT_CANDIDATE_COUNT,decodeObservedEight as decode} from './codebook-eight.mjs?v=iter-20261010-f';
const masks=[];for(let bits=0;bits<256;bits++){const mask=Array.from({length:8},(_,i)=>i).filter(i=>bits&(1<<i));if(mask.length<=3)masks.push(mask);}
const distance=(a,b)=>a.reduce((sum,x,i)=>sum+(x!==b[i]),0);
test('30 distinct eight-symbol all-color bounded-run dictionary words have distance5',()=>{
 assert.equal(book.length,30);assert.equal(EIGHT_CANDIDATE_COUNT,32808);
 assert.equal(new Set(book.map(c=>c.symbols.join(''))).size,30);
 for(const [i,c] of book.entries()){
  assert.equal(c.id,`paper-${String(i+1).padStart(3,'0')}`);assert.equal(c.symbols.length,8);assert.equal(new Set(c.symbols).size,4);
  assert.ok(!c.symbols.some((x,k)=>k>=2&&x===c.symbols[k-1]&&x===c.symbols[k-2]));
  for(const d of book.slice(i+1))assert.ok(distance(c.symbols,d.symbols)>=5);
 }
});
test('exhaustive zero through three erasures preserve unique identity',()=>{
 let count=0;for(const c of book)for(const mask of masks){const s=c.symbols.map((x,i)=>mask.includes(i)?null:x);assert.equal(decode(s)?.id,c.id);count++;}
 assert.equal(count,2790);
});
test('exhaustive substitution plus zero through three erasures always reject',()=>{
 let count=0;for(const c of book)for(let position=0;position<8;position++)for(let color=0;color<4;color++){
  if(color===c.symbols[position])continue;
  for(const mask of masks){if(mask.includes(position))continue;const s=c.symbols.map((x,i)=>mask.includes(i)?null:i===position?color:x);assert.equal(decode(s),null);count++;}
 }
 assert.equal(count,46080);
});
test('underobserved or malformed input is never decoded',()=>{
 for(const s of [null,[],book[0].symbols.slice(0,7),[...book[0].symbols.slice(0,4),null,null,null,null],Array(8).fill(null),[NaN,...book[0].symbols.slice(1)],[4,...book[0].symbols.slice(1)],['0',...book[0].symbols.slice(1)],Array(8),Object.assign(Array(8),{0:book[0].symbols[0],1:book[0].symbols[1],2:book[0].symbols[2],3:book[0].symbols[3],4:book[0].symbols[4]})])assert.equal(decode(s),null);
});
