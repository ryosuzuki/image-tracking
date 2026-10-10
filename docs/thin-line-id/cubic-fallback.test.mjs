import test from 'node:test';
import assert from 'node:assert/strict';
import {CODEBOOK,setCodebook,stripeLayout,READER_OPTIONS} from './color-code.mjs?v=iter-20261010-f';
import {eligibleCubicFallback,selectCubicFallbackCandidates,mergeCubicFallback,cubicReaderPatches,readCubicFallback} from './cubic-fallback.mjs';
const combinations=(n,k)=>{const out=[];function visit(a,start){if(a.length===k){out.push(a);return;}for(let i=start;i<n;i++)visit([...a,i],i+1);}visit([],0);return out;};
test('all books preserve known colors/conflicts and reject substitution plus permitted erasures',()=>{
 for(const book of ['original','balanced','eight']){setCodebook(book);const count=CODEBOOK[0].symbols.length;
  for(const item of CODEBOOK)for(const missing of combinations(count,count-4)){
   const symbols=item.symbols.map((x,i)=>missing.includes(i)?null:x),base={id:null,symbols,conflict:false},compatible=eligibleCubicFallback(base);
   const good=mergeCubicFallback(base,{symbols:item.symbols.slice(),conflict:false});assert.equal(good?.id||null,compatible?item.id:null);
   assert.equal(mergeCubicFallback({...base,id:item.id},{symbols:item.symbols}),null);assert.equal(mergeCubicFallback({...base,conflict:true},{symbols:item.symbols}),null);assert.equal(mergeCubicFallback(base,{symbols:item.symbols,conflict:true}),null);
   const known=symbols.findIndex(x=>x!==null),changed=item.symbols.slice();changed[known]=(changed[known]+1)%4;assert.equal(mergeCubicFallback(base,{symbols:changed}),null);changed[known]=null;assert.equal(mergeCubicFallback(base,{symbols:changed}),null);
   for(const wrong of missing)for(let color=0;color<4;color++)if(color!==item.symbols[wrong])for(let eraseCount=0;eraseCount<missing.length;eraseCount++)for(const erased of combinations(missing.length-1,eraseCount)){
    const remaining=missing.filter(i=>i!==wrong),cubic=item.symbols.slice();cubic[wrong]=color;for(const i of erased)cubic[remaining[i]]=null;assert.equal(mergeCubicFallback(base,{symbols:cubic,conflict:false}),null);
   }
  }
  assert.equal(eligibleCubicFallback({symbols:Array(count).fill(null)}),null);
 }
 setCodebook();
});
test('original ambiguous four-color evidence cannot accept a wrong cubic symbol',()=>{
 setCodebook();const base={id:null,symbols:[null,null,null,0,0,0,0],conflict:false};assert.equal(eligibleCubicFallback(base),null);assert.equal(mergeCubicFallback(base,{symbols:[2,null,null,0,0,0,0]}),null);
});
test('two-group rotating budget excludes fresh/conflicting/blank/noncompatible observations',()=>{
 setCodebook('balanced');const item=CODEBOOK[0],base={id:null,symbols:item.symbols.map((x,i)=>i<3?null:x),conflict:false};
 const qs=Array.from({length:5},(_,i)=>({...base,q:[[i*100,0],[i*100+80,0],[i*100+80,100],[i*100,100]]}));
 assert.deepEqual(selectCubicFallbackCandidates(qs,0),qs.slice(0,2));assert.deepEqual(selectCubicFallbackCandidates(qs,1),qs.slice(1,3));assert.deepEqual(selectCubicFallbackCandidates(qs,4),[qs[4],qs[0]]);
 assert.equal(selectCubicFallbackCandidates([{...qs[0],id:item.id},{...qs[1],conflict:true},{...qs[2],symbols:Array(7).fill(null)},{...qs[3],q:null}]).length,0);setCodebook();
});
test('patches cover existing reader locations in seven/eight-slot and four-edge modes',()=>{
 for(const book of ['original','balanced','eight']){setCodebook(book);const layout=stripeLayout();for(const sides of [false,true]){const patches=cubicReaderPatches(layout,sides);assert.equal(patches.length,4+layout.count*(sides?4:2));assert.ok(patches.every(([x,y,w,h])=>x>=0&&y>=0&&x+w<=640&&y+h<=880));}}
 setCodebook();
});
test('all native Mats are released on success and allocation/warp/display failures',()=>{
 const oldCV=globalThis.cv,oldDocument=globalThis.document,oldSides=READER_OPTIONS.useSides;setCodebook('balanced');READER_OPTIONS.useSides=true;
 try{for(const failure of [null,'allocate2','allocate5','transform','warp1','warp12','display1','display8']){
  const mats=[];let allocations=0,warps=0,displays=0;
  class Mat{constructor(data=[1,0,0,0,1,0,0,0,1]){allocations++;if(failure===`allocate${allocations}`)throw Error('allocation');this.data64F=Float64Array.from(data);this.deleted=false;mats.push(this);}delete(){assert.equal(this.deleted,false,'no double deletion');this.deleted=true;}}
  globalThis.cv={Mat,CV_32FC2:1,CV_64F:2,INTER_CUBIC:2,matFromArray:(r,c,type,data)=>new Mat(data),getPerspectiveTransform:()=>{if(failure==='transform')throw Error('transform');return new Mat();},Size:class{constructor(width,height){Object.assign(this,{width,height});}},warpPerspective:()=>{warps++;if(failure===`warp${warps}`)throw Error('warp');},imshow:()=>{displays++;if(failure===`display${displays}`)throw Error('display');}};
  const ctx={fillRect(){},drawImage(){},getImageData(x,y,w,h){return {data:Uint8ClampedArray.from({length:w*h*4},()=>255)};}};globalThis.document={createElement:()=>({getContext:()=>ctx})};
  if(failure)assert.throws(()=>readCubicFallback({},[[0,0],[100,0],[100,140],[0,140]]));else assert.equal(readCubicFallback({},[[0,0],[100,0],[100,140],[0,140]]),null);
  assert.ok(mats.every(m=>m.deleted),failure||'success');
 }}finally{globalThis.cv=oldCV;globalThis.document=oldDocument;READER_OPTIONS.useSides=oldSides;setCodebook();}
});
