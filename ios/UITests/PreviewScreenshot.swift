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
}
