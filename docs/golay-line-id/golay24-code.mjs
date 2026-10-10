import {GOLAY24_BOOK,decodeGolay24} from './golay24.mjs?v=golay24-20261010-a';
export {GOLAY24_BOOK,decodeGolay24};
export const GOLAY24_LAYOUTS={dense14:{lineHeight:8,lineLength:14,sampleWidth:12},subtle8:{lineHeight:8,lineLength:8,sampleWidth:12},middle10:{lineHeight:8,lineLength:10,sampleWidth:12}};
export const GOLAY24_OPTIONS={maxErrors:1,maxErasures:3,orientationRatio:.7,minOne:.055,maxZero:.025,sampleWidth:12,rankSkew:.6};
export function drawGolay24Card(canvas,index=0,{dual=true,lineHeight=8,lineLength=14,content=true,book=GOLAY24_BOOK}={}){
 canvas.width=640;canvas.height=880;const c=canvas.getContext('2d'),word=book[index];c.fillStyle='white';c.fillRect(0,0,640,880);c.strokeStyle='black';c.lineWidth=20;
 for(const [x,y,s,t] of [[25,25,1,1],[615,25,-1,1],[615,855,-1,-1],[25,855,1,-1]]){c.beginPath();c.moveTo(x+s*60,y);c.lineTo(x,y);c.lineTo(x,y+t*60);c.stroke();}
 c.fillStyle='black';for(const base of dual?[0,750]:[0]){c.fillRect(76,51+base,14,24);c.fillRect(534,56+base,8,14);word.bits.forEach((bit,i)=>{if(bit)c.fillRect(130+i*348/23-lineLength/2,63+base-lineHeight/2,lineLength,lineHeight);});}
 if(content){c.font='30px sans-serif';c.textAlign='center';c.fillText(word.id,320,175);c.font='20px sans-serif';c.fillText('BLACK LINE ID — prototype',320,230);}
 return canvas;
}
function medianExact(input){const a=input.slice(),k=Math.floor(a.length/2);let lo=0,hi=a.length-1;while(lo<hi){const pivot=a[(lo+hi)>>1];let i=lo,j=hi;while(i<=j){while(a[i]<pivot)i++;while(a[j]>pivot)j--;if(i<=j){[a[i],a[j]]=[a[j],a[i]];i++;j--;}}if(k<=j)hi=j;else if(k>=i)lo=i;else break;}return a[k];}
export function observeGolay24(canvas,{useBottom=true,minOne=.055,maxZero=.025,orientationRatio=.7,sampleWidth=12}={}){
 if(!Number.isFinite(orientationRatio)||orientationRatio<.3||orientationRatio>.85)throw new RangeError('orientationRatio must be finite and between .3 and .85');
 if(!Number.isInteger(sampleWidth)||sampleWidth<6||sampleWidth>14)throw new RangeError('sampleWidth must be integer6..14');
 const c=canvas.getContext('2d');
 const cached=base=>{const data=c.getImageData(70,42+base,480,48).data;return (x,y,w,h)=>{const a=[];for(let row=0;row<h;row++)for(let col=0;col<w;col++){const k=((y-42-base+row)*480+x-70+col)*4;a.push(.2126*data[k]+.7152*data[k+1]+.0722*data[k+2]);}return a;};};
 const inspect=base=>{const luma=cached(base),white=medianExact(luma(100,42+base,430,48));if(white<25)return null;const dark=(x0,x1)=>{for(let x=x0;x<=x1;x+=2)for(let y=49+base;y<=76+base;y+=2){const ink=luma(x,y,3,3);if(ink.reduce((a,b)=>a+b,0)/ink.length<white*orientationRatio)return true;}return false;};if(!dark(72,88)||!dark(528,542))return null;return Array.from({length:24},(_,i)=>{const values=luma(Math.round(130+i*348/23-sampleWidth/2),42+base,sampleWidth,48),paper=medianExact(values);if(paper<25)return null;const mass=values.reduce((s,v)=>s+Math.max(0,Math.min(1,(paper-v)/paper)),0)/values.length;return mass>=minOne?1:mass<=maxZero?0:null;});};
 const top=inspect(0),bottom=useBottom?inspect(750):null;if(!top&&!bottom)return null;let conflict=false;const bits=Array.from({length:24},(_,i)=>{const a=top?.[i]??null,b=bottom?.[i]??null;if(a!==null&&b!==null&&a!==b){conflict=true;return null;}return a??b;});return {bits,top,bottom,conflict};
}

export function readGolay24(canvas,options){const o=observeGolay24(canvas,options);if(!o||o.conflict)return null;const word=decodeGolay24(o.bits,options);return word?{...word,...o}:null;}
