import assert from 'node:assert/strict'
import {inferAngleGesture} from '../src/sketch-proximity.js'
const lines=[{id:0,points:[{x:0,y:0},{x:1,y:0}]},{id:1,points:[{x:0,y:0},{x:0,y:1}]}]
assert.deepEqual(inferAngleGesture([{x:.4,y:0},{x:0,y:.4}],lines),[0,1]);assert.equal(inferAngleGesture([{x:1,y:0},{x:0,y:1}],lines),null);assert.equal(inferAngleGesture([{x:.4,y:.5},{x:.5,y:.4}],lines),null);assert.equal(inferAngleGesture([{x:.3,y:0},{x:.7,y:0}],lines),null);console.log('Interior-to-interior gestures infer an angle; endpoint connections and remote/parallel gestures stay line segments')
