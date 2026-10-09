import assert from 'node:assert/strict'
import {inferPerpendicular} from '../src/sketch-proximity.js'
import {evaluateObjectGraph,validateObjectGraph} from '../src/sketch-objects-model.js'
const a={id:0,name:'a',kind:'line',parameter:'length',points:[{x:0,y:0},{x:1,y:0}],endBinding:'moving'},b={id:1,name:'b',kind:'line',parameter:'angle',points:[{x:0,y:0},{x:.01,y:.5}],perpendicularTo:0,perpendicularSign:1}
assert.deepEqual(inferPerpendicular(b.points,[a]),{id:0,sign:1});assert.equal(inferPerpendicular([{x:3,y:0},{x:3,y:.5}],[a]),null)
for(const q of [{x:1,y:0},{x:.5,y:.8}]){const r=evaluateObjectGraph([a,b],{point:()=>q});assert.ok(Math.abs(r.results.get(1).angle-r.results.get(0).angle-90)<1e-9);assert.ok(Math.abs(r.results.get(1).length-Math.hypot(.01,.5))<1e-9)}
for(const q of [{x:.1,y:.2},{x:.3,y:.6}]){const r=evaluateObjectGraph([a,{...b,startBinding:'root'}],{point:id=>id==='root'?q:{x:1,y:.5}});assert.ok(Math.abs(r.results.get(1).length-Math.hypot(.01,.5))<1e-9)}
assert.equal(evaluateObjectGraph([a,b]).results.get(1).valid,false)
assert.throws(()=>validateObjectGraph([{...a,lengthExpression:'b'},b]),/Cyclic/)
assert.throws(()=>validateObjectGraph([a,{...b,angleExpression:'a'}]),/Choose/)
console.log('Proximity-gated perpendicular inference follows a moving reference, preserves length, rejects cycles and missing input')
