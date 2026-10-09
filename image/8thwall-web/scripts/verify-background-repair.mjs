import assert from 'node:assert/strict'
import {repairMaskedPixels} from '../src/background-repair.js'
const width=30,height=20,data=new Uint8ClampedArray(width*height*4),mask=new Uint8Array(width*height)
for(let i=0;i<width*height;i++){data.set([180,205,225,255],i*4);if(i%width>=12&&i%width<17&&Math.floor(i/width)>3&&Math.floor(i/width)<16){mask[i]=1;data.set([10,10,10,255],i*4)}}
const repaired=repairMaskedPixels({width,height,data},mask);assert.equal(repaired.complete,true);assert.equal(repaired.filled,60);for(let i=0;i<mask.length;i++)assert.deepEqual([...repaired.data.slice(i*4,i*4+4)],[180,205,225,255]);assert.equal(data[5*width*4+12*4],10,'Input must remain unchanged');assert.equal(repairMaskedPixels({width:1,height:1,data:new Uint8ClampedArray(4)},new Uint8Array([1])).complete,false);console.log(JSON.stringify({passed:true,filled:60,unmaskedPixelsUnchanged:true,cameraColorPreserved:true,allMaskedRejected:true}))
