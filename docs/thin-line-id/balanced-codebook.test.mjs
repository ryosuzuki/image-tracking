import test from 'node:test';
import assert from 'node:assert/strict';
import {BALANCED_CODEBOOK as book} from './balanced-codebook.mjs?v=iter-20261010-a';
const matches=symbols=>book.filter(c=>symbols.every((x,i)=>x===null||x===c.symbols[i]));
const distance=(a,b)=>a.reduce((s,x,i)=>s+(x!==b[i]),0);
const masks=[[],...Array.from({length:7},(_,i)=>[i]),...Array.from({length:7},(_,i)=>Array.from({length:6-i},(_,j)=>[i,i+j+1])).flat()];
test('30 unique all-color checksum-valid bounded-run words at distance4',()=>{
 assert.equal(book.length,30);assert.equal(new Set(book.map(c=>c.id)).size,30);
 for(const [index,c] of book.entries()){
  assert.equal(c.id,`paper-${String(index+1).padStart(3,'0')}`);assert.equal(c.symbols.length,7);
  assert.equal(new Set(c.symbols).size,4);
  assert.equal(c.symbols[6],c.symbols.slice(0,6).reduce((s,x,k)=>s+x*(k%2?3:1),0)%4);
  assert.ok(!c.symbols.some((x,i)=>i>=2&&x===c.symbols[i-1]&&x===c.symbols[i-2]));
  for(const other of book.slice(index+1))assert.ok(distance(c.symbols,other.symbols)>=4);
 }
});
test('every single and double erasure identifies original uniquely',()=>{
 for(const c of book)for(const mask of masks){const symbols=c.symbols.map((x,i)=>mask.includes(i)?null:x);assert.deepEqual(matches(symbols).map(m=>m.id),[c.id]);}
});
test('one substituted color plus zero/one/two erasures never matches a wrong paper',()=>{
 let cases=0;
 for(const c of book)for(let position=0;position<7;position++)for(let color=0;color<4;color++){
  if(color===c.symbols[position])continue;
  for(const mask of masks){if(mask.includes(position))continue;
   const symbols=c.symbols.map((x,i)=>mask.includes(i)?null:i===position?color:x);
   assert.equal(matches(symbols).length,0,`${c.id} position ${position}, color ${color}, erasures ${mask}`);cases++;
  }
 }
 assert.equal(cases,13860);
});
