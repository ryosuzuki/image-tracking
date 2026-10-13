import {CODEBOOK_EIGHT} from './codebook-eight.mjs?v=iter-20261010-j';
import {BALANCED_CODEBOOK} from './balanced-codebook.mjs?v=iter-20261010-j';
export const PALETTE=['#d52d36','#166bd0','#e0ae09','#168e56'];
export const READER_OPTIONS={useBottom:true,useSides:false,useCubicFallback:false,minVote:8,dominance:2,minSaturation:.12,hueRefs:[0,215,48,148],whiteNormalize:false};
export const NAMES=['Red','Blue','Yellow','Green'];
const distance=(a,b)=>a.reduce((s,x,i)=>s+(x!==b[i]),0);
export const CODEBOOK=[];
for(let n=0;n<4096&&CODEBOOK.length<30;n++){const a=Array.from({length:6},(_,k)=>(n>>(2*k))&3);a.push(a.reduce((s,x,k)=>s+x*(k%2?3:1),0)%4);if(CODEBOOK.every(c=>distance(a,c.symbols)>=3))CODEBOOK.push({id:`paper-${String(CODEBOOK.length+1).padStart(3,'0')}`,symbols:a});}
if(CODEBOOK.length!==30)throw Error('Codebook incomplete');
const ORIGINAL_CODEBOOK=CODEBOOK.slice();
export let CODEBOOK_REVISION=0;
export function setCodebook(kind='original'){CODEBOOK_REVISION++;CODEBOOK.splice(0,CODEBOOK.length,...(kind==='eight'?CODEBOOK_EIGHT:kind==='balanced'?BALANCED_CODEBOOK:ORIGINAL_CODEBOOK));}
export function stripeLayout(){const count=CODEBOOK[0].symbols.length,pitch=348/(count-1),sampleWidth=count===7?36:Math.floor(Math.min(36,pitch*.62));return {count,pitch,sampleWidth,center:i=>130+i*pitch};}
export function decodeSymbols(a){if(!Array.isArray(a)||a.length!==CODEBOOK[0].symbols.length||Array.from(a).some(x=>!Number.isInteger(x)||x<0||x>3))return null;if(a.length===7){const sum=a.slice(0,6).reduce((s,x,k)=>s+x*(k%2?3:1),0)%4;if(sum!==a[6])return null;}return CODEBOOK.find(c=>distance(a,c.symbols)===0)||null;}
// Known erasures only; observed colors are never corrected. Eight-slot words
// use dictionary membership, not the seven-slot weighted checksum.
export function decodeObserved(symbols){const count=CODEBOOK[0].symbols.length;if(!Array.isArray(symbols)||symbols.length!==count||Array.from(symbols).some(x=>x!==null&&(!Number.isInteger(x)||x<0||x>3)))return null;const missing=symbols.filter(x=>x===null).length;if(missing===0)return decodeSymbols(symbols);if(missing>(count===8?3:2))return null;const candidates=CODEBOOK.filter(c=>symbols.every((x,i)=>x===null||x===c.symbols[i]));return candidates.length===1?candidates[0]:null;}
export const MGBY_PALETTE=['#be27bf','#0055ff','#ffc800','#00ff79'];
export function setHueRefs(refs){if(!Array.isArray(refs)||refs.length!==4||refs.some(x=>typeof x!=='number'||!Number.isFinite(x)||x<0||x>=360))throw new RangeError('hueRefs requires four finite angles in [0,360)');READER_OPTIONS.hueRefs=refs.slice();}
export function configurePalette(kind){if(kind==='original'){setHueRefs([0,215,48,148]);return PALETTE.slice();}if(kind==='mgby'){setHueRefs([300,215,48,148]);return MGBY_PALETTE.slice();}return null;}

