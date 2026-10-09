import UIKit
import ARKit
import AVFoundation
import QuartzCore

/// Records only the actual ARSCNView GPU snapshot (camera + SceneKit), not system UI,
/// stereo eyes, audio, ReplayKit, or a reconstructed/post-composited camera image.
public final class PaperARViewRecorder: NSObject {
 public struct Report: Codable {
  public let file: String, method: String, writerStatus: String
  public let width: Int, height: Int, requestedFPS: Int
  public let frames: Int, dropped: Int, sourceSeconds: Double, recordingSeconds: Double
  public let firstPTS: Double?, lastPTS: Double?, error: String?
 }
 public enum RecorderError: LocalizedError {
  case invalidInput, alreadyRecording, missingImage, noFrames
  public var errorDescription: String? { switch self {
  case .invalidInput: return "Recorder start requires main thread, a laid-out AR view, and finite positive seconds."
  case .alreadyRecording: return "An AR view recording is already running or finishing."
  case .missingImage: return "Actual AR view snapshot has no image."
  case .noFrames: return "No actual AR view frames were written."
  } }
 }
 public var onCompletion: ((Result<Report, Error>) -> Void)?
 public private(set) var lastReport: Report?
 public private(set) var isRecording = false
 private weak var ar: ARSCNView?
 private var displayLink: CADisplayLink?, context: WriterContext?
 private var started = 0.0, maximumSeconds = 0.0, captureBusy = false
 private let queue = DispatchQueue(label: "edu.colorado.paperlab.actual-ar-view-writer", qos: .utility)
 private final class WriterContext {
  let writer: AVAssetWriter, input: AVAssetWriterInput, adaptor: AVAssetWriterInputPixelBufferAdaptor
  let url: URL, width: Int, height: Int
  var frames = 0, dropped = 0, firstPTS: Double?, lastPTS: Double?
  init(url: URL, width: Int, height: Int) throws {
   self.url=url;self.width=width;self.height=height
   writer=try AVAssetWriter(outputURL:url,fileType:.mp4)
   input=AVAssetWriterInput(mediaType:.video,outputSettings:[AVVideoCodecKey:AVVideoCodecType.h264,AVVideoWidthKey:width,AVVideoHeightKey:height,AVVideoCompressionPropertiesKey:[AVVideoAverageBitRateKey:6_000_000,AVVideoExpectedSourceFrameRateKey:15,AVVideoMaxKeyFrameIntervalKey:30]])
   input.expectsMediaDataInRealTime=true
   adaptor=AVAssetWriterInputPixelBufferAdaptor(assetWriterInput:input,sourcePixelBufferAttributes:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA,kCVPixelBufferWidthKey as String:width,kCVPixelBufferHeightKey as String:height,kCVPixelBufferCGImageCompatibilityKey as String:true,kCVPixelBufferCGBitmapContextCompatibilityKey as String:true])
   guard writer.canAdd(input) else{throw RecorderError.invalidInput};writer.add(input)
   guard writer.startWriting() else{throw writer.error ?? RecorderError.invalidInput}
   writer.startSession(atSourceTime:.zero)
  }
 }
 @discardableResult public func start(ar: ARSCNView, seconds: Double) throws -> URL {
  guard Thread.isMainThread, seconds.isFinite, seconds>0, ar.bounds.width.isFinite, ar.bounds.height.isFinite, ar.bounds.width>0, ar.bounds.height>0 else{throw RecorderError.invalidInput}
  guard context==nil else{throw RecorderError.alreadyRecording}
  let scale=min(ar.contentScaleFactor,1920/max(ar.bounds.width,ar.bounds.height))
  let width=max(2,Int(ar.bounds.width*scale)/2*2),height=max(2,Int(ar.bounds.height*scale)/2*2)
  let directory=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0]
  let name="paper-ar-view-\(Int(Date().timeIntervalSince1970*1000))-\(UUID().uuidString.prefix(8)).mp4"
  let url=directory.appendingPathComponent(name)
  context=try WriterContext(url:url,width:width,height:height);self.ar=ar;maximumSeconds=min(900,seconds)
  started=CACurrentMediaTime();captureBusy=false;lastReport=nil;isRecording=true
  let link=CADisplayLink(target:self,selector:#selector(tick));link.preferredFramesPerSecond=15;link.add(to:.main,forMode:.common);displayLink=link
  print("PAPER_AR_RECORD_START method=actual-ARSCNView-GPU-snapshot camera-plus-SceneKit-only requestedFPS=15 maxSeconds=\(maximumSeconds) output=\(name)")
  return url
 }
 @objc private func tick(_ link: CADisplayLink) {
  guard isRecording,let context else{return}
  let elapsed=CACurrentMediaTime()-started
  if elapsed>=maximumSeconds {stop();return}
  guard !captureBusy else{queue.async{context.dropped += 1};return}
  guard let ar else{stop();return}
  captureBusy=true
  // Monotonic timestamp immediately before the actual main-thread GPU snapshot.
  let pts=CACurrentMediaTime()-started,image=ar.snapshot()
  queue.async { [weak self] in
   self?.append(image,pts:pts,context:context)
   DispatchQueue.main.async { [weak self] in self?.captureBusy=false }
  }
 }
 private func append(_ image: UIImage, pts: Double, context c: WriterContext) {
  guard pts.isFinite,pts>=0,c.writer.status == .writing,c.input.isReadyForMoreMediaData,
   c.lastPTS.map({pts>$0}) ?? true,let pool=c.adaptor.pixelBufferPool else{c.dropped += 1;return}
  var buffer:CVPixelBuffer?
  guard CVPixelBufferPoolCreatePixelBuffer(nil,pool,&buffer)==kCVReturnSuccess,let buffer else{c.dropped += 1;return}
  CVPixelBufferLockBaseAddress(buffer,[]);defer{CVPixelBufferUnlockBaseAddress(buffer,[])}
  guard let memory=CVPixelBufferGetBaseAddress(buffer),let cg=CGContext(data:memory,width:c.width,height:c.height,bitsPerComponent:8,bytesPerRow:CVPixelBufferGetBytesPerRow(buffer),space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedFirst.rawValue|CGBitmapInfo.byteOrder32Little.rawValue),image.size.width>0,image.size.height>0 else{c.dropped += 1;return}
  cg.setFillColor(CGColor(gray:0,alpha:1));cg.fill(CGRect(x:0,y:0,width:c.width,height:c.height))
  let fit=min(CGFloat(c.width)/image.size.width,CGFloat(c.height)/image.size.height)
  let size=CGSize(width:image.size.width*fit,height:image.size.height*fit)
  let rect=CGRect(x:(CGFloat(c.width)-size.width)/2,y:(CGFloat(c.height)-size.height)/2,width:size.width,height:size.height)
  // UIKit drawing preserves UIImage orientation; aspect-fit keeps pose geometry intact if bounds change.
  cg.translateBy(x:0,y:CGFloat(c.height));cg.scaleBy(x:1,y:-1)
  UIGraphicsPushContext(cg);image.draw(in:rect);UIGraphicsPopContext()
  if c.adaptor.append(buffer,withPresentationTime:CMTime(seconds:pts,preferredTimescale:60_000)) {
   c.frames += 1;if c.firstPTS==nil{c.firstPTS=pts};c.lastPTS=pts
  } else {c.dropped += 1}
 }
 public func stop() {
  guard Thread.isMainThread else{DispatchQueue.main.async { [weak self] in self?.stop() };return}
  guard isRecording,let c=context else{return}
  isRecording=false;displayLink?.invalidate();displayLink=nil;ar=nil
  let wallDuration=CACurrentMediaTime()-started
  queue.async { [weak self] in
   c.input.markAsFinished()
   guard c.frames>0 else{c.writer.cancelWriting();self?.complete(c,wallDuration:wallDuration,failure:RecorderError.noFrames);return}
   if c.writer.status == .writing {
    c.writer.finishWriting { [weak self] in
     self?.queue.async { [weak self] in self?.complete(c,wallDuration:wallDuration,failure:c.writer.status == .completed ? nil:(c.writer.error ?? RecorderError.noFrames)) }
    }
   } else{self?.complete(c,wallDuration:wallDuration,failure:c.writer.error ?? RecorderError.noFrames)}
  }
 }
 private func statusName(_ status: AVAssetWriter.Status) -> String {switch status{case .unknown:return "unknown";case .writing:return "writing";case .completed:return "completed";case .failed:return "failed";case .cancelled:return "cancelled";@unknown default:return "future-unknown"}}
 private func complete(_ c: WriterContext,wallDuration: Double,failure: Error?) {
  let report=Report(file:c.url.lastPathComponent,method:"actual-ARSCNView-GPU-snapshot; camera+SceneKit view only; no system UI/audio/stereo; requested FPS is not measured FPS; monotonic pre-snapshot PTS, not camera sensor exposure timestamps",writerStatus:statusName(c.writer.status),width:c.width,height:c.height,requestedFPS:15,frames:c.frames,dropped:c.dropped,sourceSeconds:max(0,(c.lastPTS ?? 0)-(c.firstPTS ?? 0)),recordingSeconds:wallDuration,firstPTS:c.firstPTS,lastPTS:c.lastPTS,error:failure?.localizedDescription)
  if let data=try? JSONEncoder().encode(report){try? data.write(to:c.url.deletingPathExtension().appendingPathExtension("json"),options:.atomic)}
  print("PAPER_AR_RECORD_END frames=\(report.frames) dropped=\(report.dropped) sourceSeconds=\(report.sourceSeconds) status=\(report.writerStatus) error=\(report.error ?? "none")")
  DispatchQueue.main.async { [weak self] in
   guard let self else{return};self.context=nil;self.lastReport=report
   if let failure{self.onCompletion?(.failure(failure))}else{self.onCompletion?(.success(report))}
  }
 }
}
