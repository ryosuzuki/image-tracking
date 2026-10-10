// Standalone opt-in prototype; not connected to any live recognition page.
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
export function observeBlackLine(canvas,{useBottom=true,minOne=.055,maxZero=.025}={}){
 const c=canvas.getContext('2d'),luma=data=>{const a=[];for(let k=0;k<data.length;k+=4)a.push(.2126*data[k]+.7152*data[k+1]+.0722*data[k+2]);return a;};
 const median=a=>a.slice().sort((x,y)=>x-y)[Math.floor(a.length/2)];
 const marked=base=>{const white=median(luma(c.getImageData(100,42+base,430,48).data));if(white<25)return false;const dark=(x0,x1)=>{for(let x=x0;x<=x1;x+=2)for(let y=49+base;y<=76+base;y+=2){const ink=luma(c.getImageData(x,y,3,3).data);if(ink.reduce((a,b)=>a+b,0)/ink.length<white*.5)return true;}return false;};return dark(72,88)&&dark(528,542);};
 const edge=base=>Array.from({length:16},(_,i)=>{const values=luma(c.getImageData(Math.round(130+i*348/15-9),42+base,18,48).data),paper=median(values);if(paper<25)return null;const mass=values.reduce((s,v)=>s+Math.max(0,Math.min(1,(paper-v)/paper)),0)/values.length;return mass>=minOne?1:mass<=maxZero?0:null;});
 const top=marked(0)?edge(0):null,bottom=useBottom&&marked(750)?edge(750):null;if(!top&&!bottom)return null;let conflict=false;
 const bits=Array.from({length:16},(_,i)=>{const a=top?.[i]??null,b=bottom?.[i]??null;if(a!==null&&b!==null&&a!==b){conflict=true;return null;}return a??b;});
 return {bits,top,bottom,conflict};
}
export function readBlackLine(canvas,options){const observation=observeBlackLine(canvas,options);if(!observation||observation.conflict)return null;const word=decodeBlackBits(observation.bits,options);return word?{...word,...observation}:null;}
