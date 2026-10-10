import {BALANCED_CODEBOOK} from './balanced-codebook.mjs';
export const PALETTE=['#d52d36','#166bd0','#e0ae09','#168e56'];
export const READER_OPTIONS={useBottom:true,minVote:8,dominance:2,minSaturation:.12};
export const NAMES=['赤','青','黄','緑'];
const distance=(a,b)=>a.reduce((s,x,i)=>s+(x!==b[i]),0);
export const CODEBOOK=[];
for(let n=0;n<4096&&CODEBOOK.length<30;n++){const a=Array.from({length:6},(_,k)=>(n>>(2*k))&3);a.push(a.reduce((s,x,k)=>s+x*(k%2?3:1),0)%4);if(CODEBOOK.every(c=>distance(a,c.symbols)>=3))CODEBOOK.push({id:`paper-${String(CODEBOOK.length+1).padStart(3,'0')}`,symbols:a});}
if(CODEBOOK.length!==30)throw Error('Codebook incomplete');
const ORIGINAL_CODEBOOK=CODEBOOK.slice();
export function setCodebook(kind='original'){CODEBOOK.splice(0,CODEBOOK.length,...(kind==='balanced'?BALANCED_CODEBOOK:ORIGINAL_CODEBOOK));}
export function decodeSymbols(a){if(a.length!==7||a.some(x=>!Number.isInteger(x)||x<0||x>3))return null;const sum=a.slice(0,6).reduce((s,x,k)=>s+x*(k%2?3:1),0)%4;if(sum!==a[6])return null;return CODEBOOK.find(c=>distance(a,c.symbols)===0)||null;}
// Minimum code distance 3 makes up to two *known missing* symbols recoverable.
// Never change an observed color; reject if more than one registered code fits.
export function decodeObserved(symbols){const missing=symbols.filter(x=>x===null).length;if(missing===0)return decodeSymbols(symbols);if(missing>2||symbols.length!==7)return null;const candidates=CODEBOOK.filter(c=>symbols.every((x,i)=>x===null||x===c.symbols[i]));return candidates.length===1?candidates[0]:null;}
export function classify([r,g,b]){const mx=Math.max(r,g,b),mn=Math.min(r,g,b),d=mx-mn;if(mx<35||d<12||d/mx<.075)return null;let h=mx===r?((g-b)/d)%6:mx===g?(b-r)/d+2:(r-g)/d+4;h=(h*60+360)%360;const refs=[0,215,48,148],rank=refs.map((v,i)=>({i,d:Math.min(Math.abs(h-v),360-Math.abs(h-v))})).sort((a,b)=>a.d-b.d);return rank[0].d<=30&&rank[1].d-rank[0].d>15?rank[0].i:null;}
export function drawCard(canvas,index=0,{content=true,corrupt=false,dual=false,lineHeight=8,lineLength=40,palette=PALETTE}={}){canvas.width=640;canvas.height=880;const c=canvas.getContext('2d'),item=CODEBOOK[index];c.fillStyle='white';c.fillRect(0,0,640,880);c.strokeStyle='black';c.lineWidth=20;for(const [x,y,s,t]of [[25,25,1,1],[615,25,-1,1],[615,855,-1,-1],[25,855,1,-1]]){c.beginPath();c.moveTo(x+s*60,y);c.lineTo(x,y);c.lineTo(x,y+t*60);c.stroke();}c.fillStyle='black';c.fillRect(76,51,14,24);c.fillRect(534,56,8,14);item.symbols.forEach((s,i)=>{c.fillStyle=corrupt&&i===2?'#aaa':palette[s];c.fillRect(130+i*58-lineLength/2,63-lineHeight/2,lineLength,lineHeight)});if(dual){c.fillStyle='black';c.fillRect(76,801,14,24);c.fillRect(534,806,8,14);item.symbols.forEach((s,i)=>{c.fillStyle=palette[s];c.fillRect(130+i*58-lineLength/2,813-lineHeight/2,lineLength,lineHeight)});}if(content){c.fillStyle='#222';c.textAlign='center';c.font='bold 36px sans-serif';c.fillText(item.id,320,175);c.font='22px sans-serif';c.fillText('L corners + thin LINE ID',320,230);c.fillStyle='#eee';for(let i=0;i<10;i++)c.fillRect(85,290+i*36,400-(i%3)*50,8);c.font='18px sans-serif';c.fillStyle='#555';c.fillText('Page content is NOT matched',320,755);}return canvas;}
export function observeRectified(canvas){
 const c=canvas.getContext('2d');
 const dark=(x0,x1,y0)=>{for(let x=x0;x<=x1;x+=2)for(let y=y0;y<=y0+27;y+=2){const a=c.getImageData(x,y,3,3).data;let sum=0;for(let k=0;k<a.length;k+=4)sum+=(a[k]+a[k+1]+a[k+2])/3;if(sum/9<110)return true;}return false;};
 const read=y=>Array.from({length:7},(_,i)=>{const votes=[0,0,0,0],pixels=c.getImageData(112+i*58,y,36,48).data;for(let k=0;k<pixels.length;k+=4){const rgb=[pixels[k],pixels[k+1],pixels[k+2]],mx=Math.max(...rgb),sat=(mx-Math.min(...rgb))/Math.max(mx,1),z=classify(rgb);if(z!==null&&sat>READER_OPTIONS.minSaturation)votes[z]+=sat;}const ranked=votes.map((v,z)=>({v,z})).sort((a,b)=>b.v-a.v);return ranked[0].v>=READER_OPTIONS.minVote&&ranked[0].v>ranked[1].v*READER_OPTIONS.dominance?ranked[0].z:null;});
 const top=dark(72,88,49)&&dark(528,542,49)?read(42):null;
 const bottom=READER_OPTIONS.useBottom&&dark(72,88,799)&&dark(528,542,799)?read(792):null;
 if(!top&&!bottom)return null;
 let conflict=false;
 const symbols=Array.from({length:7},(_,i)=>{const a=top?.[i]??null,b=bottom?.[i]??null;if(a!==null&&b!==null&&a!==b){conflict=true;return null;}return a??b;});
 return {symbols,top,bottom,conflict};
}
export function readRectified(canvas){const observation=observeRectified(canvas);if(!observation||observation.conflict)return null;const item=decodeObserved(observation.symbols);return item?{...item,...observation,erasures:observation.symbols.filter(x=>x===null).length}:null;}
