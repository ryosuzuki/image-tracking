import assert from 'node:assert/strict'
import {inferClosedRegion} from '../src/sketch-proximity.js'
import {evaluateObjectGraph,validateObjectGraph} from '../src/sketch-objects-model.js'
const line=(id,name,points,extra={})=>({id,name,kind:'line',parameter:'length',points:points.map(([x,y])=>({x,y})),...extra})
const a=line(0,'a',[[0,0],[1,0]]),b=line(1,'b',[[1,0],[1,1]],{startBinding:'line:0:1'}),c=line(2,'c',[[1,1],[0,1]],{startBinding:'line:1:1'}),d=line(3,'d',[[0,1],[0,0]],{startBinding:'line:2:1',endBinding:'line:0:0'})
const detected=inferClosedRegion(d,[a,b,c]);assert.ok(detected);assert.equal(detected.references.length,4)
const region={id:4,name:'region',kind:'area',points:[],...detected};let result=evaluateObjectGraph([a,b,c,d,region]);assert.equal(result.results.get(4).area,1)
result=evaluateObjectGraph([{...a,points:[{x:0,y:0},{x:2,y:0}]},b,c,d,region]);assert.equal(result.results.get(4).area,1.5);assert.deepEqual(result.results.get(1).points[0],{x:2,y:0})
result=evaluateObjectGraph([{...a,endBinding:'missing'},b,c,d,region]);assert.equal(result.results.get(4).valid,false)
result=evaluateObjectGraph([a,b,c,{...d,endBinding:'fixed',points:[{x:0,y:1},{x:.2,y:0}]},region]);assert.equal(result.results.get(4).valid,false);assert.match(result.results.get(4).error,/opened/)
assert.equal(inferClosedRegion({...d,points:[{x:0,y:1},{x:3,y:0}]},[a,b,c]),null)
assert.throws(()=>validateObjectGraph([{...a,startBinding:'line:3:0'},b,c,d,region]),/Cyclic/)
const closing=line(2,'c',[[1,1],[0,0]]),triangle=inferClosedRegion(closing,[a,b]);assert.ok(triangle);assert.equal(evaluateObjectGraph([a,b,closing,{id:3,name:'area',kind:'area',points:[],...triangle}]).results.get(3).area,.5)
console.log('Triangles and quadrilaterals become dependent areas; endpoint references follow edits, missing/open edges invalidate, cycles reject')
