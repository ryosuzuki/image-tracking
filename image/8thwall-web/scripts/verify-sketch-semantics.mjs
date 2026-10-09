import assert from 'node:assert/strict'
import {polygonArea,evaluateSketchBinding} from '../src/sketch-semantics.js'
assert.equal(polygonArea([{x:0,y:0},{x:3,y:0},{x:3,y:4},{x:0,y:4}]),12)
assert.equal(evaluateSketchBinding('L*2+A',{length:3,angle:90,area:12,t:1},{length:'L',angle:'theta',area:'A'}),18)
assert.throws(()=>evaluateSketchBinding('unknown',{length:3,angle:90,area:12,t:1}),/Unknown variable/)
assert.throws(()=>evaluateSketchBinding('length/0',{length:3,angle:90,area:12,t:1}),/finite/)
console.log('Sketch polygon area, renamed variables, expression binding and invalid expressions passed')
