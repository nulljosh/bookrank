import XCTest

@MainActor
final class PreviewScreenshot: XCTestCase {
    func testTakeScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments.append("UITEST_SNAPSHOT")
        app.launch()
        sleep(8)   // covers load over the network; the iPad shot caught placeholders at 3
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
    /// (QA, not the store set): `SHOTS_DIR=/tmp/x xcodebuild test -only-testing:KernelUITests/PreviewScreenshot/testSignInScreens`.
    func testSignInScreens() {
        let app = XCUIApplication()
        app.launchArguments += ["-kernel.onboarded", "YES"]   // the first-run pages would cover the library
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

    /// A real session on jaybulb-api: sign in with a QA account (TEST_RUNNER_QA_EMAIL and
    /// TEST_RUNNER_QA_PASSWORD on the xcodebuild line), open the shelf, a book and the account sheet,
    /// then sign out. Never presses Listen.
    func testSignedInWalk() throws {
        let env = ProcessInfo.processInfo.environment
        guard let email = env["QA_EMAIL"], let password = env["QA_PASSWORD"] else { throw XCTSkip("no QA account") }
        let app = XCUIApplication()
        app.launchArguments += ["-kernel.onboarded", "YES"]
        app.launch()
        let open = app.buttons["Sign in"].firstMatch
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        open.tap()
        let field = app.textFields["Email"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText(email)
        let pw = app.secureTextFields["Password"]
        pw.tap(); pw.typeText(password)
        app.buttons.matching(NSPredicate(format: "label == 'Sign in'")).allElementsBoundByIndex.last?.tap()
        sleep(3)
        save("signedin-account", XCUIScreen.main.screenshot())
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
        let book = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Art of War'")).firstMatch
        XCTAssertTrue(book.waitForExistence(timeout: 15), "the seeded summary should load from jaybulb-api")
        save("signedin-library", XCUIScreen.main.screenshot())
        book.tap()
        sleep(2)
        save("signedin-book", XCUIScreen.main.screenshot())
    }

    /// What App Review does: signed out, open the sample chapter and press Listen.
    func testSampleListen() {
        let app = XCUIApplication()
        app.launchArguments += ["-kernel.onboarded", "YES"]
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

    /// First-run pages, walked with taps: page 1 to 3, then Skip and the library. Never presses
    /// the sample's Listen or any Play. Screenshots go to TEST_RUNNER_SHOTS_DIR (the xcodebuild line).
    func testOnboardingWalk() {
        let app = XCUIApplication()
        app.launchArguments += ["-kernel.onboarded", "NO"]
        app.launch()
        let next = app.buttons["Next"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 15), "the first-run pages should appear after the splash")
        sleep(1)
        saveTo("onboard-1", XCUIScreen.main.screenshot())
        next.tap()
        sleep(1)
        saveTo("onboard-2", XCUIScreen.main.screenshot())
        app.buttons["Next"].firstMatch.tap()
        sleep(1)
        saveTo("onboard-3", XCUIScreen.main.screenshot())
        XCTAssertTrue(app.buttons["Try a sample chapter"].firstMatch.exists)
        app.buttons["Skip"].firstMatch.tap()
        sleep(2)
        saveTo("library-after-skip", XCUIScreen.main.screenshot())
        XCTAssertFalse(app.buttons["Skip"].firstMatch.exists, "Skip should close the pages")
    }

    /// Signed out: the library, the sample book and its first chapter. Never presses Listen.
    func testSampleRead() {
        let app = XCUIApplication()
        app.launchArguments += ["-kernel.onboarded", "YES"]
        app.launch()
        let sample = app.buttons["Try a sample chapter"].firstMatch
        XCTAssertTrue(sample.waitForExistence(timeout: 15))
        sleep(1)
        saveTo("library", XCUIScreen.main.screenshot())
        sample.tap()
        let chapter = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Know the ground'")).firstMatch
        XCTAssertTrue(chapter.waitForExistence(timeout: 10))
        sleep(1)
        saveTo("book", XCUIScreen.main.screenshot())
        chapter.tap()
        sleep(2)
        saveTo("chapter", XCUIScreen.main.screenshot())
    }

    /// The player bar's menu (speed, sleep timer), shown silent via UITEST_PLAYER. Never presses Play.
    func testPlayerMenu() {
        let app = XCUIApplication()
        app.launchArguments += ["-kernel.onboarded", "YES", "UITEST_PLAYER"]
        app.launch()
        let speed = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Speed'")).firstMatch
        XCTAssertTrue(speed.waitForExistence(timeout: 15))
        speed.tap()
        sleep(1)
        saveTo("player-menu", XCUIScreen.main.screenshot())
    }

    /// Long-press a line in the sample, highlight it, and find it on the book page. Never presses Listen.
    func testHighlight() {
        let app = XCUIApplication()
        app.launchArguments += ["-kernel.onboarded", "YES"]
        app.launch()
        let sample = app.buttons["Try a sample chapter"].firstMatch
        XCTAssertTrue(sample.waitForExistence(timeout: 15)); sample.tap()
        let chapter = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Know the ground'")).firstMatch
        XCTAssertTrue(chapter.waitForExistence(timeout: 10)); chapter.tap()
        let line = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Sun Tzu opens'")).firstMatch
        XCTAssertTrue(line.waitForExistence(timeout: 10))
        line.press(forDuration: 1.0)
        let mark = app.buttons["Highlight"].firstMatch
        XCTAssertTrue(mark.waitForExistence(timeout: 5)); mark.tap()
        sleep(1)
        saveTo("highlight-chapter", XCUIScreen.main.screenshot())
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Highlights"].waitForExistence(timeout: 5), "the book page should list the highlight")
        sleep(1)
        saveTo("highlight-book", XCUIScreen.main.screenshot())
    }

    /// The book page's Download control (offline audio). Shot only; tapping it would spend voice credits.
    func testOfflineButton() {
        let app = XCUIApplication()
        app.launchArguments += ["-kernel.onboarded", "YES", "UITEST_SNAPSHOT"]
        app.launch()
        let book = app.buttons.matching(NSPredicate(format: "label CONTAINS 'The Optimist'")).firstMatch
        XCTAssertTrue(book.waitForExistence(timeout: 15)); book.tap()
        XCTAssertTrue(app.buttons["Download"].firstMatch.waitForExistence(timeout: 10), "a signed-in book should offer Download")
        sleep(1)
        saveTo("offline-book", XCUIScreen.main.screenshot())
    }

    private func saveTo(_ name: String, _ shot: XCUIScreenshot) {
        let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? shot.pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
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
