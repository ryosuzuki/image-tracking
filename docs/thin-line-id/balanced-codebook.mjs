// Experimental dictionary only: does not replace color-code.mjs CODEBOOK.
// Exhaust all 4^6 data words, append the existing weighted mod-4 checksum,
// require every color and no three consecutive identical symbols. A finite
// deterministic multi-start greedy search favors distance and color diversity.
const distance=(a,b)=>a.reduce((s,x,i)=>s+(x!==b[i]),0);
const candidates=[];
for(let n=0;n<4096;n++){
 const symbols=Array.from({length:6},(_,k)=>(n>>(2*k))&3);
 symbols.push(symbols.reduce((s,x,k)=>s+x*(k%2?3:1),0)%4);
 if(new Set(symbols).size!==4||symbols.some((x,i)=>i>=2&&x===symbols[i-1]&&x===symbols[i-2]))continue;
 candidates.push({n,symbols});
}
function generate(seed){
 const chosen=[candidates[(seed*79)%candidates.length]];
 const counts=Array.from({length:7},()=>[0,0,0,0]);
 const add=c=>c.symbols.forEach((x,i)=>counts[i][x]++);
 add(chosen[0]);let pool=candidates.filter(c=>c!==chosen[0]);
 while(chosen.length<30){
  pool=pool.filter(c=>distance(c.symbols,chosen.at(-1).symbols)>=4);
  let best=null,bestScore=-Infinity;
  for(const c of pool){
   const distances=chosen.map(other=>distance(c.symbols,other.symbols));
   const score=Math.min(...distances)*10000-c.symbols.reduce((s,x,i)=>s+counts[i][x],0)*30+distances.reduce((s,x)=>s+x,0);
   if(score>bestScore){best=c;bestScore=score;}
  }
  if(!best)break;chosen.push(best);add(best);pool=pool.filter(c=>c!==best);
 }
 return {chosen,imbalance:counts.flat().reduce((s,n)=>s+n*n,0)};
}
let best=null;
for(let seed=0;seed<32;seed++){
 const result=generate(seed);
 if(result.chosen.length===30&&(!best||result.imbalance<best.imbalance))best=result;
}
if(!best)throw new Error('Balanced codebook search failed to reach 30 entries');
export const BALANCED_CODEBOOK=Object.freeze(best.chosen.map((c,i)=>Object.freeze({id:`paper-${String(i+1).padStart(3,'0')}`,symbols:Object.freeze(c.symbols.slice())})));
