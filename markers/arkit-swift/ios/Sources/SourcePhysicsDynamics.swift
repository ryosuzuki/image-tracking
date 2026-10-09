import Foundation

/// SI-unit teaching dynamics. Parameters are authored, not inferred from a photograph.
/// The page adapter maps these states back to the original segmented diagram pixels.
struct SourceSpringDynamics {
 var mass = 0.15, stiffness = 14.0, damping = 0.12
 var displacement = 0.008, velocity = 0.0
 var time = 0.0
 var energy: Double { 0.5 * mass * velocity * velocity + 0.5 * stiffness * displacement * displacement }
 mutating func reset() { displacement = 0.008; velocity = 0; time = 0 }
 mutating func setStiffness(_ value: Double) { guard value.isFinite else { return }; stiffness = min(60, max(2, value)) }
 mutating func setMass(_ value: Double) { guard value.isFinite else { return }; mass = min(1, max(0.05, value)) }
 mutating func advance(_ interval: Double) {
  guard interval.isFinite, interval > 0 else { return }
  let duration = min(interval, 0.1), steps = max(1, Int(ceil(duration / 0.002)))
  let dt = duration / Double(steps)
  func acceleration(_ x: Double, _ v: Double) -> Double { (-stiffness * x - damping * v) / mass }
  for _ in 0..<steps {
   let x = displacement, v = velocity
   let k1x = v, k1v = acceleration(x, v)
   let k2x = v + 0.5 * dt * k1v, k2v = acceleration(x + 0.5 * dt * k1x, v + 0.5 * dt * k1v)
   let k3x = v + 0.5 * dt * k2v, k3v = acceleration(x + 0.5 * dt * k2x, v + 0.5 * dt * k2v)
   let k4x = v + dt * k3v, k4v = acceleration(x + dt * k3x, v + dt * k3v)
   displacement += dt / 6 * (k1x + 2*k2x + 2*k3x + k4x)
   velocity += dt / 6 * (k1v + 2*k2v + 2*k3v + k4v)
   time += dt
  }
 }
}

struct SourceInclineDynamics {
 var angle = 18.0 * Double.pi / 180, friction = 0.06
 var position = 0.0, velocity = 0.0, trackLength = 0.035
 var playing = true
 var acceleration: Double {
  let downhill = 9.81 * sin(angle), resistance = friction * 9.81 * cos(angle)
  if abs(velocity) < 1e-7 { return max(0, downhill - resistance) }
  return downhill - (velocity > 0 ? resistance : -resistance)
 }
 mutating func reset() { position = 0; velocity = 0; playing = true }
 mutating func setAngle(_ degrees: Double) { guard degrees.isFinite else { return }; angle = min(40, max(0, degrees)) * .pi / 180 }
 mutating func setFriction(_ value: Double) { guard value.isFinite else { return }; friction = min(0.8, max(0, value)) }
 mutating func advance(_ interval: Double) {
  guard playing, interval.isFinite, interval > 0 else { return }
  let duration = min(interval, 0.1), steps = max(1, Int(ceil(duration / 0.002)))
  let dt = duration / Double(steps)
  for _ in 0..<steps {
   let a = acceleration, v = max(0, velocity + a * dt)
   position = min(trackLength, position + 0.5 * (velocity + v) * dt)
   velocity = position < trackLength ? v : 0
   if position >= trackLength { playing = false; break }
  }
 }
}
