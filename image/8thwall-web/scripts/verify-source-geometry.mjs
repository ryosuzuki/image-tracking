import assert from 'node:assert/strict'
import Matter from 'matter-js'
import * as THREE from 'three'
import {inkConvexHull,inkContours} from '../src/source-geometry.js'
const width=20,height=20,data=new Uint8ClampedArray(width*height*4)
for(let y=4;y<14;y++)for(let x=3;x<=3+y-4;x++)data[(y*width+x)*4+3]=255
const hull=inkConvexHull({data,width,height}),area=Matter.Vertices.area(hull),center=Matter.Vertices.centre(hull),body=Matter.Bodies.fromVertices(center.x,center.y,[hull])
assert.ok(hull.length>3);assert.ok(area<100);assert.ok(area>50);assert.ok(Math.abs(body.position.x-center.x)<1e-9);assert.ok(Math.abs(body.position.y-center.y)<1e-9);assert.ok(Math.abs(Matter.Vertices.area(body.vertices)-area)<1e-8)
assert.equal(Matter.Query.point([body],{x:12,y:4}).length,0,'Empty corner must not collide as a rectangle')
assert.equal(Matter.Query.point([body],{x:5,y:12}).length,1)
assert.deepEqual(inkConvexHull({data:new Uint8ClampedArray(16),width:2,height:2}),[])
console.log(JSON.stringify({passed:true,vertices:hull.length,area,emptyCornerRejected:true,centroidPreserved:true}))

function triangulated(mask,w,h){const components=inkContours({data:mask,width:w,height:h}),parts=[];for(const c of components){const outer=c.outer.map(p=>new THREE.Vector2(p.x,p.y)),holes=c.holes.map(h=>h.map(p=>new THREE.Vector2(p.x,p.y))),all=[...outer,...holes.flat()];for(const face of THREE.ShapeUtils.triangulateShape(outer,holes)){const triangle=face.map(i=>({x:all[i].x,y:all[i].y})),center=Matter.Vertices.centre(triangle);parts.push(Matter.Bodies.fromVertices(center.x,center.y,[triangle]))}}return {components,parts,body:Matter.Body.create({parts:parts.slice()})}}
const ring=new Uint8ClampedArray(12*12*4);for(let y=1;y<11;y++)for(let x=1;x<11;x++)if(x<4||x>=8||y<4||y>=8)ring[(y*12+x)*4+3]=255
const donut=triangulated(ring,12,12);assert.equal(donut.components.length,1);assert.equal(donut.components[0].holes.length,1);assert.equal(donut.parts.reduce((n,p)=>n+Matter.Vertices.area(p.vertices),0),84);assert.equal(Matter.Query.point([donut.body],{x:6,y:6}).length,0);assert.equal(Matter.Query.point([donut.body],{x:2,y:6}).length,1)
const concave=new Uint8ClampedArray(10*10*4);for(let y=1;y<9;y++)for(let x=1;x<9;x++)if(x<3||y<3||y>=7)concave[(y*10+x)*4+3]=255
const c=triangulated(concave,10,10);assert.equal(c.components[0].holes.length,0);assert.equal(Matter.Query.point([c.body],{x:6,y:5}).length,0);assert.equal(Matter.Query.point([c.body],{x:2,y:5}).length,1)
const diagonal=new Uint8ClampedArray(2*2*4);diagonal[3]=255;diagonal[15]=255;assert.equal(inkContours({data:diagonal,width:2,height:2}).length,2)
console.log(JSON.stringify({passed:true,internalHoleEmpty:true,concavityEmpty:true,donutTriangleArea:84,diagonalIslands:2}))
