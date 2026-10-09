import Foundation
@main struct Checks {
 static func main() throws {
  var lens=SourceThinLens();let s=lens.solution
  precondition(abs(s.imageDistance!-124*303/179)<1e-10 && s.magnification!<0)
  precondition(abs(1/s.distance+1/s.imageDistance!-1/lens.focal)<1e-12)
  lens.setObjectX(653-124);precondition(lens.solution.atFocus)
  lens.setObjectX(600);precondition(lens.solution.magnification!>0 && lens.solution.imageDistance!<0)
  lens.setObjectX(.nan);precondition(lens.objectX==600)
  var c=SourceSeriesCircuit();precondition(c.current==0.2 && c.drops==[60,40]);c.setR1(600);precondition(abs(c.drops.reduce(0,+)-c.voltage)<1e-12 && c.current==0.125);c.setVoltage(0);precondition(c.current==0 && c.drops==[0,0]);c.setR1(-4);precondition(c.r1==1);c.setR2(.infinity);precondition(c.r2==200)
  var p=SourceNonlinearPendulum();precondition(abs(p.bobPixel[0]-157)<1e-10 && abs(p.bobPixel[1]-254)<1e-10);p.damping=0;let e=p.energy
  for _ in 0..<10000 {p.advance(0.002)};precondition(abs(p.energy/e-1)<1e-8,"nonlinear RK4 energy")
  p.setAmplitude(5);let period=2*Double.pi*sqrt(p.length/9.81),start=p.angle;for _ in 0..<2000 {p.advance(period/2000)};precondition(abs(p.angle-start)<1e-5,"small angle analytic period")
  p.setAmplitude(80);let high=p.angle;for _ in 0..<2000 {p.advance(period/2000)};precondition(abs(p.angle-high)>0.05,"nonlinear period must differ from small-angle")
  p.damping=0.2;let damped=p.energy;for _ in 0..<1000 {p.advance(0.01)};precondition(p.energy<damped/4);p.setLength(.nan);precondition(p.length==1)
  // A right-side pointer must retain its side; increasing magnitude must not mirror it.
  p.setSignedAmplitude(30);precondition(p.bobPixel[0]>259 && p.angle>0)
  p.setAmplitude(40);precondition(p.angle>0 && abs(p.angle-40 * .pi/180)<1e-12)
  p.setSignedAmplitude(-30);precondition(p.bobPixel[0]<259 && p.angle<0)
  p.setSignedAmplitude(0);precondition(p.bobPixel==[259,61+SourceNonlinearPendulum.sourceLengthPixels] && p.energy==0)
  p.advance(0.1);precondition(p.angle==0 && p.velocity==0,"vertical release stays at equilibrium")
  p.setSignedAmplitude(300);precondition(abs(p.angle-85 * .pi/180)<1e-12)
  p.setSignedAmplitude(.nan);precondition(abs(p.angle-85 * .pi/180)<1e-12)
  if CommandLine.arguments.count>1 {let dir=URL(fileURLWithPath:CommandLine.arguments[1]);for id in ["optics","circuit","pendulum"] {let d=try Data(contentsOf:dir.appendingPathComponent("original-physics-\(id)-provenance.json")),spec=try JSONDecoder().decode(SourceDiagramProvenance.self,from:d);precondition(spec.validate(directory:dir));let tmp=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString);try FileManager.default.createDirectory(at:tmp,withIntermediateDirectories:true);defer{try? FileManager.default.removeItem(at:tmp)};for asset in [spec.page,spec.cutout,spec.mask,spec.rawMask].compactMap({$0}) {try FileManager.default.copyItem(at:dir.appendingPathComponent(asset.file),to:tmp.appendingPathComponent(asset.file))};for asset in [spec.page,spec.cutout,spec.mask,spec.rawMask].compactMap({$0}) {let file=tmp.appendingPathComponent(asset.file),original=try Data(contentsOf:file);var bytes=original;bytes[0]^=1;try bytes.write(to:file);precondition(!spec.validate(directory:tmp),"corrupt source/RGB/alpha/raw mask must fail closed");try original.write(to:file)}}}
  print("Thin-lens reciprocal/focus/virtual-image, series KVL/zero-current, nonlinear RK4 energy/period/dissipation/source coordinates and lineage corruption checks passed")
 }
}
