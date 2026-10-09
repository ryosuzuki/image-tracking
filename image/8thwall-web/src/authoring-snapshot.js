const scope='#math-controls, #physics-controls, #sketch-controls, #canvas-controls, #body-controls'
export function isAuthoringControl(element){return !!element?.id&&(element.id==='mode'||element.closest?.(scope))&&['INPUT','SELECT','TEXTAREA'].includes(element.tagName)&&!['file','password','hidden'].includes(element.type)}
export function controlValue(element){return element.type==='checkbox'?element.checked:String(element.value??'').slice(0,4096)}
export function authoringSnapshot(document, target, replay){
 const controls={};for(const element of document.querySelectorAll('#mode, '+scope.split(', ').map(s=>s+' input, '+s+' select, '+s+' textarea').join(', ')))if(isAuthoringControl(element))controls[element.id]=controlValue(element)
 return {schemaVersion:1,scope:'Authoring controls and current graph configuration; drawn geometry, binding references and simulation state are not serialized',controls,target:target?{name:target.name,aspect:target.aspect,planeBasis:'Target height one; width equals original source aspect',graph:target.graph?JSON.parse(JSON.stringify(target.graph)):null}:null,replay:replay?{sourceTime:replay.sourceTime,paused:replay.paused,epoch:replay.epoch}:null}
}
