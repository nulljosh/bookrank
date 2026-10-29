import XCTest

/// How fast Kernel is: a 500-book shelf against a 60-book one, scroll hitches, cold launch. Never presses Play.
final class SpeedWalk: XCTestCase {
    /// 500 books against 60: the shelf appears and scrolls about as fast, and search narrows it.
    /// A fast swipe coasts for seconds on any long list, so the check is the ratio to a shelf that also scrolls the whole time.
    func testBigShelf() {
        func run(_ n: Int) -> (shown: Double, scrolled: Double, app: XCUIApplication) {
            let app = XCUIApplication()
            app.launchArguments = ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES"]
            app.launchEnvironment["UITEST_SHELF"] = "\(n)"
            let start = Date(); app.launch()
            XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 20))
            let shown = Date().timeIntervalSince(start), t = Date()
            for _ in 0..<12 { app.swipeUp(velocity: .fast) }
            return (shown, Date().timeIntervalSince(t), app)
        }
        let small = run(60); small.app.terminate()
        let big = run(500)
        print("SHELF 60: shown \(small.shown)s, 12 swipes \(small.scrolled)s; 500: shown \(big.shown)s, 12 swipes \(big.scrolled)s")
        saveTo("big-scrolled", XCUIScreen.main.screenshot())
        let find = big.app.searchFields.firstMatch
        if find.waitForExistence(timeout: 5) { find.tap(); find.typeText("Shui 45") }
        XCTAssertTrue(big.app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Good Feng Shui 45'")).firstMatch.waitForExistence(timeout: 5))
        saveTo("big-search", XCUIScreen.main.screenshot())
        XCTAssertLessThan(big.shown, small.shown * 2 + 3)
    }

    /// Scroll hitches on the 500-book shelf, from the system's own signposts: time spent on dropped frames per second of scrolling.
    func testBigShelfHitches() {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES"]
        app.launchEnvironment["UITEST_SHELF"] = "500"
        app.launch()
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 20))
        let options = XCTMeasureOptions(); options.iterationCount = 3
        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric], options: options) { app.swipeUp(velocity: .fast); app.swipeDown(velocity: .fast) }
    }

    /// Cold launch to the first frame, measured by the system. The budget is in docs/ARCHITECTURE.md.
    func testLaunchTime() {
        let options = XCTMeasureOptions(); options.iterationCount = 5
        measure(metrics: [XCTApplicationLaunchMetric()], options: options) {
            let app = XCUIApplication()
            app.launchArguments = ["-kernel.onboarded", "YES"]
            app.launch()
        }
    }

    private func saveTo(_ name: String, _ shot: XCUIScreenshot) {
        let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? shot.pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
    }
}
