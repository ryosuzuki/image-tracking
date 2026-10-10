// Opt-in 126-ID capacity variant; robust30 remains the default camera dictionary.
// Systematic binary cyclic BCH(15,7,5), generator x^8+x^7+x^6+x^4+1,
// extended by overall even parity to [16,7,6]. Remove constant words.
export const GENERATOR=0x1d1;
export function encodeBCH16(message){
 if(!Number.isInteger(message)||message<0||message>=128)throw new RangeError('Seven-bit message required');
 const shifted=message<<8;let remainder=shifted;
 for(let position=14;position>=8;position--)if(remainder>>position&1)remainder^=GENERATOR<<(position-8);
 const code=shifted|remainder,bits=Array.from({length:15},(_,i)=>code>>i&1);bits.push(bits.reduce((parity,b)=>parity^b,0));return bits;
}
export const BCH126_BOOK=Array.from({length:128},(_,message)=>({message,bits:encodeBCH16(message)})).filter(w=>w.bits.some(b=>b===0)&&w.bits.some(b=>b===1)).map((w,i)=>({...w,id:`paper-${String(i+1).padStart(3,'0')}`}));
export const BCH126_WEIGHT8=BCH126_BOOK.filter(w=>w.bits.reduce((a,b)=>a+b)===8);

const COLUMN_PERMUTATION=[5,2,15,8,0,4,10,6,3,9,11,7,12,13,14,1];
import {BLACK_ROBUST_BOOK} from './black-line-robust-book.mjs?v=black-20261010-h';
const transformed=BCH126_BOOK.map(w=>({...w,bits:COLUMN_PERMUTATION.map(i=>w.bits[i])})),keys=new Set(BLACK_ROBUST_BOOK.map(w=>w.bits.join('')));
const preserved=BLACK_ROBUST_BOOK.map(w=>{const found=transformed.find(x=>x.bits.join('')===w.bits.join(''));if(!found)throw Error('Existing robust30 pattern missing from BCH dictionary');return found;});
export const BLACK_BCH126_BOOK=[...preserved,...transformed.filter(w=>!keys.has(w.bits.join('')))].map((w,i)=>({...w,id:`paper-${String(i+1).padStart(3,'0')}`}));
export const BLACK_BCH126_OPTIONS={book:BLACK_BCH126_BOOK,minDistance:6,maxErrors:1,maxErasures:3};
