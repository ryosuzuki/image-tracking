import assert from 'node:assert/strict';
import {registrationQuality as gate} from '../quality.mjs';
for (const q of [
  [[0,0],[600,0],[600,400],[0,400]],
  [[150,0],[650,100],[500,500],[0,400]],
  [[100,80],[570,110],[600,420],[50,400]],
]) assert.equal(gate(q).ok,true,'Normal, rotated and moderately skewed papers remain readable');
for (const q of [
  [[0,0],[600,0],[600,30],[0,30]],
  [[0,0],[600,0],[140,400],[100,400]],
  [[0,0],[600,0],[620,20],[20,20]],
  [[0,0],[600,400],[600,0],[0,400]],
  [[0,0],[30,0],[30,20],[0,20]],
]) assert.equal(gate(q).ok,false,'Collapsed, extreme perspective, crossed and tiny papers must not register');
console.log('8 registration geometry checks passed');
