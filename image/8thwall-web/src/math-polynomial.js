// Structural degree-two polynomial recognition; sampling cannot establish degree.
export function polynomial2(source,constants={}){
 const compact=source.replace(/\s/g,''),tokens=compact.match(/(?:\d+(?:\.\d*)?|\.\d+|[A-Za-z]+|[()+\-*/^])/g)||[]
 if(tokens.join('')!==compact)return null
 let index=0
 const constant=n=>new Map([['0,0',n]]),clean=p=>{for(const [key,value]of p){if(!Number.isFinite(value))throw Error('Nonfinite coefficient');if(value===0)p.delete(key)}return p}
 function sum(a,b,sign=1){const p=new Map(a);for(const [key,value]of b)p.set(key,(p.get(key)||0)+sign*value);return clean(p)}
 function multiply(a,b){const p=new Map();for(const [ka,va]of a)for(const [kb,vb]of b){const aa=ka.split(',').map(Number),bb=kb.split(',').map(Number),x=aa[0]+bb[0],y=aa[1]+bb[1];if(x+y>2)throw Error('Degree exceeds two');const key=`${x},${y}`;p.set(key,(p.get(key)||0)+va*vb)}return clean(p)}
 const scalar=p=>p.size===0?0:p.size===1&&p.has('0,0')?p.get('0,0'):null
 function expression(){let a=term();while(['+','-'].includes(tokens[index])){const op=tokens[index++];a=sum(a,term(),op==='+'?1:-1)}return a}
 function term(){let a=unary();while(['*','/'].includes(tokens[index])||tokens[index]&&(/^[A-Za-z\d.]/.test(tokens[index])||tokens[index]==='(')){const op=['*','/'].includes(tokens[index])?tokens[index++]:'*',b=unary();if(op==='*')a=multiply(a,b);else{const n=scalar(b);if(n===null||n===0)throw Error('Polynomial denominator must be a nonzero constant');a=clean(new Map([...a].map(([key,value])=>[key,value/n])))}}return a}
 function unary(){if(tokens[index]==='-'){index++;return multiply(constant(-1),unary())}if(tokens[index]==='+'){index++;return unary()}return power()}
 function power(){let a=atom();if(tokens[index]==='^'){index++;const n=scalar(unary());if(n===null||!Number.isInteger(n)||n<0||n>2)throw Error('Unsupported polynomial power');const base=a;a=constant(1);for(let i=0;i<n;i++)a=multiply(a,base)}return a}
 function atom(){const token=tokens[index++];if(token==='('){const a=expression();if(tokens[index++]!==')')throw Error('Missing parenthesis');return a}if(/^(?:\d|\.\d)/.test(token||''))return constant(Number(token));if(token==='x')return new Map([['1,0',1]]);if(token==='y')return new Map([['0,1',1]]);if(token==='pi')return constant(Math.PI);if(Object.hasOwn(constants,token)&&Number.isFinite(constants[token]))return constant(constants[token]);throw Error('Unsupported polynomial symbol')}
 try{const p=clean(expression());if(index!==tokens.length)return null;return {constant:p.get('0,0')||0,x:p.get('1,0')||0,y:p.get('0,1')||0,xx:p.get('2,0')||0,xy:p.get('1,1')||0,yy:p.get('0,2')||0}}catch{return null}
}
