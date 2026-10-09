import Foundation

/// Explicit teaching mechanisms, independent of the inferred appearance mesh. No learned rig claim.
struct DomainInteractionState {
 static let ids = ["solar-system","car","cell","dna","mountain-river","machine","origami","arithmetic","storybook","water-cycle","pendulum","lever","pulley","wind-turbine","hydro-turbine","piston","bridge","electromagnet","electric-motor","lunar-phases","eclipse","atom","water-molecule","carbon-dioxide","neuron","heart","lungs","bacterium","butterfly","fish","turtle","dinosaur","tree-growth","mushroom","snowflake","crystal-growth","fractions","geometry-net","storybook-space"]
 let id:String
 var parameter=0.5,time=0.0,stage=0,playing=true
 mutating func advance(_ dt:Double) {if playing,dt.isFinite,dt>0 {time += min(dt,0.1)}}
 mutating func setParameter(_ value:Double) {if value.isFinite {parameter=min(1,max(0,value))}}
 mutating func event() {stage=(stage+1)%3}
 mutating func reset() {parameter=0.5;time=0;stage=0;playing=true}
 var frequency:Double {0.5+3*parameter}
 var phase:Double {time*frequency}
 var foldAngle:Double {parameter * .pi/2}
 var gearAngles:(Double,Double) {(phase,-phase/2)} // author-defined 2:1 gear relation
 var grouping:(left:Int,right:Int) {stage==0 ? (5,0) : (2,3)}
 var label:String {
  switch id {
  case "solar-system","lunar-phases","eclipse","atom":return String(format:"orbit rate %.2f · phase %.2f rad",frequency,phase)
  case "car","fish","turtle","dinosaur":return String(format:"direction %.0f° · speed %.2f",(parameter-0.5)*90,frequency)
  case "origami","geometry-net":return String(format:"authored fold %.0f°",foldAngle*180 / .pi)
  case "arithmetic":return "5 source blocks → authored 2 + 3 · separated \(stage != 0)"
  case "machine":return "driver/follower = −2:1 · author-defined gears"
  case "dna":return String(format:"strand separation %.0f%%",parameter*100)
  case "mountain-river":return String(format:"rain/flow %.0f%%",parameter*100)
  case "cell","bacterium":return "simplified compartments · reveal stage \(stage)"
  case "storybook","storybook-space","water-cycle":return "authored narrative/cycle stage \(stage+1)/3"
  case "heart":return String(format:"scripted pulse %.0f/min",frequency*60)
  case "lungs":return String(format:"inflation %.0f%%",parameter*100)
  case "fractions":return "4 pieces · separated \(stage != 0)"
  default:return String(format:"authored mechanism · parameter %.0f%% · stage %d",parameter*100,stage)
  }
 }
}