function classifyRGB(r,g,b){const mx=Math.max(r,g,b),mn=Math.min(r,g,b),d=mx-mn;if(mx<35||d<12||d/mx<.075)return null;let h=mx===r?((g-b)/d)%6:mx===g?(b-r)/d+2:(r-g)/d+4;h=(h*60+360)%360;let best=-1,first=Infinity,second=Infinity;for(let i=0;i<4;i++){const delta=Math.abs(h-READER_OPTIONS.hueRefs[i]),distance=Math.min(delta,360-delta);if(distance<first){second=first;first=distance;best=i;}else if(distance<second)second=distance;}return first<=30&&second-first>15?best:null;}
export function classify([r,g,b]){return classifyRGB(r,g,b);}
export function drawCard(canvas,index=0,{content=true,corrupt=false,dual=false,sides=false,lineHeight=8,lineLength=40,palette=PALETTE}={}){canvas.width=640;canvas.height=880;const c=canvas.getContext('2d'),item=CODEBOOK[index],layout=stripeLayout();if(layout.count===8)lineLength=Math.min(lineLength,layout.pitch-10);c.fillStyle='white';c.fillRect(0,0,640,880);c.strokeStyle='black';c.lineWidth=20;for(const [x,y,s,t]of [[25,25,1,1],[615,25,-1,1],[615,855,-1,-1],[25,855,1,-1]]){c.beginPath();c.moveTo(x+s*60,y);c.lineTo(x,y);c.lineTo(x,y+t*60);c.stroke();}c.fillStyle='black';c.fillRect(76,51,14,24);c.fillRect(534,56,8,14);item.symbols.forEach((s,i)=>{c.fillStyle=corrupt&&i===2?'#aaa':palette[s];c.fillRect(layout.center(i)-lineLength/2,63-lineHeight/2,lineLength,lineHeight)});if(dual){c.fillStyle='black';c.fillRect(76,801,14,24);c.fillRect(534,806,8,14);item.symbols.forEach((s,i)=>{c.fillStyle=palette[s];c.fillRect(layout.center(i)-lineLength/2,813-lineHeight/2,lineLength,lineHeight)});}if(sides){item.symbols.forEach((symbol,i)=>{c.fillStyle=palette[symbol];const y=160+i*560/(layout.count-1);for(const x of [63,577])c.fillRect(x-lineHeight/2,y-lineLength/2,lineHeight,lineLength);});}if(content){c.fillStyle='#222';c.textAlign='center';c.font='bold 36px sans-serif';c.fillText(item.id,320,175);c.font='22px sans-serif';c.fillText('L corners + thin LINE ID',320,230);c.fillStyle='#eee';for(let i=0;i<10;i++)c.fillRect(85,290+i*36,400-(i%3)*50,8);c.font='18px sans-serif';c.fillStyle='#555';c.fillText('Page content is NOT matched',320,755);}return canvas;}
export function setWhiteNormalize(v){if(typeof v!=='boolean')throw new TypeError('whiteNormalize boolean');READER_OPTIONS.whiteNormalize=v;}
function localWhite(c,x,y,width){const d=c.getImageData(x,y===42?84:834,width,14).data,a=[[],[],[]];for(let k=0;k<d.length;k+=4)for(let j=0;j<3;j++)a[j].push(d[k+j]);const r=a.map(v=>{v.sort((a,b)=>a-b);return {m:v[Math.floor(v.length*.5)],iqr:v[Math.floor(v.length*.75)]-v[Math.floor(v.length*.25)]};});if(r.some(v=>v.m<45||v.iqr/v.m>.2)||Math.max(...r.map(v=>v.m))/Math.min(...r.map(v=>v.m))>3)return null;const l=r.reduce((s,v)=>s+v.m,0)/3;return r.map(v=>l/v.m);}
export function observeRectified(canvas){
 const c=canvas.getContext('2d'),layout=stripeLayout();
 const dark=(x0,x1,y0)=>{for(let x=x0;x<=x1;x+=2)for(let y=y0;y<=y0+27;y+=2){const a=c.getImageData(x,y,3,3).data;let sum=0;for(let k=0;k<a.length;k+=4)sum+=(a[k]+a[k+1]+a[k+2])/3;if(sum/9<110)return true;}return false;};
 const vote=(x,y,width,height)=>{const votes=[0,0,0,0],pixels=c.getImageData(x,y,width,height).data,white=READER_OPTIONS.whiteNormalize?localWhite(c,x,y,width):[1,1,1];if(!white)return null;for(let k=0;k<pixels.length;k+=4){const r=Math.min(255,pixels[k]*white[0]),g=Math.min(255,pixels[k+1]*white[1]),b=Math.min(255,pixels[k+2]*white[2]),mx=Math.max(r,g,b),sat=(mx-Math.min(r,g,b))/Math.max(mx,1),z=classifyRGB(r,g,b);if(z!==null&&sat>READER_OPTIONS.minSaturation)votes[z]+=sat;}const ranked=votes.map((v,z)=>({v,z})).sort((a,b)=>b.v-a.v);return ranked[0].v>=READER_OPTIONS.minVote&&ranked[0].v>ranked[1].v*READER_OPTIONS.dominance?ranked[0].z:null;};
 const read=y=>Array.from({length:layout.count},(_,i)=>vote(Math.round(layout.center(i)-layout.sampleWidth/2),y,layout.sampleWidth,48));
 const topMarked=dark(72,88,49)&&dark(528,542,49);
 const bottomMarked=(READER_OPTIONS.useBottom||READER_OPTIONS.useSides)&&dark(72,88,799)&&dark(528,542,799);
 // Side color samples never establish page orientation by themselves. Keep
 // existing asymmetric upper/lower black marks; no added side fiducials.
 if(!topMarked&&!bottomMarked)return null;
 const top=topMarked?read(42):null,bottom=READER_OPTIONS.useBottom&&bottomMarked?read(792):null;
 const side=x=>Array.from({length:layout.count},(_,i)=>vote(x-24,Math.round(160+i*560/(layout.count-1)-layout.sampleWidth/2),48,layout.sampleWidth));
 const left=READER_OPTIONS.useSides?side(63):null,right=READER_OPTIONS.useSides?side(577):null;
 let conflict=false;
 const symbols=Array.from({length:layout.count},(_,i)=>{let known=null;for(const edge of [top,bottom,left,right]){const color=edge?.[i]??null;if(color===null)continue;if(known!==null&&known!==color){conflict=true;return null;}known=color;}return known;});
 return {symbols,top,bottom,...(READER_OPTIONS.useSides?{left,right}:{}),conflict};
}
export function readRectified(canvas){const observation=observeRectified(canvas);if(!observation||observation.conflict)return null;const item=decodeObserved(observation.symbols);return item?{...item,...observation,erasures:observation.symbols.filter(x=>x===null).length}:null;}
