import test from 'node:test';import assert from 'node:assert/strict';
import {GOLAY24_BOOK,GOLAY24_OPTIONS,mergeGolayLowMass,decodeGolay24} from './golay24-code.mjs';
const opts={...GOLAY24_OPTIONS},obs=bits=>({bits,conflict:false});
test('default opt-ins disabled',()=>{assert.equal(opts.lowMassFallback,false);assert.equal(opts.lowMassCascade,false);});
test('fills erasures only with unique existing code',()=>{for(const w of GOLAY24_BOOK){const p=obs(w.bits.map((b,i)=>i<4?null:b)),c=obs(w.bits.map((b,i)=>i<2?null:b));assert.equal(decodeGolay24(p.bits,opts),null);assert.equal(decodeGolay24(c.bits,opts).id,w.id);assert.equal(mergeGolayLowMass(p,c,opts),c);}});
test('successful primary never replaced',()=>{const w=GOLAY24_BOOK[0];assert.equal(mergeGolayLowMass(obs(w.bits),obs(w.bits),opts),null);});
test('known contradictions and either conflict rejected',()=>{const w=GOLAY24_BOOK[0],p=obs(w.bits.map((b,i)=>i<4?null:b)),c=obs([...w.bits]);c.bits[5]^=1;assert.equal(mergeGolayLowMass(p,c,opts),null);assert.equal(mergeGolayLowMass({...p,conflict:true},obs(w.bits),opts),null);assert.equal(mergeGolayLowMass(p,{...obs(w.bits),conflict:true},opts),null);});
test('blank gray and missing primary never guessed',()=>{for(const bits of [Array(24).fill(0),Array(24).fill(1),Array(24).fill(null)])assert.equal(mergeGolayLowMass(obs(Array(24).fill(null)),obs(bits),opts),null);assert.equal(mergeGolayLowMass(null,obs(GOLAY24_BOOK[0].bits),opts),null);});
