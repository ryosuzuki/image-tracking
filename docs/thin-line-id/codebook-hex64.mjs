// Opt-in capacity experiment: six-symbol GF(4) hexacode plus the existing
// integer-mod-4 weighted check. The resulting seven-symbol dictionary has
// minimum Hamming distance 4. This does not improve optical readability.
// All 64 words are retained, including monochrome words; blank-page/color
// calibration rejection is essential. Requiring all four colors and no
// three equal consecutive symbols leaves 42 words, not 64.
export function multiplyGF4(a,b){
 let result=0;
 for(;b;b>>=1){if(b&1)result^=a;a<<=1;if(a&4)a^=7;}
 return result&3;
}
export function generateHex64(){
 const words=[];
 for(let a=0;a<4;a++)for(let b=0;b<4;b++)for(let c=0;c<4;c++){
  const symbols=[a,b,c,a^b^c,a^multiplyGF4(2,b)^multiplyGF4(3,c),a^multiplyGF4(3,b)^multiplyGF4(2,c)];
  symbols.push(symbols.reduce((sum,x,i)=>sum+x*(i%2?3:1),0)%4);
  words.push({id:`paper-${String(words.length+1).padStart(3,'0')}`,symbols});
 }
 return words;
}
export const CODEBOOK_HEX64=generateHex64();
