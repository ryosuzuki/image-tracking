import test from 'node:test';
import assert from 'node:assert/strict';
import {CODEBOOK,setCodebook,stripeLayout,drawCard,observeRectified,readRectified,decodeObserved,READER_OPTIONS,PALETTE} from './color-code.mjs?v=iter-20261010-f';
// Minimal axis-aligned RGBA canvas fixture for actual renderer/reader sampling.
// Not a geometry or perspective detector substitute.
class Canvas {
 constructor(){this.rects=[];this.ctx={fillStyle:'white',fillRect:(...args)=>this.rects.push([...args,this.ctx.fillStyle]),beginPath(){},moveTo(){},lineTo(){},stroke(){},getImageData:(x,y,w,h)=>{const data=new Uint8ClampedArray(w*h*4);for(let row=0;row<h;row++)for(let col=0;col<w;col++){
 const rect=this.rects.findLast(([rx,ry,rw,rh])=>x+col>=rx&&x+col<rx+rw&&y+row>=ry&&y+row<ry+rh),color=rect?.[4]||'white';const rgb=color==='white'?[255,255,255]:color==='black'?[0,0,0]:color==='#aaa'?[170,170,170]:color.slice(1).match(/../g).map(v=>parseInt(v,16));data.set([...rgb,255],(row*w+col)*4);
 }return {data};}};}
 getContext(){return this.ctx;}
}
test('all30 original/balanced/eight render and read both stripes with matched layout',()=>{
 for(const kind of ['original','balanced','eight']){
  setCodebook(kind);const layout=stripeLayout();assert.equal(layout.count,kind==='eight'?8:7);assert.equal(layout.center(0),130);assert.equal(layout.center(layout.count-1),478);if(kind!=='eight'){assert.equal(layout.pitch,58);assert.equal(layout.sampleWidth,36);}
  for(let index=0;index<30;index++){const canvas=new Canvas();drawCard(canvas,index,{content:false,dual:true});assert.equal(readRectified(canvas)?.id,CODEBOOK[index].id);canvas.ctx.fillStyle='white';canvas.ctx.fillRect(70,42,480,48);assert.equal(readRectified(canvas)?.id,CODEBOOK[index].id);}
 }
 setCodebook();
});
test('eight observation has8slots, three gray erasures recover and wrong colors reject',()=>{
 setCodebook('eight');const canvas=new Canvas();drawCard(canvas,0,{content:false});const layout=stripeLayout();
 canvas.ctx.fillStyle='#aaa';for(const i of [1,3,6])canvas.ctx.fillRect(layout.center(i)-22,42,44,48);
 const observed=observeRectified(canvas);assert.equal(observed.symbols.length,8);assert.equal(observed.symbols.filter(x=>x===null).length,3);assert.equal(readRectified(canvas)?.id,CODEBOOK[0].id);
 const colors=['#d52d36','#166bd0','#e0ae09','#168e56'];canvas.ctx.fillStyle=colors[(CODEBOOK[0].symbols[0]+1)%4];canvas.ctx.fillRect(layout.center(0)-20,59,40,8);assert.equal(readRectified(canvas),null);setCodebook();
});
test('eight decoder integrated path exhaustively rejects wrong-color plus up to3 erasures',()=>{
 setCodebook('eight');const masks=[];for(let bits=0;bits<256;bits++){const m=Array.from({length:8},(_,i)=>i).filter(i=>bits&(1<<i));if(m.length<=3)masks.push(m);}
 for(const c of CODEBOOK)for(const mask of masks){assert.equal(decodeObserved(c.symbols.map((x,i)=>mask.includes(i)?null:x))?.id,c.id);}
 let count=0;for(const c of CODEBOOK)for(let p=0;p<8;p++)for(let color=0;color<4;color++){if(color===c.symbols[p])continue;for(const mask of masks){if(mask.includes(p))continue;assert.equal(decodeObserved(c.symbols.map((x,i)=>mask.includes(i)?null:i===p?color:x)),null);count++;}}
 assert.equal(count,46080);setCodebook();
});

