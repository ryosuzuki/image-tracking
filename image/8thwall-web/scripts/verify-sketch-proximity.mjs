import assert from 'node:assert/strict'
import {nearestTrackedBinding} from '../src/sketch-proximity.js'
const points=[{id:'missing',point:null},{id:'red',point:{x:.1,y:.2}},{id:'blue',point:{x:.13,y:.2}}]
assert.equal(nearestTrackedBinding({x:.104,y:.2},points),'red');assert.equal(nearestTrackedBinding({x:.14,y:.2},points),'blue');assert.equal(nearestTrackedBinding({x:.7,y:.2},points),null);assert.equal(nearestTrackedBinding({x:.1,y:.2},points,NaN),null);assert.equal(nearestTrackedBinding({x:.1,y:NaN},points),null);console.log('Nearest available tracked input binds within explicit page-space tolerance')
