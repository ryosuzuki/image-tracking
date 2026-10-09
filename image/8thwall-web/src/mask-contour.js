import {inkContours} from './source-geometry.js'
export function confidenceShape({width,height,data},threshold=.5){
 if(!Number.isInteger(width)||!Number.isInteger(height)||width<=0||height<=0||data.length!==width*height)return null
 const rgba=new Uint8ClampedArray(width*height*4),cut=Math.max(0,Math.min(255,Math.ceil(threshold*255)));let pixels=0,minX=width,minY=height,maxX=-1,maxY=-1
 for(let i=0;i<data.length;i++)if(data[i]>=cut){rgba[i*4+3]=255;pixels++;const x=i%width,y=Math.floor(i/width);minX=Math.min(minX,x);minY=Math.min(minY,y);maxX=Math.max(maxX,x);maxY=Math.max(maxY,y)}
 const components=inkContours({width,height,data:rgba}),loops=components.flatMap(c=>[c.outer,...c.holes]);return {width,height,rgba,pixels,components,loops,bounds:pixels?{minX,minY,maxX,maxY}:null}
}
export function drawContourShape(ctx,shape,{width,height,color='#35ffcf',opacity=.25,fill=false,animated=false,clock=0}={}){
 if(!shape?.pixels)return false
 ctx.save();ctx.strokeStyle=color;ctx.fillStyle=color;ctx.lineWidth=2;ctx.beginPath();for(const loop of shape.loops){loop.forEach((p,i)=>{const x=p.x/shape.width*width,y=p.y/shape.height*height;i?ctx.lineTo(x,y):ctx.moveTo(x,y)});ctx.closePath()}
 if(fill){ctx.globalAlpha=opacity;ctx.fill('evenodd');ctx.globalAlpha=1}
 if(animated){ctx.setLineDash([12,8]);ctx.lineDashOffset=-(clock/25)%20}ctx.stroke();ctx.restore();return true
}
