import Foundation
import Vision
import ImageIO
var best: [[String: Any]] = []
var bestScore = -1.0
var bestOrientation = "up"
for (name, orientation) in [("up", CGImagePropertyOrientation.up), ("right", .right), ("down", .down), ("left", .left)] {
 let request = VNRecognizeTextRequest()
 request.recognitionLevel = .accurate
 request.usesLanguageCorrection = false
 request.recognitionLanguages = ["en-US", "zh-Hans"]
 request.automaticallyDetectsLanguage = true
 request.minimumTextHeight = 0.008
 try VNImageRequestHandler(url: URL(fileURLWithPath: CommandLine.arguments[1]), orientation: orientation, options: [:]).perform([request])
 var score = 0.0
 let lines = (request.results ?? []).compactMap { observation -> [String: Any]? in
  guard let candidate = observation.topCandidates(1).first else { return nil }
  score += Double(candidate.confidence) * Double(min(candidate.string.count, 80))
  let b = observation.boundingBox
  return ["text": candidate.string, "confidence": candidate.confidence, "bbox": ["x": b.minX,"y": b.minY,"width": b.width,"height": b.height]]
 }
 if score > bestScore { best = lines; bestScore = score; bestOrientation = name }
}
let data = try JSONSerialization.data(withJSONObject: ["engine":"Apple Vision accurate OCR, local Mac", "orientation":bestOrientation, "bboxSpace":"Oriented image; normalized bottom-left origin", "lines":best])
print(String(data:data,encoding:.utf8)!)
