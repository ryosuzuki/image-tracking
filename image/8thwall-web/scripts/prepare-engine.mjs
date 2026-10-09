import {cp, mkdir} from 'node:fs/promises'
await mkdir('public/engine', {recursive: true})
await cp('node_modules/@8thwall/engine/dist', 'public/engine', {recursive: true})
console.log('Copied official open-source @8thwall/engine artifacts (no engine-binary).')
