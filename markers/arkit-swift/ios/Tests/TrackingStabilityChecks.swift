import Foundation
import simd

@main struct TrackingStabilityChecks {
 static func pose(_ x: Float = 0, angle: Float = 0) -> simd_float4x4 {
  var result = simd_float4x4(simd_quatf(angle: angle, axis: SIMD3(0, 1, 0)))
  result.columns.3 = SIMD4(x, 0, 0, 1); return result
 }
 static func main() {
  var count = 0
  func check(_ condition: @autoclosure () -> Bool, _ name: String) {
   precondition(condition(), name); count += 1
  }
  var moving = TrackingStability()
  check(moving.sample(at: 0).pose == nil, "never acquired: no fabricated pose")
  moving.observe(pose: pose(1), tracked: true, at: 0)
  check(moving.sample(at: 0.12).measured, "fresh measurement labeled tracked")
  moving.observe(pose: pose(1), tracked: false, at: 0.14)
  let held = moving.sample(at: 0.2)
  check(held.state == .held && !held.measured, "brief loss held but explicitly not measured")
  check(held.pose == pose(1), "loss preserves exact last world pose")
  moving.observe(pose: pose(9), tracked: false, at: 0.3)
  check(moving.sample(at: 0.3).pose == pose(1), "untracked transform cannot move held pose")
  check(moving.lastMeasurementTime == 0, "false updates cannot extend grace")
  let fading = moving.sample(at: 0.55)
  check(fading.state == .fading && abs(fading.opacity - 0.5) < 0.001, "linear fade before hard limit")
  check(moving.sample(at: 0.65).pose == nil, "moving target hidden at exact 650ms limit")
  moving.observe(pose: pose(3), tracked: true, at: 0.8)
  check(moving.sample(at: 0.8).pose == pose(3), "expired reacquisition snaps not ghosts")
  check(moving.sample(at: 0.95).state == .tracked, "freshness boundary inclusive")
  let noUpdates = moving.sample(at: 1.0)
  check(noUpdates.state == .held && !noUpdates.measured, "callback stall ceases tracked label")
  check(moving.sample(at: 1.46).pose == nil, "callback stall independently expires")
  moving.observe(pose: pose(99), tracked: true, at: 0.1)
  check(moving.sample(at: 1.47).pose == nil, "out-of-order stale observation cannot revive expired pose")

  var fixed = TrackingStability(); fixed.policy = .fixed
  fixed.observe(pose: pose(), tracked: true, at: 0); _ = fixed.sample(at: 0.1)
  fixed.markLost()
  check(fixed.sample(at: 0.7).state == .held, "fixed target longer world-lock grace")
  check(fixed.sample(at: 1.4).state == .fading, "fixed target still bounded and fading")
  check(fixed.sample(at: 1.5).pose == nil, "fixed target expires at 1.5 seconds")

  var short = TrackingStability()
  short.observe(pose: pose(), tracked: true, at: 0); _ = short.sample(at: 0.1)
  short.markLost(); _ = short.sample(at: 0.2)
  short.observe(pose: pose(0.04, angle: .pi / 12), tracked: true, at: 0.21)
  let resumed = short.sample(at: 0.23)
  let x = TrackingStability.position(resumed.pose!).x
  check(x > 0 && x < 0.04, "small reacquisition smoothly interpolates translation")
  let q = simd_quatf(resumed.pose!)
  check(abs(simd_length(q.vector) - 1) < 0.0001, "orientation interpolation stays rigid/unit quaternion")
  short.markLost(); _ = short.sample(at: 0.24)
  short.observe(pose: pose(0.4), tracked: true, at: 0.25)
  let relocated = short.sample(at: 0.25)
  check(relocated.pose == pose(0.4) && relocated.opacity == 0, "large displacement snaps and fades in")
  short.observe(pose: pose(0.4), tracked: true, at: 0.31)
  check(abs(short.sample(at: 0.31).opacity - 0.5) < 0.001, "relocation fade does not reset every measurement")
  short.setCameraReliable(false)
  check(short.sample(at: 0.32).pose == nil, "limited camera tracking hides immediately")
  short.observe(pose: pose(2), tracked: true, at: 0.33)
  check(short.sample(at: 0.33).pose == nil, "bad world tracking cannot resurrect a pose")
  short.setCameraReliable(true)
  check(short.sample(at: 0.34).pose == nil, "world recovery still requires new image measurement")
  short.observe(pose: pose(2), tracked: true, at: 0.35)
  check(short.sample(at: 0.35).pose == pose(2), "recovered world acquires new reliable pose")
  short.reset()
  check(short.sample(at: 0.36).pose == nil, "reset cannot retain old session coordinates")

  var rotation = TrackingStability()
  rotation.observe(pose: pose(), tracked: true, at: 0); _ = rotation.sample(at: 0.1)
  rotation.markLost(); _ = rotation.sample(at: 0.2)
  let turned = pose(angle: .pi / 2)
  rotation.observe(pose: turned, tracked: true, at: 0.21)
  let snappedRotation = simd_quatf(rotation.sample(at: 0.21).pose!)
  check(abs(simd_dot(snappedRotation.vector, simd_quatf(turned).vector)) > 0.99999, "large rotational relocation also snaps")
  var pinned=TrackingStability();pinned.policy = .worldPinned
  check(pinned.sample(at:0).pose==nil,"pin never invents a never-observed image pose")
  pinned.observe(pose:pose(1),tracked:true,at:0);_ = pinned.sample(at:0.1);pinned.markLost()
  let worldOnly=pinned.sample(at:30)
  check(worldOnly.state == .pinned && !worldOnly.measured && worldOnly.interactive,"opt-in world pin remains interactive but explicitly untracked")
  check(worldOnly.pose==pose(1) && pinned.lastMeasurementTime==0,"pin preserves actual last world pose without fabricating fresh observations")
  pinned.observe(pose:pose(7),tracked:false,at:31)
  check(pinned.sample(at:31).pose==pose(1),"untracked image transform cannot move a pinned object")
  pinned.setCameraReliable(false)
  check(pinned.sample(at:31.1).pose==nil,"pin clears immediately on unreliable world camera")
  pinned.setCameraReliable(true)
  check(pinned.sample(at:31.2).pose==nil,"pin cannot survive reset/relocalization without reacquisition")
  pinned.observe(pose:pose(2),tracked:true,at:32);_ = pinned.sample(at:32.1);pinned.markLost();pinned.policy = .moving
  check(pinned.sample(at:34).pose==nil,"unpin restores bounded moving-image hold")
  print("PASS: \(count) tracking stability behavioral checks")
 }
}
