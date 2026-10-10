// Experimental explicit-dictionary scheme, not the seven-slot checksum scheme.
// Enumerate every 4^8 word; all four colors and no run longer than two.
// Deterministic greedy max-min Hamming selection with total-distance tie-break,
// then lowest enumeration index. No device/default integration is implied.
const distance=(a,b)=>a.reduce((sum,x,i)=>sum+(x!==b[i]),0);
const candidates=[];
for(let n=0;n<65536;n++){
 const symbols=Array.from({length:8},(_,i)=>(n>>(2*i))&3);
 if(new Set(symbols).size===4&&!symbols.some((x,i)=>i>=2&&x===symbols[i-1]&&x===symbols[i-2]))candidates.push({n,symbols});
}
const chosen=[candidates[0]];let pool=candidates.slice(1);
while(chosen.length<30){
 pool=pool.filter(c=>distance(c.symbols,chosen.at(-1).symbols)>=5);
 let best=null,bestScore=-Infinity;
 for(const c of pool){const distances=chosen.map(d=>distance(c.symbols,d.symbols));const score=Math.min(...distances)*1000+distances.reduce((sum,x)=>sum+x,0);if(score>bestScore){best=c;bestScore=score;}}
 if(!best)throw new Error('Eight-symbol dictionary could not reach 30 words');
 chosen.push(best);pool=pool.filter(c=>c!==best);
}
export const CODEBOOK_EIGHT=Object.freeze(chosen.map((c,i)=>Object.freeze({id:`paper-${String(i+1).padStart(3,'0')}`,symbols:Object.freeze(c.symbols.slice())})));
export const EIGHT_CANDIDATE_COUNT=candidates.length;
// Null denotes a known erasure; observed colors are never corrected or guessed.
// At distance 5: a substitution plus <=3 erased positions cannot match a
// different word, since such a match would imply distance <=1+3=4.
export function decodeObservedEight(symbols){
 if(!Array.isArray(symbols)||symbols.length!==8||Array.from(symbols).some(x=>x!==null&&(!Number.isInteger(x)||x<0||x>3))||symbols.filter(x=>x===null).length>3)return null;
 const matches=CODEBOOK_EIGHT.filter(c=>symbols.every((x,i)=>x===null||x===c.symbols[i]));
 return matches.length===1?matches[0]:null;
}
