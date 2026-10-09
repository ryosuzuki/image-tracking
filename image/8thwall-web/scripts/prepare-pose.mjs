import {createHash} from 'node:crypto'
import assert from 'node:assert/strict'
import {cp,mkdir,readFile,writeFile} from 'node:fs/promises'
await mkdir('public/pose/wasm',{recursive:true})
await cp('node_modules/@mediapipe/tasks-vision/wasm','public/pose/wasm',{recursive:true})
console.log('Copied pinned MediaPipe WASM; bundled pose model retained locally.')
const provenance=JSON.parse(await readFile('public/pose/provenance.json'));
try { await readFile('public/pose/pose_landmarker_lite.task') } catch (error) {
  if (error.code !== 'ENOENT') throw error
  const response = await fetch(provenance.model.source)
  if (!response.ok) throw new Error('Official pose model download failed: '+response.status)
  const bytes = Buffer.from(await response.arrayBuffer())
  assert.equal(createHash('sha256').update(bytes).digest('hex'), provenance.model.sha256, 'Downloaded model hash mismatch')
  await writeFile('public/pose/pose_landmarker_lite.task', bytes)
}
assert.equal(createHash('sha256').update(await readFile('public/pose/pose_landmarker_lite.task')).digest('hex'),provenance.model.sha256,'Pose model hash mismatch')
