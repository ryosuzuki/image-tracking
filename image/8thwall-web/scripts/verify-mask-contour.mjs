import assert from 'node:assert/strict'
import {confidenceShape} from '../src/mask-contour.js'
const data=new Uint8Array(12*12);for(let y=1;y<11;y++)for(let x=1;x<11;x++)if(x<4||x>=8||y<4||y>=8)data[y*12+x]=255
const shape=confidenceShape({width:12,height:12,data});assert.equal(shape.pixels,84);assert.equal(shape.components.length,1);assert.equal(shape.components[0].holes.length,1);assert.equal(shape.loops.length,2)
assert.equal(confidenceShape({width:12,height:12,data:new Uint8Array(3)}),null)
const ramp=confidenceShape({width:3,height:1,data:new Uint8Array([100,128,255])},.5);assert.equal(ramp.pixels,2)
console.log('Confidence threshold, disconnected mask validity and enclosed-hole contour geometry passed')
