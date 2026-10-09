const compact=new URLSearchParams(location.search).get('compact')==='1';if(compact)document.body.classList.add('compact')
const targets=await fetch('/targets.json').then(r=>r.json())
const choose=document.querySelector('#choose'),image=document.querySelector('#card'),title=document.querySelector('#title'),auto=document.querySelector('#auto')
const brightness=document.querySelector('#brightness');brightness.value=new URLSearchParams(location.search).get('brightness')||(compact?.22:.65);const setBrightness=()=>image.style.filter=`brightness(${brightness.value})`;brightness.oninput=setBrightness;setBrightness()
let index=Number(new URLSearchParams(location.search).get('target')||1)-1,timer
index=Math.max(0,Math.min(targets.length-1,index))
for(const t of targets){const option=document.createElement('option');option.value=t.number-1;option.textContent=`${String(t.number).padStart(2,'0')} ${t.label}`;choose.append(option);const preload=new Image();preload.src=t.image}
function show(n){index=(n+targets.length)%targets.length;const t=targets[index];choose.value=index;if(compact){const portrait=t.aspect<1;image.style.width=portrait?'390px':'520px';image.style.height=portrait?'520px':'390px';image.style.transform=portrait?'rotate(90deg)':'none';image.style.marginTop=portrait?'-65px':'0';image.style.marginBottom=portrait?'-65px':'0'}image.src=t.image;image.alt=`${t.number} ${t.label} math tracking target`;title.textContent=`${t.number} / ${targets.length} · ${t.label}`;document.body.dataset.target=t.name;history.replaceState(null,'',`?target=${t.number}${compact?'&compact=1':''}`);fetch('/api/presenter-event',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({target:t.name,number:t.number,unixMs:Date.now(),at:performance.now(),intervalSeconds:Number(document.querySelector('#interval').value)})}).catch(()=>{})}
function toggleAuto(){if(timer){clearInterval(timer);timer=null;auto.textContent='Auto advance'}else{const seconds=Math.max(4,Number(document.querySelector('#interval').value)||5);timer=setInterval(()=>show(index+1),seconds*1000);auto.textContent='Pause auto advance'}}
document.querySelector('#prev').onclick=()=>show(index-1);document.querySelector('#next').onclick=()=>show(index+1);choose.onchange=()=>show(Number(choose.value));auto.onclick=toggleAuto
const full=()=>document.fullscreenElement?document.exitFullscreen():document.documentElement.requestFullscreen()
document.querySelector('#full').onclick=full
addEventListener('keydown',e=>{if(e.target.matches('input,select'))return;if(e.key==='ArrowRight')show(index+1);if(e.key==='ArrowLeft')show(index-1);if(e.key===' '){e.preventDefault();toggleAuto()}if(e.key.toLowerCase()==='f')full()})
show(index)
