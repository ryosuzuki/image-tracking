import assert from 'node:assert/strict'
import {selectInkComponent} from '../src/ink-selection.js'
const width=30,height=20,data=new Uint8ClampedArray(width*height*4).fill(255)
function dot(x,y){data[(y*width+x)*4]=0}
for(let x=2;x<=10;x++){dot(x,2);dot(x,10)}for(let y=2;y<=10;y++){dot(2,y);dot(10,y)}for(let y=3;y<8;y++)for(let x=20;x<25;x++)dot(x,y)
const r=selectInkComponent({width,height,data},{x:6,y:2},{radius:2});assert.equal(r.pixels,32);assert.equal(r.mask[6*width+6],0);assert.equal(r.mask[5*width+22],0);assert.deepEqual(r.bounds,{x0:0,y0:0,x1:13,y1:13})
assert.equal(selectInkComponent({width,height,data},{x:15,y:16},{radius:1}),null)
assert.equal(selectInkComponent({width,height,data},{x:NaN,y:2}),null)
const b=selectInkComponent({width,height,data},{x:22,y:5},{radius:1});assert.equal(b.pixels,25);assert.equal(b.mask[2*width+2],0)
console.log('Connected ink selection preserves holes and excludes disconnected adjacent objects')