const erase=(canvas,x,y,w,h)=>{canvas.ctx.fillStyle='white';canvas.ctx.fillRect(x,y,w,h);};
const eraseHorizontalColors=canvas=>{erase(canvas,100,42,430,48);erase(canvas,100,792,430,48);};
test('all30 codes in every book decode sides-only and either remaining side',()=>{
 READER_OPTIONS.useSides=true;
 for(const kind of ['original','balanced','eight']){setCodebook(kind);
  for(let index=0;index<30;index++)for(const masked of ['none','left','right']){
   const canvas=new Canvas();drawCard(canvas,index,{content:false,dual:true,sides:true,lineHeight:10});eraseHorizontalColors(canvas);
   if(masked==='left')erase(canvas,39,130,48,620);if(masked==='right')erase(canvas,553,130,48,620);
   const observation=observeRectified(canvas);assert.ok(observation.top.every(x=>x===null));assert.ok(observation.bottom.every(x=>x===null));assert.equal(observation.conflict,false);
   assert.equal(readRectified(canvas)?.id,CODEBOOK[index].id,`${kind} ${index} ${masked}`);
  }
 }
 READER_OPTIONS.useSides=false;setCodebook();
});
test('side duplication is opt-in at rendering and reading; default observations unchanged',()=>{
 setCodebook('balanced');const canvas=new Canvas();drawCard(canvas,0,{content:false,sides:true});eraseHorizontalColors(canvas);
 assert.equal(READER_OPTIONS.useSides,false);assert.equal(readRectified(canvas),null);assert.equal('left' in observeRectified(canvas),false);
 READER_OPTIONS.useSides=true;assert.equal(readRectified(canvas)?.id,CODEBOOK[0].id);
 const noSides=new Canvas();drawCard(noSides,0,{content:false});eraseHorizontalColors(noSides);assert.equal(readRectified(noSides),null);
 READER_OPTIONS.useSides=false;setCodebook();
});
test('left/right and horizontal/side observed-color conflicts reject every book',()=>{
 READER_OPTIONS.useSides=true;
 for(const kind of ['original','balanced','eight']){setCodebook(kind);
  for(const horizontal of [false,true]){
   const canvas=new Canvas();drawCard(canvas,0,{content:false,dual:true,sides:true});if(!horizontal)eraseHorizontalColors(canvas);
   canvas.ctx.fillStyle=PALETTE[(CODEBOOK[0].symbols[0]+1)%4];canvas.ctx.fillRect(573,140,8,40);
   assert.equal(observeRectified(canvas).conflict,true);assert.equal(readRectified(canvas),null);
  }
 }
 READER_OPTIONS.useSides=false;setCodebook();
});
test('partial side evidence combines known erasures without changing colors',()=>{
 READER_OPTIONS.useSides=true;setCodebook('eight');const canvas=new Canvas();drawCard(canvas,4,{content:false,sides:true});eraseHorizontalColors(canvas);
 for(let i=0;i<8;i++){const y=160+i*560/7;erase(canvas,i<4?39:553,y-24,48,48);}
 assert.equal(readRectified(canvas)?.id,CODEBOOK[4].id);assert.deepEqual(observeRectified(canvas).symbols,CODEBOOK[4].symbols);
 READER_OPTIONS.useSides=false;setCodebook();
});
test('side colors cannot bypass asymmetric orientation marks or blank controls',()=>{
 READER_OPTIONS.useSides=true;
 for(const kind of ['original','balanced','eight']){setCodebook(kind);
  const blank=new Canvas();erase(blank,0,0,640,880);assert.equal(observeRectified(blank),null);assert.equal(readRectified(blank),null);
  const noMarks=new Canvas();drawCard(noMarks,0,{content:false,sides:true,dual:true});erase(noMarks,0,0,640,100);erase(noMarks,0,780,640,100);assert.equal(observeRectified(noMarks),null);
  const noColors=new Canvas();drawCard(noColors,0,{content:false,sides:true,dual:true});eraseHorizontalColors(noColors);erase(noColors,39,130,48,620);erase(noColors,553,130,48,620);assert.ok(observeRectified(noColors).symbols.every(x=>x===null));assert.equal(readRectified(noColors),null);
 }
 READER_OPTIONS.useSides=false;setCodebook();
});
