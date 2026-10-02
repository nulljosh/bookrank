import XCTest

@MainActor
final class PreviewScreenshot: XCTestCase {
    func testTakeScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments.append("UITEST_SNAPSHOT")
        app.launch()
        sleep(3)
        snapshot("0Library")
        let first = app.buttons.matching(NSPredicate(format: "label CONTAINS 'The Optimist'")).firstMatch
        if first.waitForExistence(timeout: 5) {
            first.tap()
            sleep(3)
            snapshot("1Summary")
            let chapter = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Chapter 1'")).firstMatch
            if chapter.waitForExistence(timeout: 20) {
                chapter.tap()
                sleep(4)
                snapshot("2Chapter")
            }
        }
    }

    /// Footage for the ad: a slow walk from the list into a chapter, then Listen, so the
    /// highlight moves with real speech. Recorded with `xcrun simctl io <udid> recordVideo`.
    func testAdWalk() {
        let app = XCUIApplication()
        app.launchArguments.append("UITEST_SNAPSHOT")
        app.launch()
        sleep(4)
        let book = app.buttons.matching(NSPredicate(format: "label CONTAINS 'The Optimist'")).firstMatch
        XCTAssertTrue(book.waitForExistence(timeout: 10)); book.tap()
        sleep(4)
        let chapter = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Chapter 1'")).firstMatch
        XCTAssertTrue(chapter.waitForExistence(timeout: 20)); chapter.tap()
        sleep(3)
        let listen = app.buttons["Listen"].firstMatch
        XCTAssertTrue(listen.waitForExistence(timeout: 10)); listen.tap()
        sleep(14)
    }
}
