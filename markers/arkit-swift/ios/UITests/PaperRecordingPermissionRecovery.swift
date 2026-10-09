import XCTest

/// Supported real XCTest UI input to cancel only the genuine screen-recording alert.
/// Does not grant recording permission, change entitlements, or dismiss unrelated dialogs.
final class PaperRecordingPermissionRecovery: XCTestCase {
 func testCancelPendingScreenRecordingPermission() {
  continueAfterFailure=false
  let app=XCUIApplication(bundleIdentifier:"edu.colorado.paperlab.prototype")
  app.activate() // Keep the current installed app and its live state; no launch or reinstall.
  let springboard=XCUIApplication(bundleIdentifier:"com.apple.springboard")
  let predicate=NSPredicate(format:"label == %@ OR label == %@", "Record Screen", "Start Recording")
  let candidates=[springboard.alerts.containing(.button,identifier:"Record Screen").firstMatch,
                  springboard.alerts.containing(.button,identifier:"Start Recording").firstMatch,
                  app.alerts.containing(.button,identifier:"Record Screen").firstMatch,
                  app.alerts.containing(.button,identifier:"Start Recording").firstMatch]
  let deadline=Date().addingTimeInterval(15)
  var recordingAlert:XCUIElement?
  repeat {
   recordingAlert=candidates.first{$0.exists && $0.buttons.matching(predicate).firstMatch.exists}
   if recordingAlert==nil{Thread.sleep(forTimeInterval:0.25)}
  } while recordingAlert==nil && Date()<deadline
  attach("screen-permission-before-cancel")
  guard let alert=recordingAlert else{XCTFail("No genuine screen-recording alert with Record Screen/Start Recording button found. No other dialog was touched.");return}
  let cancelPredicate=NSPredicate(format:"label == %@ OR label == %@ OR label == %@", "Don't Allow", "Don’t Allow", "Cancel")
  let cancel=alert.buttons.matching(cancelPredicate).firstMatch
  XCTAssertTrue(cancel.exists && cancel.isHittable,"Genuine recording alert has a usable negative permission action")
  cancel.tap()
  let gone=expectation(for:NSPredicate(format:"exists == false"),evaluatedWith:alert)
  wait(for:[gone],timeout:10)
  attach("screen-permission-after-real-cancel")
  print("PAPER_RECORD_PERMISSION_RECOVERY genuineSystemAlertNegativeButtonTapped=true disappearanceVerified=true permissionGranted=false")
 }
 private func attach(_ name:String){let screenshot=XCTAttachment(screenshot:XCUIScreen.main.screenshot());screenshot.name=name;screenshot.lifetime = .keepAlways;add(screenshot)}
}
