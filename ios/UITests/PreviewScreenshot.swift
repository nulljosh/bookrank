import XCTest

@MainActor
final class PreviewScreenshot: XCTestCase {
    func testTakeScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        sleep(2)
        snapshot("0Library")
    }
}
