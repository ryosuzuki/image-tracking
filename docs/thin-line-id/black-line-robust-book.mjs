import {BLACK_LINE_BOOK} from './black-line-code.mjs?v=black-20261010-f';
const distance=(a,b)=>a.reduce((n,v,i)=>n+(v!==b[i]),0),selected=[];
for(const word of BLACK_LINE_BOOK)if(selected.every(other=>distance(word.bits,other.bits)>=8))selected.push(word);
if(selected.length!==30)throw Error('Robust black-line dictionary must contain 30 words');
export const BLACK_ROBUST_BOOK=selected.map((word,i)=>({id:`paper-${String(i+1).padStart(3,'0')}`,bits:word.bits.slice()}));
export const BLACK_ROBUST_OPTIONS={book:BLACK_ROBUST_BOOK,minDistance:8,maxErrors:1,maxErasures:3};
