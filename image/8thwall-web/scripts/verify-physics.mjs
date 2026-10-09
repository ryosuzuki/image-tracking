import assert from 'node:assert/strict'
import {pendulumStep,pendulumEnergy,thinLens,projectile,circuit} from '../src/physics.js'
let s={angle:.8,velocity:0},e=pendulumEnergy(s,{length:2}),max=0
for(let i=0;i<20000;i++){s=pendulumStep(s,.005,{length:2});max=Math.max(max,Math.abs(pendulumEnergy(s,{length:2})-e)/e)}assert.ok(max<1e-6,`Energy error ${max}`)
assert.deepEqual(thinLens(1,2),{imageDistance:2,magnification:-1});assert.equal(thinLens(1,.5).imageDistance,-1);assert.equal(thinLens(1,1).imageDistance,Infinity)
const angle=Math.PI/4,speed=5,t=2*speed*Math.sin(angle)/9.81;assert.ok(Math.abs(projectile(t,{speed,angle}).y)<1e-10);assert.deepEqual(circuit(6,3),{current:2,power:12});console.log(JSON.stringify({passed:true,pendulumEnergyMaxRelativeError:max,thinLens:true,projectile:true,circuit:true}))
