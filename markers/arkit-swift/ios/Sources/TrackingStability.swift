import Foundation
import simd

/// Presentation policy only: a held pose is not a new ARKit observation.
/// All calls come from the main thread, using a monotonic clock in seconds.
struct TrackingStability {
 enum TargetPolicy: String {
  case moving, fixed, worldPinned
  var maximumHold: Double { self == .worldPinned ? .infinity : (self == .moving ? 0.65 : 1.5) }
 }
 enum State: String { case searching, tracked, held, fading, hidden, pinned }
 struct Output {
  let state: State
  let pose: simd_float4x4?
  let opacity: Float
  let observationAge: Double?
  var measured: Bool { state == .tracked }
  var interactive:Bool {state == .tracked || state == .pinned}
 }

 var policy: TargetPolicy = .moving
 let fadeDuration = 0.20
 let observationTimeout = 0.15
 let normalSmoothing = 0.045
 let reacquisitionSmoothing = 0.070
 let maximumSmoothTranslation: Float = 0.10
 let maximumSmoothAngle: Float = .pi / 6
 private(set) var lastMeasurementTime: Double?
 private var targetPose: simd_float4x4?
 private var displayedPose: simd_float4x4?
 private var observedTracked = false
 private var cameraReliable = true
 private var lastRenderTime: Double?
 private var reacquisitionUntil = 0.0
 private var fadeInStarted: Double?

 mutating func reset() {
  lastMeasurementTime = nil; targetPose = nil; displayedPose = nil
  observedTracked = false; lastRenderTime = nil
  reacquisitionUntil = 0; fadeInStarted = nil
 }

 mutating func setCameraReliable(_ reliable: Bool) {
  cameraReliable = reliable
  // No world-pose retention during relocalization/interruption or after reset.
  if !reliable { reset() }
 }

 mutating func markLost() { observedTracked = false }

 mutating func observe(pose: simd_float4x4, tracked: Bool, at time: Double) {
  guard cameraReliable else { return }
  if let lastMeasurementTime, time < lastMeasurementTime { return }
  guard tracked else { observedTracked = false; return }
  let expired = lastMeasurementTime.map { time - $0 >= policy.maximumHold } ?? true
  let reacquiring = !observedTracked || lastMeasurementTime.map { time - $0 > observationTimeout } ?? true
  if let displayedPose, reacquiring, !expired {
   let distance = simd_distance(Self.position(displayedPose), Self.position(pose))
   let similarity = min(1, abs(simd_dot(simd_quatf(displayedPose).vector, simd_quatf(pose).vector)))
   let rotation = 2 * acos(similarity)
   // A moved, unseen target cannot be inferred. Do not sweep an overlay across
   // the room to conceal a large displacement on rediscovery.
   if distance > maximumSmoothTranslation || rotation > maximumSmoothAngle {
    self.displayedPose = pose; fadeInStarted = time
   } else { reacquisitionUntil = time + 0.20 }
  } else if displayedPose == nil || expired {
   displayedPose = pose; fadeInStarted = time
  }
  targetPose = pose; observedTracked = true; lastMeasurementTime = time
 }

 mutating func sample(at time: Double) -> Output {
  guard cameraReliable, let measuredAt = lastMeasurementTime, let targetPose, var displayedPose else {
   return Output(state: .searching, pose: nil, opacity: 0, observationAge: nil)
  }
  let age = max(0, time - measuredAt)
  let dt = max(0, min(0.10, time - (lastRenderTime ?? time)))
  lastRenderTime = time
  let measured = observedTracked && age <= observationTimeout
  if measured {
   let tau = time < reacquisitionUntil ? reacquisitionSmoothing : normalSmoothing
   let amount = Float(1 - exp(-dt / tau))
   displayedPose = Self.interpolate(displayedPose, targetPose, amount: amount)
   self.displayedPose = displayedPose
   let opacity = fadeInStarted.map { Float(min(1, max(0, (time - $0) / 0.12))) } ?? 1
   return Output(state: .tracked, pose: displayedPose, opacity: opacity, observationAge: age)
  }
  // Explicit opt-in world pin retains only a previously measured world pose.
  // It is never labeled measured image tracking; unreliable camera/reset clears it.
  if policy == .worldPinned {return Output(state:.pinned,pose:displayedPose,opacity:1,observationAge:age)}
  // False/lost updates never extend measuredAt. The monotonic render tick
  // expires this pose even when no further anchor callbacks arrive.
  guard age < policy.maximumHold else {
   return Output(state: .hidden, pose: nil, opacity: 0, observationAge: age)
  }
  let fadeStart = policy.maximumHold - fadeDuration
  if age < fadeStart { return Output(state: .held, pose: displayedPose, opacity: 1, observationAge: age) }
  let opacity = Float(max(0, (policy.maximumHold - age) / fadeDuration))
  return Output(state: .fading, pose: displayedPose, opacity: opacity, observationAge: age)
 }

 static func position(_ pose: simd_float4x4) -> SIMD3<Float> {
  SIMD3(pose.columns.3.x, pose.columns.3.y, pose.columns.3.z)
 }
 static func interpolate(_ from: simd_float4x4, _ to: simd_float4x4, amount: Float) -> simd_float4x4 {
  let translation = simd_mix(position(from), position(to), SIMD3(repeating: amount))
  var result = simd_float4x4(simd_slerp(simd_quatf(from), simd_quatf(to), amount))
  result.columns.3 = SIMD4(translation.x, translation.y, translation.z, 1)
  return result
 }
}
