import sharp from 'sharp'
import {spawn} from 'node:child_process'
import {mkdir} from 'node:fs/promises'
import {once} from 'node:events'
await mkdir('.test-fixtures', {recursive: true})
const file = '.test-fixtures/math-card.y4m'
const ffmpeg = spawn('ffmpeg', ['-y', '-f','rawvideo','-pix_fmt','rgb24','-s','640x480','-r','15','-i','pipe:0','-pix_fmt','yuv420p',file], {stdio:['pipe','ignore','pipe']})
let error = ''; ffmpeg.stderr.on('data', x => error += x)
const target = await sharp('public/target.png').resize(270,360).png().toBuffer()
for (let i = 0; i < 450; i++) {
  const visible = i >= 30 && i < 195 || i >= 270
  const image = sharp({create:{width:640,height:480,channels:3,background:'#b8b6ae'}})
  if (visible) image.composite([{input:target,left:Math.round(185+25*Math.sin(i/40)),top:Math.round(60+12*Math.cos(i/50))}])
  const frame = await image.removeAlpha().raw().toBuffer()
  if (!ffmpeg.stdin.write(frame)) await once(ffmpeg.stdin, 'drain')
}
ffmpeg.stdin.end()
const [code] = await once(ffmpeg,'exit')
if (code) throw Error(error)
console.log(`Generated 30-second synthetic camera: ${file}`)
