// Responses derive from OCR text, never from marker IDs.
export function responseFor(text){
 const s=text.toUpperCase().replace(/[^A-Z0-9+*/.()\- ]/g,' ').replace(/\s+/g,' ').trim();
 const arithmetic=s.match(/(?:CALCULATE\s*)?(\d+(?:\.\d+)?)\s*([+*/-])\s*(\d+(?:\.\d+)?)/);
 if(arithmetic){const a=Number(arithmetic[1]),b=Number(arithmetic[3]),op=arithmetic[2];const n=op==='+'?a+b:op==='-'?a-b:op==='*'?a*b:b?a/b:null;return {kind:'math',label:n===null?'Division by zero':`${a} ${op} ${b} = ${Number(n.toFixed(4))}`,color:'#a78bfa',symbol:'∑'};}
 if(/\bSUN\b/.test(s))return {kind:'sun',label:'SUN → sunshine animation',color:'#facc15',symbol:'☀'};
 if(/\bTREE\b/.test(s))return {kind:'tree',label:'TREE → growing tree',color:'#4ade80',symbol:'🌳'};
 if(/\bMUSIC\b/.test(s))return {kind:'music',label:'MUSIC → moving notes',color:'#38bdf8',symbol:'♫'};
 return {kind:'text',label:text.trim()?'Read: '+text.trim():'No readable text. Move closer and try again.',color:'#fff',symbol:'✎'};
}
