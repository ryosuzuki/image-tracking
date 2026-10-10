import test from 'node:test';
import assert from 'node:assert/strict';
import {setCodebook,CODEBOOK,decodeObserved,READER_OPTIONS,setWhiteNormalize} from './color-code.mjs?v=iter-20261010-j';
import {GEOMETRY_OPTIONS,setWhiteFallback,selectWhiteNormalizedObservation} from './color-detector.mjs?v=iter-20261010-j';

test('white normalization and supplemental calibration default off; setters reject nonboolean',()=>{
 assert.equal(READER_OPTIONS.whiteNormalize,false);assert.equal(GEOMETRY_OPTIONS.whiteFallback,false);
 for(const v of [null,undefined,0,1,'true',{}]){assert.throws(()=>setWhiteNormalize(v),TypeError);assert.throws(()=>setWhiteFallback(v),TypeError);}
 setWhiteNormalize(true);setWhiteFallback(true);setWhiteNormalize(false);setWhiteFallback(false);
});
test('successful primary and primary conflicts never replaced; original symbols immutable',()=>{
 setCodebook('balanced');
 for(const w of CODEBOOK){const good={symbols:[...w.symbols],conflict:false};const missing={symbols:Array(7).fill(null),conflict:false};const before=JSON.stringify(good);
 assert.equal(selectWhiteNormalizedObservation(good,good),null);
 assert.equal(selectWhiteNormalizedObservation({...missing,conflict:true},good),null);
 assert.equal(selectWhiteNormalizedObservation(missing,{...good,conflict:true}),null);
 assert.equal(selectWhiteNormalizedObservation(null,good),null);
 assert.equal(selectWhiteNormalizedObservation(missing,good),good);
 assert.equal(JSON.stringify(good),before);
 }
});
test('ambiguous projections and blank observations cannot supply supplemental ID',()=>{
 setCodebook('balanced');const blank={symbols:Array(7).fill(null),conflict:false};assert.equal(selectWhiteNormalizedObservation(blank,blank),null);
 for(let a=0;a<CODEBOOK.length;a++)for(let b=a+1;b<CODEBOOK.length;b++){
 const symbols=CODEBOOK[a].symbols.map((v,i)=>v===CODEBOOK[b].symbols[i]?v:null);
 assert.equal(decodeObserved(symbols),null);assert.equal(selectWhiteNormalizedObservation(blank,{symbols,conflict:false}),null);
 }
});
