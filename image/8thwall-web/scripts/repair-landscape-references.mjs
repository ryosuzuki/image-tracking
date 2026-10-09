import sharp from 'sharp'
import {applyCrop} from '@8thwall/image-target-cli/src/apply.js'
import {readFile,writeFile} from 'node:fs/promises'
const targets=JSON.parse(await readFile('public/targets.json'))
for(const t of targets){const image=sharp('public'+t.image),m=await image.metadata();if(m.width<=m.height)continue;await applyCrop(image,{type:'PLANAR',geometry:{left:0,top:0,width:m.height,height:m.width,isRotated:true,originalWidth:m.height,originalHeight:m.width}},'public/image-targets',t.name,true);t.trackingReference={revision:2,orientation:'Official CLI90-degree portrait reference; original source and camera presentation remain landscape',canonicalPlane:'Target height one; width equals source aspect',scaledHeight:m.height/m.width};console.log(JSON.stringify({name:t.name,aspect:t.aspect,scaledHeight:t.trackingReference.scaledHeight}))}await writeFile('public/targets.json',JSON.stringify(targets,null,2)+'\n')
