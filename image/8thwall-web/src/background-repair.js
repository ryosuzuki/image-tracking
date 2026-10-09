// Local camera-pixel fill inside an explicit source-ink mask. It preserves all
// unmasked pixels and propagates nearby paper colors; no learned reconstruction.
export function repairMaskedPixels(image,mask){
 const {width,height,data}=image,out=new Uint8ClampedArray(data),known=Uint8Array.from(mask,v=>v?0:1),queue=[],queued=new Uint8Array(mask.length)
 const neighbors=i=>{const x=i%width,y=Math.floor(i/width);return [x?i-1:-1,x+1<width?i+1:-1,y?i-width:-1,y+1<height?i+width:-1].filter(j=>j>=0)}
 for(let i=0;i<mask.length;i++)if(mask[i]&&neighbors(i).some(j=>known[j])){queue.push(i);queued[i]=1}
 let filled=0
 for(let q=0;q<queue.length;q++){const i=queue[q],near=neighbors(i).filter(j=>known[j]);if(!near.length)continue;for(let c=0;c<3;c++)out[i*4+c]=Math.round(near.reduce((sum,j)=>sum+out[j*4+c],0)/near.length);out[i*4+3]=255;known[i]=1;filled++;for(const j of neighbors(i))if(mask[j]&&!queued[j]){queued[j]=1;queue.push(j)}}
 return {data:out,filled,maskPixels:mask.reduce((n,v)=>n+!!v,0),complete:known.every(Boolean)}
}
