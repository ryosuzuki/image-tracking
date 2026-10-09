import {readFile,writeFile} from 'node:fs/promises'
import {createHash} from 'node:crypto'
const targets=JSON.parse(await readFile('public/targets.json'))
for(const t of targets)t.source.imageSHA256=createHash('sha256').update(await readFile('public'+t.image)).digest('hex')
await writeFile('public/targets.json',JSON.stringify(targets,null,2)+'\n')
console.log('Stamped SHA-256 of '+targets.length+' existing source images; no images modified')
