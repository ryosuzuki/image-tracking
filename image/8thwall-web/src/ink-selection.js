// Select one connected non-white component from prepared source pixels.
// The seed is user chosen. This is topology selection, not semantic segmentation.
export function selectInkComponent(image,seed,{threshold=235,radius=12,minPixels=4}={}){
 const {width,height,data}=image
 if(!Number.isInteger(width)||!Number.isInteger(height)||width<1||height<1||data?.length!==width*height*4||!Number.isFinite(seed?.x)||!Number.isFinite(seed?.y))return null
 const ink=i=>data[i*4+3]>0&&(data[i*4]<threshold||data[i*4+1]<threshold||data[i*4+2]<threshold)
 const cx=Math.round(seed.x),cy=Math.round(seed.y);let start=-1,best=Infinity
 for(let y=Math.max(0,cy-radius);y<=Math.min(height-1,cy+radius);y++)for(let x=Math.max(0,cx-radius);x<=Math.min(width-1,cx+radius);x++){const d=(x-seed.x)**2+(y-seed.y)**2;if(d<=radius**2&&d<best&&ink(y*width+x)){best=d;start=y*width+x}}
 if(start<0)return null
 const mask=new Uint8Array(width*height),queue=new Int32Array(width*height);let head=0,tail=1,minX=width,minY=height,maxX=0,maxY=0;queue[0]=start;mask[start]=1
 while(head<tail){const i=queue[head++],x=i%width,y=Math.floor(i/width);minX=Math.min(minX,x);maxX=Math.max(maxX,x);minY=Math.min(minY,y);maxY=Math.max(maxY,y)
  for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){const xx=x+dx,yy=y+dy;if(xx<0||xx>=width||yy<0||yy>=height)continue;const j=yy*width+xx;if(!mask[j]&&ink(j)){mask[j]=1;queue[tail++]=j}}
 }
 if(tail<minPixels)return null
 return {mask,width,height,pixels:tail,bounds:{x0:Math.max(0,minX-2),y0:Math.max(0,minY-2),x1:Math.min(width,maxX+3),y1:Math.min(height,maxY+3)},seed:{x:start%width,y:Math.floor(start/width)},method:'User-seeded connected ink on prepared source image'}
}
