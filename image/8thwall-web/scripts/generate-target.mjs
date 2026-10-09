import sharp from 'sharp'
import {mkdir, writeFile} from 'node:fs/promises'
import {spawnSync} from 'node:child_process'
await mkdir('public/image-targets', {recursive: true})
// Original vector artwork: asymmetric high-contrast geometry and math, no remote assets.
let seed = 731
const random = () => ((seed = (seed * 1664525 + 1013904223) >>> 0) / 4294967296)
let marks = ''
for (let i = 0; i < 130; i++) {
  const x = 40 + random() * 640, y = 250 + random() * 650, r = 4 + random() * 20
  marks += i % 2 ? `<circle cx="${x}" cy="${y}" r="${r}" fill="none" stroke="#152940" stroke-width="4"/>` : `<path d="M${x},${y} l${r},${r*1.5} l${-r*1.8},${r*.3} Z" fill="#152940"/>`
}
const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="720" height="960"><rect width="720" height="960" fill="#fff"/><rect x="16" y="16" width="688" height="928" fill="none" stroke="#152940" stroke-width="8"/><text x="50" y="100" font-family="sans-serif" font-size="48" font-weight="bold">AUGMENTED MATH</text><text x="50" y="160" font-family="sans-serif" font-size="32">Image tracking test · 01</text><path d="M50 210 H660" stroke="#152940" stroke-width="5"/>${marks}<rect x="155" y="410" width="410" height="155" fill="white" stroke="#152940" stroke-width="6"/><text x="190" y="510" font-family="sans-serif" font-size="60">y = x² + 1</text><path d="M60 875 L60 710 M60 875 H240 M70 860 Q140 855 210 730" fill="none" stroke="#152940" stroke-width="6"/></svg>`
await writeFile('public/target.svg', svg)
await sharp(Buffer.from(svg)).png().toFile('public/target.png')
const input = 'public/target.png\n1\ny\npublic/image-targets\nmath-card\n'
const result = spawnSync(process.execPath, ['node_modules/@8thwall/image-target-cli/src/index.js'], {
  input, encoding: 'utf8', env: {...process.env, OVERWRITE_FILES: 'true'},
})
console.log(result.stdout)
if (result.status !== 0) throw new Error(result.stderr || 'Official target CLI failed')
