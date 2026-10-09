import XCTest
final class PhysicalInteraction: XCTestCase {
func shot(_ label:String) { let a=XCTAttachment(screenshot:XCUIScreen.main.screenshot()); a.name=label; a.lifetime = .keepAlways; add(a) }
func testLivePageTouches() {
 let app=XCUIApplication(bundleIdentifier:"edu.colorado.paperlab.prototype")
 app.launchArguments=["--ar-live","--science-pages","--fixed-target"]
 app.launch(); sleep(14); shot("live-before-touch")
 XCTAssertTrue(app.buttons["Pause motion"].waitForExistence(timeout:15))
 app.buttons["Pause motion"].tap(); sleep(2); shot("touch-paused")
 XCTAssertTrue(app.buttons["Resume motion"].exists)
 app.buttons["Resume motion"].tap(); sleep(2); shot("touch-resumed")
 let start=app.coordinate(withNormalizedOffset:CGVector(dx:0.42,dy:0.48)); let end=app.coordinate(withNormalizedOffset:CGVector(dx:0.67,dy:0.48))
 start.press(forDuration:0.05,thenDragTo:end); sleep(2); shot("touch-rotated")
 app.pinch(withScale:1.35,velocity:0.6); sleep(2); shot("touch-pinched")
 app.buttons["Replay pop-out"].tap(); sleep(3); shot("touch-replay")
}
func testSourceSineControls() {
 let app=XCUIApplication(bundleIdentifier:"edu.colorado.paperlab.prototype")
 app.launchArguments=["--ar-live","--science-pages","--science-target","original-math-sine"]
 app.launch()
 let frequency=app.sliders["SourceSineFrequency"]
 XCTAssertTrue(frequency.waitForExistence(timeout:60),"Requires actual original sample01 sine crop presented to camera")
 XCTAssertTrue(frequency.isEnabled)
 shot("source-sine-before-touch")
 frequency.adjust(toNormalizedSliderPosition:0.75)
 shot("source-sine-frequency-touch")
 XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS 'period'")).firstMatch.exists)
}
func testSourceSummationControls() {
 let app=XCUIApplication(bundleIdentifier:"edu.colorado.paperlab.prototype")
 app.launchArguments=["--ar-live","--science-pages","--science-target","original-math-summation"]
 app.launch()
 let upper=app.steppers["SourceSumUpper"],lower=app.steppers["SourceSumLower"]
 XCTAssertTrue(upper.waitForExistence(timeout:60),"Requires actual original sample09 presented to camera")
 XCTAssertTrue(lower.exists)
 shot("source-summation-before-touch")
 upper.buttons["Increment"].tap();lower.buttons["Increment"].tap()
 shot("source-summation-bounds-touch")
 XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS 'Σ(i=2…21)'")).firstMatch.exists)
}
}
