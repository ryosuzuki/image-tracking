import {isShiftedPower} from './math-power.js'
import {parseExpression} from './math-semantics.js'
import {polynomial2} from './math-polynomial.js'
export function latexToExpression(latex){
 let s=latex.replace(/\\(?:left|right)/g,'').replace(/\\(?:sin|cos|sqrt|log|exp)/g,x=>x.slice(1)).replace(/\^\{([^{}]+)\}/g,'^($1)')
 for(let i=0;i<5;i++)s=s.replace(/\\frac\{([^{}]+)\}\{([^{}]+)\}/g,'(($1)/($2))')
 return s.replace(/\{/g,'(').replace(/\}/g,')').replace(/\\pi/g,'pi').replace(/\\cdot/g,'*').replace(/\\,/g,'').replace(/\s+/g,'')
}
export function identifyEquation(latex){
 const flat=latexToExpression(latex)
 if(/[<>]/.test(flat))return {family:'algebra',expression:flat}
 if(/^a\^\(?2\)?\+b\^\(?2\)?=c\^\(?2\)?$/.test(flat))return {family:'triangle'}
 const parts=flat.split('='),rhs=parts.at(-1)
 if(parts.length<2)return {family:'unsupported',expression:flat}
 if(!['y','f(x)','g(x)','h(x)','P(x)'].includes(parts[0])){
  const left=polynomial2(parts[0],{h:0,k:0,r:2}),right=polynomial2(rhs,{h:0,k:0,r:2})
  if(left&&right){const p=Object.fromEntries(Object.keys(left).map(key=>[key,left[key]-right[key]])),{constant:c,x:bx,y:by,xx:ax,yy:ay,xy}=p
   if(ax===0&&ay===0&&xy===0&&by!==0)return {family:'function',expression:`${-bx/by}*x+${-c/by}`,slope:-bx/by,intercept:-c/by}
   if(ax!==0&&ax===ay&&xy===0){const h=-bx/(2*ax),k=-by/(2*ax),rSquared=h*h+k*k-c/ax;if(Number.isFinite(rSquared)&&rSquared>0)return {family:'circle',h,k,r:Math.sqrt(rSquared),expression:'sqrt(r^2-(x-h)^2)+k'}}
  }
  return {family:'algebra',expression:flat}
 }
 try{
  if(isShiftedPower(rhs))return{family:'power',expression:rhs}
  const p=polynomial2(rhs,{h:0,k:0,r:1}),a=p?.xx,b=p?.x,c=p?.constant
  if(p&&a!==0&&p.y===0&&p.xy===0&&p.yy===0)return {family:'quadratic',a,b,c,h:b/(2*a),k:c-b*b/(4*a),expression:`${a}*(x+h)^2+k`}
  parseExpression(rhs)({x:0,h:0,k:0,r:1,a:3,b:4,n:2})
  return {family:'function',expression:rhs}
 }catch{return {family:'unsupported',expression:flat}}
}
