import Foundation
@main struct Checks {
 static func main() {
  var spring = SourceSpringDynamics(); spring.damping = 0
  let initialEnergy = spring.energy, period = 2 * Double.pi * sqrt(spring.mass / spring.stiffness)
  let steps = 1000
  for _ in 0..<steps { spring.advance(period / Double(steps)) }
  precondition(abs(spring.displacement - 0.008) < 1e-8, "undamped period must match sqrt(m/k)")
  precondition(abs(spring.energy / initialEnergy - 1) < 1e-6, "RK4 energy conservation")
  spring.damping = 0.25
  var previousEnergy = spring.energy
  for _ in 0..<500 { spring.advance(0.01); precondition(spring.energy <= previousEnergy + 1e-12); previousEnergy = spring.energy }
  precondition(spring.energy < initialEnergy * 0.001, "damped oscillator dissipates")
  var cart = SourceInclineDynamics(); cart.friction = 0; cart.trackLength = 100
  cart.setAngle(30)
  for _ in 0..<100 { cart.advance(0.01) }
  precondition(abs(cart.position - 0.5 * 4.905) < 1e-8, "frictionless slope analytic position")
  precondition(abs(cart.velocity - 4.905) < 1e-8)
  cart.reset(); cart.friction = 0.8; cart.setAngle(5); cart.advance(0.1)
  precondition(cart.position == 0 && cart.velocity == 0, "static friction prevents motion")
  cart.reset(); cart.friction = 0; cart.setAngle(30); cart.trackLength = 0.035
  for _ in 0..<100 { cart.advance(0.01) }
  precondition(cart.position == cart.trackLength && cart.velocity == 0 && !cart.playing)
  spring.setStiffness(.nan); precondition(spring.stiffness.isFinite)
  cart.setAngle(.infinity); precondition(cart.angle.isFinite)
  print("Source physics: analytic spring period, energy, dissipation, incline acceleration, static friction, track stop and finite input checks passed")
 }
}
