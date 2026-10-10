// Conservative image-space registration gate, not a camera-pose estimate.
export function registrationQuality(q) {
  if (!q || q.length !== 4 || q.some(p => p.length !== 2 || p.some(v => !Number.isFinite(v)))) return {ok:false, reason:'Four visible corners required'};
  const edges=q.map((p,i)=>Math.hypot(p[0]-q[(i+1)%4][0],p[1]-q[(i+1)%4][1]));
  const crosses=q.map((p,i)=>{const a=q[(i+1)%4],b=q[(i+2)%4];return (a[0]-p[0])*(b[1]-a[1])-(a[1]-p[1])*(b[0]-a[0]);});
  if (!crosses.every(v=>v>0)&&!crosses.every(v=>v<0)) return {ok:false,reason:'Corners do not form a convex paper'};
  if(Math.min(...edges)<40) return {ok:false,reason:'Move closer: paper is too small'};
  const angles=q.map((p,i)=>{const a=q[(i+3)%4],b=q[(i+1)%4];const dot=(a[0]-p[0])*(b[0]-p[0])+(a[1]-p[1])*(b[1]-p[1]);return Math.acos(Math.max(-1,Math.min(1,dot/(edges[(i+3)%4]*edges[i]))))*180/Math.PI;});
  const ratio=(a,b)=>Math.max(a,b)/Math.min(a,b);
  if(Math.min(...angles)<40||Math.max(...angles)>140||Math.max(...edges)/Math.min(...edges)>4||ratio(edges[0],edges[2])>2.5||ratio(edges[1],edges[3])>2.5) return {ok:false,reason:'Too skewed: face the paper more directly'};
  return {ok:true,reason:'Ready to read'};
}
