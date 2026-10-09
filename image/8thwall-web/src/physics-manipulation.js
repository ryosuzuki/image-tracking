import * as THREE from 'three'
export function physicsHandles(model,{p1,p2,angle=p2}){
 if(![p1,p2,angle].every(Number.isFinite))return []
 if(model==='pendulum')return[{control:'bob',x:p1*Math.sin(angle)*.09,y:.2-p1*Math.cos(angle)*.09,label:`L=${p1.toFixed(2)}; amplitude=${p2.toFixed(2)} rad`}]
 if(model==='optics')return[{control:'object-distance',x:-p2*.05,y:.12,label:`d=${p2.toFixed(2)}`},{control:'focus-left',x:-p1*.05,y:0,label:`f=${p1.toFixed(2)}`},{control:'focus-right',x:p1*.05,y:0,label:'f'}]
 if(model==='projectile'){const a=p2/10*Math.PI/2;return[{control:'velocity',x:-.25+p1*.05*Math.cos(a),y:-.2+p1*.05*Math.sin(a),label:`v=${p1.toFixed(2)}; θ=${(p2*9).toFixed(1)}°`}]}
 if(model==='circuit')return[{control:'voltage',x:-.2,y:.025,label:`V=${p1.toFixed(2)}`},{control:'resistance',x:.2,y:.025,label:`R=${p2.toFixed(2)}`}]
 return []
}
export function physicsHandleValues(control,p,base){
 if(![p.x,p.y,base.p1,base.p2].every(Number.isFinite))return null
 if(control==='bob'){const angle=Math.atan2(p.x,.2-p.y);return{p1:Math.hypot(p.x,.2-p.y)/.09,p2:Math.abs(angle),angle}}
 if(control==='object-distance')return{p2:-p.x/.05}
 if(control.startsWith('focus-'))return{p1:Math.abs(p.x)/.05}
 if(control==='velocity'){const x=Math.max(0,p.x+.25),y=Math.max(0,p.y+.2);return{p1:Math.hypot(x,y)/.05,p2:Math.atan2(y,x)/(Math.PI/2)*10}}
 if(control==='voltage')return{p1:base.p1+(p.x+.2)*20}
 if(control==='resistance')return{p2:base.p2+(p.x-.2)*40}
 return null
}
export function installPhysicsManipulation({getAnchor,getTarget,getState,apply,setPlaying,isSourceEditing,diagnostics,recordEvent}){
 const screen=document.querySelector('#camera'),ray=new THREE.Raycaster(),plane=new THREE.Plane(),normal=new THREE.Vector3(),point=new THREE.Vector3();let drag
 function available(){return document.querySelector('#mode').value==='physics'&&getAnchor()?.visible&&!diagnostics.sourcePhysics?.active&&!isSourceEditing()}
 function cancel(){if(drag){setPlaying(drag.playing);drag=null}if(diagnostics.physicsHandles)diagnostics.physicsHandles.dragging=false}
 function coherent(){if(drag&&(!available()||getTarget()?.name!==drag.target||getAnchor()!==drag.anchor||getState().model!==drag.model))cancel()}
 function local(e){const anchor=getAnchor();if(!anchor?.visible)return null;normal.set(0,0,1).applyQuaternion(anchor.quaternion);plane.setFromNormalAndCoplanarPoint(normal,anchor.localToWorld(new THREE.Vector3(0,0,.02)));ray.setFromCamera(new THREE.Vector2(e.clientX/innerWidth*2-1,1-e.clientY/innerHeight*2),XR8.Threejs.xrScene().camera);return ray.ray.intersectPlane(plane,point)?anchor.worldToLocal(point.clone()):null}
 function tick(ctx){coherent();const state=getState(),valid=available(),handles=valid?physicsHandles(state.model,state):[],camera=XR8.Threejs.xrScene().camera;const projected=handles.map(h=>{const p=getAnchor().localToWorld(new THREE.Vector3(h.x,h.y,.02)).project(camera);return{...h,screen:{x:(p.x+1)*innerWidth/2,y:(1-p.y)*innerHeight/2}}});diagnostics.physicsHandles={model:state.model,target:getTarget()?.name,visible:valid,dragging:!!drag,method:'Direct manipulation of authored image-anchored simulation; automatic printed-component correspondence pending',handles:projected};if(ctx){ctx.save();ctx.font='12px sans-serif';for(const h of projected){ctx.beginPath();ctx.arc(h.screen.x,h.screen.y,4,0,Math.PI*2);ctx.fillStyle='#ffcc45';ctx.fill();ctx.lineWidth=1.5;ctx.strokeStyle='#10202e';ctx.stroke();const width=ctx.measureText(h.label).width;ctx.fillStyle='rgba(8,22,30,.9)';ctx.fillRect(h.screen.x+8,h.screen.y-22,width+8,18);ctx.fillStyle='#ffe293';ctx.fillText(h.label,h.screen.x+12,h.screen.y-9)}ctx.restore()}}
 function draw(root){if(!available())return;const state=getState();for(const handle of physicsHandles(state.model,state)){const mesh=new THREE.Mesh(new THREE.SphereGeometry(.009,12,8),new THREE.MeshBasicMaterial({color:handle.control==='object-distance'?'#ff75d6':'#ffcc45',depthTest:false}));mesh.position.set(handle.x,handle.y,.02);root.add(mesh)}if(state.model==='projectile'){const h=physicsHandles(state.model,state)[0],geometry=new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(-.25,-.2,.019),new THREE.Vector3(h.x,h.y,.019)]);root.add(new THREE.Line(geometry,new THREE.LineBasicMaterial({color:'#ff75d6',depthTest:false})))} }
 screen.addEventListener('pointerdown',e=>{if(!available())return;const p=local(e);if(!p)return;const state=getState(),nearest=physicsHandles(state.model,state).map(h=>{const q=getAnchor().localToWorld(new THREE.Vector3(h.x,h.y,.02)).project(XR8.Threejs.xrScene().camera);return{...h,distance:Math.hypot((q.x+1)*innerWidth/2-e.clientX,(1-q.y)*innerHeight/2-e.clientY)}}).sort((a,b)=>a.distance-b.distance)[0];if(!nearest||nearest.distance>14)return;drag={target:getTarget().name,anchor:getAnchor(),model:state.model,control:nearest.control,handle:nearest,start:{x:p.x,y:p.y},base:{p1:state.p1,p2:state.p2},pointer:e.pointerId,playing:state.playing};setPlaying(false);screen.setPointerCapture(e.pointerId);recordEvent({name:'physicsdragstart',at:performance.now(),target:drag.target,model:drag.model,control:drag.control,parameters:drag.base});e.stopImmediatePropagation()},true)
 screen.addEventListener('pointermove',e=>{coherent();if(!drag||e.pointerId!==drag.pointer)return;const p=local(e);if(!p){cancel();return}const values=physicsHandleValues(drag.control,{x:drag.handle.x+p.x-drag.start.x,y:drag.handle.y+p.y-drag.start.y},drag.base);if(values){apply(values);recordEvent({name:'physicsdirectdrag',at:performance.now(),target:drag.target,model:drag.model,control:drag.control,parameters:getState(),method:'Authored simulation handle'})}e.stopImmediatePropagation()},true)
 for(const type of ['pointerup','pointercancel','lostpointercapture'])screen.addEventListener(type,cancel,true);for(const id of ['mode','physics-model'])document.querySelector('#'+id).addEventListener('change',cancel)
 return{tick,draw,cancel}
}
