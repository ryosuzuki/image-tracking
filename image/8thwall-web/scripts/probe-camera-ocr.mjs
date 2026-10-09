import {readFile,writeFile,mkdir} from 'node:fs/promises'
import {execFileSync} from 'node:child_process'
import sharp from 'sharp'
import {resolve} from 'node:path'
const root=resolve('../..')
const gallery=JSON.parse(await readFile(root+'/outputs/demo/evidence/gallery-c920-complete.json'))
await mkdir(root+'/work/ocr-probes',{recursive:true});const rows=[]
for(const id of [6,7,8,9,10,19,20]){
 const row=gallery.rows.find(r=>r.number===id),file=root+'/work/ocr-probes/target-'+id+'.png'
 execFileSync('ffmpeg',['-y','-hide_banner','-loglevel','error','-ss',String(row.startSeconds+2),'-i',root+'/work/captures/'+gallery.session+'/raw.webm','-frames:v','1','-vf','crop=480:360:600:720',file])
 for(const method of ['native','sharpen','threshold']){
  let p=sharp(file);if(method!=='native')p=p.resize(1440,1080).grayscale().normalize().sharpen({sigma:1,m1:1,m2:3});if(method==='threshold')p=p.threshold(150)
  const pixels=await p.png().toBuffer(),response=await fetch('http://localhost:5173/api/source-ocr',{method:'POST',body:pixels});const result=await response.json();rows.push({id,method,physicalCamera:true,sourceTime:row.startSeconds+2,lines:result.lines||[],error:result.error});console.log(JSON.stringify({id,method,lines:result.lines?.length,text:result.lines?.map(l=>l.text).slice(0,4)}))
 }
 await writeFile(root+'/work/ocr-probes/results.json',JSON.stringify({source:'Original complete C920 native gallery recording; deterministic contrast/sharpness only',session:gallery.session,rows},null,2))
}
