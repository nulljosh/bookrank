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

    /// Signed-out sign-in and create-account screens, saved as PNGs under the host's SHOTS_DIR
    /// (QA, not the store set): `SHOTS_DIR=/tmp/x xcodebuild test -only-testing:BookrankUITests/PreviewScreenshot/testSignInScreens`.
    func testSignInScreens() {
        let app = XCUIApplication()
        app.launch()
        sleep(3)
        let open = app.buttons["Sign in"].firstMatch
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        open.tap()
        sleep(2)
        save("signin", XCUIScreen.main.screenshot())
        let toggle = app.buttons["New here? Create an account"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.tap()
        sleep(1)
        save("create", XCUIScreen.main.screenshot())
    }

    /// What App Review does: signed out, open the sample chapter and press Listen.
    func testSampleListen() {
        let app = XCUIApplication()
        app.launch()
        let sample = app.buttons["Try a sample chapter"]
        XCTAssertTrue(sample.waitForExistence(timeout: 10))
        save("sample-0", XCUIScreen.main.screenshot())
        sample.tap()
        let chapter = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Know the ground'")).firstMatch
        XCTAssertTrue(chapter.waitForExistence(timeout: 10))
        chapter.tap()
        let listen = app.buttons["Listen"].firstMatch
        XCTAssertTrue(listen.waitForExistence(timeout: 10))
        listen.tap()
        sleep(4)
        save("sample-1", XCUIScreen.main.screenshot())
    }

    private func save(_ name: String, _ shot: XCUIScreenshot) {
        let host = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"] ?? NSHomeDirectory()
        let dir = ProcessInfo.processInfo.environment["SIMCTL_CHILD_SHOTS_DIR"] ?? "\(host)/.claude/jobs/c303a72f/tmp/shots"
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "phone"
        try? shot.pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(device)-\(name).png"))
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
