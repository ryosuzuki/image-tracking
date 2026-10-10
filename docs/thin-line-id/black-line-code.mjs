// Standalone opt-in black-line camera prototype, separate from the color reader.
// Extended Hamming [16,11,4], restricted to constant weight 8. Every ID has
// eight black dashes. Blank/all-white is therefore never a valid ID.
export function generateBlackLineBook(){
 const words=[];
 for(let value=0;value<2048;value++){
  const bits=Array(16).fill(0);let data=0;
  for(let p=1;p<=15;p++)if((p&(p-1))!==0)bits[p-1]=(value>>data++)&1;
  for(const parity of [1,2,4,8])for(let p=1;p<=15;p++)if(p&parity)bits[parity-1]^=bits[p-1];
  bits[15]=bits.slice(0,15).reduce((sum,v)=>sum^v,0);
  if(bits.reduce((sum,v)=>sum+v,0)===8)words.push({id:`paper-${String(words.length+1).padStart(3,'0')}`,bits});
 }
 return words;
}
export const BLACK_LINE_BOOK=generateBlackLineBook();
export function decodeBlackBits(observed,{book=BLACK_LINE_BOOK,minDistance=4,maxErrors=Infinity,maxErasures=3}={}){
 if(!Array.isArray(observed)||observed.length!==16||observed.some(v=>v!==null&&v!==0&&v!==1))return null;
 const erasures=observed.filter(v=>v===null).length;
 if(erasures>maxErasures)return null;
 // Unique decoding bound 2*errors + erasures < the declared minimum distance.
 const allowedErrors=Math.min(maxErrors,Math.floor((minDistance-1-erasures)/2)),matches=[];
 for(const word of book){const errors=observed.reduce((n,v,i)=>n+(v!==null&&v!==word.bits[i]),0);if(errors<=allowedErrors)matches.push({...word,errors,erasures});}
 return matches.length===1?matches[0]:null;
}
export function drawBlackLineCard(canvas,index=0,{dual=true,lineHeight=8,lineLength=14,content=true,book=BLACK_LINE_BOOK}={}){
 canvas.width=640;canvas.height=880;const c=canvas.getContext('2d'),word=book[index];c.fillStyle='white';c.fillRect(0,0,640,880);c.strokeStyle='black';c.lineWidth=20;
 for(const [x,y,s,t] of [[25,25,1,1],[615,25,-1,1],[615,855,-1,-1],[25,855,1,-1]]){c.beginPath();c.moveTo(x+s*60,y);c.lineTo(x,y);c.lineTo(x,y+t*60);c.stroke();}
 c.fillStyle='black';for(const base of dual?[0,750]:[0]){c.fillRect(76,51+base,14,24);c.fillRect(534,56+base,8,14);word.bits.forEach((bit,i)=>{if(bit)c.fillRect(130+i*348/15-lineLength/2,63+base-lineHeight/2,lineLength,lineHeight);});}
 if(content){c.font='30px sans-serif';c.textAlign='center';c.fillText(word.id,320,175);c.font='20px sans-serif';c.fillText('BLACK LINE ID — prototype',320,230);}
 return canvas;
}
// Exact-arithmetic reader: bounded scratch reuse, no pixel quantization.
const readerScratchPool=[];
function medianInPlace(a,n){const k=Math.floor(n/2);let lo=0,hi=n-1;while(lo<hi){const pivot=a[(lo+hi)>>1];let i=lo,j=hi;while(i<=j){while(a[i]<pivot)i++;while(a[j]>pivot)j--;if(i<=j){const temporary=a[i];a[i]=a[j];a[j]=temporary;i++;j--;}}if(k<=j)hi=j;else if(k>=i)lo=i;else break;}return a[k];}
export function observeBlackLine(canvas,{useBottom=true,minOne=.055,maxZero=.025,orientationRatio=.5}={}){
 if(!Number.isFinite(orientationRatio)||orientationRatio<.3||orientationRatio>.85)throw new RangeError('orientationRatio must be finite and between .3 and .85');
 const c=canvas.getContext('2d'),scratch=readerScratchPool.pop()??{luma:new Float64Array(480*48),select:new Float64Array(430*48)},luma=scratch.luma,select=scratch.select;
 try{
  const inspect=base=>{
   const data=c.getImageData(70,42+base,480,48).data;
   for(let i=0,k=0;i<luma.length;i++,k+=4)luma[i]=.2126*data[k]+.7152*data[k+1]+.0722*data[k+2];
   let n=0;for(let row=0;row<48;row++)for(let col=30;col<460;col++)select[n++]=luma[row*480+col];
   const white=medianInPlace(select,n);if(white<25)return null;
   const dark=(x0,x1)=>{for(let x=x0;x<=x1;x+=2)for(let y=49;y<=76;y+=2){let sum=0;for(let row=0;row<3;row++)for(let col=0;col<3;col++)sum+=luma[(y-42+row)*480+x-70+col];if(sum/9<white*orientationRatio)return true;}return false;};
   if(!dark(72,88)||!dark(528,542))return null;
   return Array.from({length:16},(_,i)=>{
    const left=Math.round(130+i*348/15-9)-70;let count=0;
    for(let row=0;row<48;row++)for(let col=0;col<18;col++)select[count++]=luma[row*480+left+col];
    const paper=medianInPlace(select,count);if(paper<25)return null;
    // Read original row-major luma, NOT the partitioned median scratch: floating
    // summation order exactly matches the old values.reduce operation.
    let sum=0;for(let row=0;row<48;row++)for(let col=0;col<18;col++){const value=luma[row*480+left+col];sum+=Math.max(0,Math.min(1,(paper-value)/paper));}
    const mass=sum/count;return mass>=minOne?1:mass<=maxZero?0:null;
   });
  };
  const top=inspect(0),bottom=useBottom?inspect(750):null;if(!top&&!bottom)return null;let conflict=false;const bits=Array.from({length:16},(_,i)=>{const a=top?.[i]??null,b=bottom?.[i]??null;if(a!==null&&b!==null&&a!==b){conflict=true;return null;}return a??b;});return {bits,top,bottom,conflict};
 }finally{if(readerScratchPool.length<2)readerScratchPool.push(scratch);}
}
// Opt-in same-crop recovery: retain primary evidence and never replace a valid ID.
export function mergeLowMassFallback(primary,candidate,options){
 if(!primary||primary.conflict||decodeBlackBits(primary.bits,options))return primary;
 if(!candidate||candidate.conflict||primary.bits.some((v,i)=>v!==null&&candidate.bits[i]!==v))return primary;
 if(candidate.bits.filter(v=>v!==null).length<=primary.bits.filter(v=>v!==null).length||!decodeBlackBits(candidate.bits,options))return primary;
 return {...candidate,lowMassFallbackUsed:true};
}
export function observeBlackLineWithFallback(canvas,options){
 const primary=observeBlackLine(canvas,options);
 if(!primary||primary.conflict||decodeBlackBits(primary.bits,options))return primary;
 const first=mergeLowMassFallback(primary,observeBlackLine(canvas,{...options,minOne:.045}),options);
 if(!options?.lowMassCascade)return first;
 if(first!==primary)return {...first,fallbackPass:1,fallbackThreshold:.045};
 const second=mergeLowMassFallback(primary,observeBlackLine(canvas,{...options,minOne:.040}),options);
 return second!==primary?{...second,fallbackPass:2,fallbackThreshold:.040}:primary;
}
export function readBlackLine(canvas,options){const observation=observeBlackLine(canvas,options);if(!observation||observation.conflict)return null;const word=decodeBlackBits(observation.bits,options);return word?{...word,...observation}:null;}
