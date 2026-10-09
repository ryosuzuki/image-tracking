import XCTest
/// OFFLINE simulator UI acceptance only; no camera, AR anchor or physical-device claim.
final class SourceDiagramInteractions:XCTestCase {
 func testPreparedSourceControls() {
  let app=XCUIApplication()
  for (kind,primary,secondary) in [("optics","Object left 25 px","Focal +10 px"),("circuit","Voltage +25 V","R1 +100 Ω"),("pendulum","Amplitude +10°","Length +0.25 m")] {
   app.launchArguments=["--science-pages","--science-preview","original-physics-"+kind];app.launch()
   XCTAssertTrue(app.buttons[primary].waitForExistence(timeout:20));app.buttons[primary].tap();app.buttons[secondary].tap()
   let changed=kind=="optics" ? "Thin lens f 134 px" : kind=="circuit" ? "Prepared series: 125 V · 400" : "L 1.25 m"
   XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS %@",changed)).firstMatch.waitForExistence(timeout:5))
   if kind=="circuit" {app.buttons["R2 +100 Ω"].tap();XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS %@","400 + 300 Ω")).firstMatch.waitForExistence(timeout:5))}
   XCTAssertTrue(app.buttons["Original / overlay"].exists);app.buttons["Original / overlay"].tap();app.buttons["Original / overlay"].tap()
   app.buttons["Pause motion"].tap();XCTAssertTrue(app.buttons["Resume motion"].exists);app.buttons["Resume motion"].tap()
   let attachment=XCTAttachment(screenshot:app.screenshot());attachment.name="OFFLINE-SIMULATOR-"+kind;attachment.lifetime = .keepAlways;add(attachment)
   app.buttons["Reset fixture"].tap()
   app.terminate()
  }
 }
}
