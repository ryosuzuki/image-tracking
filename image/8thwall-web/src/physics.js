export function pendulumStep(state,dt,{length=1,gravity=9.81,damping=0}={}){
 const f=([a,w])=>[w,-gravity/length*Math.sin(a)-damping*w],s=[state.angle,state.velocity],add=(a,b,c)=>a.map((v,i)=>v+c*b[i]),k1=f(s),k2=f(add(s,k1,dt/2)),k3=f(add(s,k2,dt/2)),k4=f(add(s,k3,dt));return {angle:s[0]+dt/6*(k1[0]+2*k2[0]+2*k3[0]+k4[0]),velocity:s[1]+dt/6*(k1[1]+2*k2[1]+2*k3[1]+k4[1])}
}
export const pendulumEnergy=(s,{length=1,mass=1,gravity=9.81}={})=>mass*gravity*length*(1-Math.cos(s.angle))+.5*mass*length**2*s.velocity**2
export function thinLens(focal,objectDistance){if(Math.abs(objectDistance-focal)<1e-8)return {imageDistance:Infinity,magnification:Infinity};const imageDistance=focal*objectDistance/(objectDistance-focal);return {imageDistance,magnification:-imageDistance/objectDistance}}
export function projectile(t,{speed=5,angle=Math.PI/4,gravity=9.81}={}){return {x:speed*Math.cos(angle)*t,y:speed*Math.sin(angle)*t-.5*gravity*t*t,vx:speed*Math.cos(angle),vy:speed*Math.sin(angle)-gravity*t}}
export function circuit(voltage,resistance){return {current:voltage/resistance,power:voltage**2/resistance}}
