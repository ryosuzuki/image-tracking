import {createHash} from 'node:crypto'
import sharp from 'sharp'
import {mkdir,writeFile,cp,readFile} from 'node:fs/promises'
import {applyCrop} from '@8thwall/image-target-cli/src/apply.js'
const math=process.env.MATH_SOURCE||'../../work/augmented-math'
let previous=[];try{previous=JSON.parse(await readFile('public/targets.json'))}catch{}
const manifest=[];await mkdir('public/originals',{recursive:true})
const entries=[]
for(let n=1;n<=10;n++)entries.push({label:`Augmented Math sample ${String(n).padStart(2,'0')}`,file:`${math}/public/sample/sample-${String(n).padStart(2,'0')}.jpg`,sourcePath:`public/sample/sample-${String(n).padStart(2,'0')}.jpg`,pdf:`${math}/public/sample/sample-${String(n).padStart(2,'0')}.pdf`,kind:'Original textbook page from Augmented Math',project:'https://github.com/ucalgary-ilab/augmented-math',shape:n===1?'original-parabola':'quadratic'})
for(let n=2;n<=7;n++)entries.push({label:`Augmented Math original figure ${n}`,file:`${math}/public/sample/figure-${String(n).padStart(2,'0')}.jpg`,sourcePath:`public/sample/figure-${String(n).padStart(2,'0')}.jpg`,kind:'Original extracted math figure',project:'https://github.com/ucalgary-ilab/augmented-math',shape:'sine'})
for(const [label,crop] of [['Experiments',[.035,.025,.45,.155]],['Animated diagrams',[.035,.305,.45,.12]],['Bi-directional binding',[.075,.724,.42,.112]],['Optics',[.515,.59,.46,.11]]])entries.push({label:`Augmented Physics · ${label}`,file:'../../work/physics-original-05.png',crop,sourcePath:'arXiv:2405.18614 page 5, published figure crop',kind:'Original physics paper figure (includes published augmentation graphics)',project:'https://arxiv.org/abs/2405.18614',shape:'circle'})
for(let i=0;i<entries.length;i++){
 const e=entries[i],number=i+1,name=`original-${String(number).padStart(2,'0')}`
 let image=sharp(e.file),m=await image.metadata()
 if(i===0){image=sharp(`${math}/public/sample/figure-01.jpg`);m=await image.metadata();e.sourcePath='public/sample/figure-01.jpg';e.kind='Original extracted figure asset from Augmented Math sample 01';await image.clone().resize(900,1200,{fit:'contain',background:'white'}).png().toFile('public/originals/original-01-present.png')}
 if(e.crop){const [x,y,w,h]=e.crop;const rect={left:Math.round(m.width*x),top:Math.round(m.height*y),width:Math.round(m.width*w),height:Math.round(m.height*h)};image=image.extract(rect);m={width:rect.width,height:rect.height}}
 const scale=Math.min(900/m.width,1200/m.height),offsetX=(900-m.width*scale)/2,offsetY=(1200-m.height*scale)/2
 if(e.crop)await image.resize({height:640}).png().toFile(`public/originals/${name}.png`);else await image.resize(900,1200,{fit:'contain',background:'white'}).png().toFile(`public/originals/${name}.png`)
 if(e.pdf)await cp(e.pdf,`public/originals/${name}.pdf`)
 const prepared=await sharp(`public/originals/${name}.png`).metadata(),rotated=prepared.width>prepared.height;await applyCrop(sharp(`public/originals/${name}.png`),{type:'PLANAR',geometry:{left:0,top:0,width:rotated?prepared.height:prepared.width,height:rotated?prepared.width:prepared.height,isRotated:rotated,originalWidth:rotated?prepared.height:prepared.width,originalHeight:rotated?prepared.width:prepared.height}},'public/image-targets',name,true)
 const t={number,name,aspect:prepared.width/prepared.height,label:e.label,shape:e.shape,color:`hsl(${number*43%360},95%,60%)`,image:i===0?'/originals/original-01-present.png':`/originals/${name}.png`,data:`/image-targets/${name}.json`,source:{project:e.project,path:e.sourcePath,kind:e.kind,upstreamCommit:e.project.includes('augmented-math')?'9ebf72a8ccb4844707bb87be34b31f201cbbcf00':undefined,padding:e.crop?'Original published crop at natural aspect ratio; no added margins':i===0?'Original figure scaled to fit; white margins only':'Original image scaled to fit 900 x 1200; white margins only'}}
 if(i===0)t.graph={originX:(1028*scale-450)/1200,originY:(600-(949*scale+offsetY))/1200,unit:24*scale/1200,equation:'y = (x + h)² + k',defaultH:3,defaultK:1,sourceExample:'Sample 01 Example 2 and Figure 5; original equation x² + 6x + 10 = (x + 3)² + 1'}
 if(rotated)t.trackingReference={revision:2,orientation:'Official CLI90-degree portrait reference; original source and camera presentation remain landscape',canonicalPlane:'Target height one; width equals source aspect',scaledHeight:prepared.height/prepared.width}
 if(number===19){t.assetRevision=2;t.source.path='arXiv:2405.18614 page5 Figure4, published diagram and caption crop';t.source.previousRevision=previous.find(p=>p.number===19)?.source.previousRevision}
 t.source.imageSHA256=createHash('sha256').update(await readFile('public'+t.image)).digest('hex')
 manifest.push(t);console.log(`${number} ${e.label}`)
}
await writeFile('public/targets.json',JSON.stringify(manifest,null,2)+'\n')
