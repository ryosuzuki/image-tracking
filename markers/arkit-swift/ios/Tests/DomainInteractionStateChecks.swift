import Foundation
@main struct Checks {
 static func main() {
  precondition(Set(DomainInteractionState.ids).count==39)
  var gear=DomainInteractionState(id:"machine");gear.advance(0.1)
  precondition(abs(gear.gearAngles.0+2*gear.gearAngles.1)<1e-12,"opposed 2:1 authored kinematics")
  var fold=DomainInteractionState(id:"origami");fold.setParameter(1)
  precondition(abs(fold.foldAngle - .pi/2)<1e-12,"full fold right angle")
  var count=DomainInteractionState(id:"arithmetic");let before=count.grouping;count.event();let after=count.grouping
  precondition(before.left+before.right==5 && after.left+after.right==5,"five visible source blocks conserve numeric quantity")
  for id in DomainInteractionState.ids {
   var state=DomainInteractionState(id:id);state.advance(0.05);let t=state.time;state.playing=false;state.advance(0.05);precondition(state.time==t,"paused scenes stop evolution")
   state.setParameter(.nan);precondition(state.parameter.isFinite);state.setParameter(10);precondition(state.parameter==1);state.setParameter(-1);precondition(state.parameter==0)
   for _ in 0..<3 {state.event()};precondition(state.stage==0,"story stage cycle wraps")
   state.reset();precondition(state.time==0 && state.stage==0 && state.parameter==0.5 && state.playing)
  }
  print("39 catalog mechanisms: gear ratio/sign, conserved regrouping, fold angle, pause, finite/clamped input and reset passed")
 }
}
