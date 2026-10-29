import XCTest

/// Library walks added after PreviewScreenshot grew too long: search and collections. Never presses Listen.
/// Shots go to SHOTS_DIR (TEST_RUNNER_SHOTS_DIR on the xcodebuild line).
@MainActor
final class LibraryWalk: XCTestCase {
    /// Search inside the books: the matching line under the row, a Found row on the book, the chapter opened at that line.
    func testSearch() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES"]
        app.launch()
        sleep(4)
        app.swipeDown()
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10)); field.tap(); field.typeText("gephi")
        sleep(2)
        saveTo("search-results", XCUIScreen.main.screenshot())
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Data Science'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        let found = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Gephi'")).firstMatch
        XCTAssertTrue(found.waitForExistence(timeout: 10))
        sleep(1)
        saveTo("search-found", XCUIScreen.main.screenshot())
        found.tap()
        sleep(2)
        saveTo("search-jumped", XCUIScreen.main.screenshot())
    }

    /// Collections: put a book in a new one from its page, then the library groups it.
    func testCollections() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES"]
        app.launch()
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Data Science'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 15)); row.tap()
        let menu = app.buttons["Add to a collection"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 10)); menu.tap()
        app.buttons["New collection…"].firstMatch.tap()
        let name = app.textFields["Name"].firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 5)); name.typeText("Work")
        app.buttons["Add"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Collection, Work"].waitForExistence(timeout: 5))
        sleep(1)
        saveTo("collection-book", XCUIScreen.main.screenshot())
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Work"].waitForExistence(timeout: 5))
        sleep(2)
        saveTo("collection-library", XCUIScreen.main.screenshot())
    }

    /// Sort and filter: shortest first, then only the books in progress.
    func testSortFilter() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES"]   // no -kernel.sort here: an argument would pin the setting
        app.launch()
        let menu = app.buttons["Sort and filter"].firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 15)); menu.tap()
        app.buttons["All books"].firstMatch.tap()   // settings persist between runs
        menu.tap()
        app.buttons["Shortest first"].firstMatch.tap()
        sleep(2)
        saveTo("sort-short", XCUIScreen.main.screenshot())
        menu.tap()
        app.buttons["In progress"].firstMatch.tap()
        sleep(2)
        saveTo("show-started", XCUIScreen.main.screenshot())
        menu.tap(); app.buttons["All books"].firstMatch.tap()   // back to the defaults, so later store shots are not filtered
        menu.tap(); app.buttons["Recently edited"].firstMatch.tap()
    }

    /// Search by meaning: words that are not in the book still find the line that means it. On the device, no network.
    func testMeaning() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES"]
        app.launch()
        sleep(4)
        app.swipeDown()
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10)); field.tap(); field.typeText("seeing how people are connected")
        XCTAssertTrue(app.staticTexts["Close in meaning"].waitForExistence(timeout: 60))
        sleep(1)
        saveTo("meaning-results", XCUIScreen.main.screenshot())
    }

    /// Highlights across books, and one shared as a card (the share sheet, nothing sent).
    func testHighlightsPage() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES"]
        app.launch()
        let open = app.buttons["Highlights"].firstMatch
        XCTAssertTrue(open.waitForExistence(timeout: 15)); open.tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Gephi'")).firstMatch.waitForExistence(timeout: 5))
        sleep(1)
        saveTo("highlights", XCUIScreen.main.screenshot())
        app.buttons["Export"].firstMatch.tap()
        sleep(3)
        saveTo("highlights-export", XCUIScreen.main.screenshot())
        app.swipeDown(velocity: .fast)   // close the share sheet
        sleep(1)
        app.buttons["Share as a card"].firstMatch.tap()
        sleep(3)
        saveTo("highlight-share", XCUIScreen.main.screenshot())
    }

    /// Today's five at the top of the library; Done hides it until tomorrow.
    func testTodaysFive() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES", "-kernel.reviewed", ""]
        app.launch()
        XCTAssertTrue(app.staticTexts["Today's five"].waitForExistence(timeout: 15))
        sleep(2)
        saveTo("todays-five", XCUIScreen.main.screenshot())
    }

    /// Your note under a chapter. Never presses Listen.
    func testChapterNote() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES"]
        app.launch()
        let book = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Data Science'")).firstMatch
        XCTAssertTrue(book.waitForExistence(timeout: 15)); book.tap()
        let chapter = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Machine Learning Tool'")).firstMatch
        XCTAssertTrue(chapter.waitForExistence(timeout: 10)); chapter.tap()
        let note = app.textFields["What you want to remember from this chapter"].firstMatch
        for _ in 0..<4 where !note.isHittable { app.swipeUp() }
        XCTAssertTrue(note.waitForExistence(timeout: 5)); note.tap(); note.typeText("Try WEKA on last year's reading log.")
        sleep(2)
        saveTo("chapter-note", XCUIScreen.main.screenshot())
    }

    /// Summarize this book on a Goodreads row opens Add pages with the title filled in.
    func testSummarizeFromGoodreads() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES"]
        app.launch()
        let row = app.staticTexts["The Man Who Solved the Market"].firstMatch   // no Goodreads link in screenshot data, so it is text, not a button
        for _ in 0..<5 where !row.exists { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 10)); row.press(forDuration: 1.2)
        app.buttons["Summarize this book"].firstMatch.tap()
        XCTAssertTrue(app.textFields["Book title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["Book title"].value as? String, "The Man Who Solved the Market")
        sleep(1)
        saveTo("summarize-goodreads", XCUIScreen.main.screenshot())
    }

    /// Your reading at the bottom of the library: the counts, and Goodreads books by year.
    func testReadingStats() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES"]
        app.launch()
        let header = app.staticTexts["Your reading"].firstMatch
        for _ in 0..<8 where !header.isHittable { app.swipeUp() }
        XCTAssertTrue(header.waitForExistence(timeout: 10))
        app.swipeUp(); sleep(1)
        saveTo("reading-stats", XCUIScreen.main.screenshot())
    }

    /// Add pages offers Import Kindle or Readwise highlights, which opens the file picker (nothing is picked).
    func testKindleImport() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES", "UITEST_SIGNED_IN"]
        app.launch()
        let row = app.staticTexts["The Man Who Solved the Market"].firstMatch
        for _ in 0..<5 where !row.exists { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 10)); row.press(forDuration: 1.2)
        app.buttons["Summarize this book"].firstMatch.tap()
        let kindle = app.buttons["Import Kindle or Readwise highlights"].firstMatch
        for _ in 0..<3 where !kindle.isHittable { app.swipeUp() }
        XCTAssertTrue(kindle.waitForExistence(timeout: 5))
        sleep(1)
        saveTo("kindle-import", XCUIScreen.main.screenshot())
    }

    /// Add pages can keep each page's exact words, read on this device, instead of summarizing on the server.
    func testPagesOnDevice() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES", "-kernel.pagesOnDevice", "YES"]
        app.launch()
        let row = app.staticTexts["The Man Who Solved the Market"].firstMatch
        for _ in 0..<5 where !row.exists { app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 10)); row.press(forDuration: 1.2)
        app.buttons["Summarize this book"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Each page is read on this device, word for word; the photo never leaves it. Edit the text before you save."].waitForExistence(timeout: 5))
        sleep(1)
        saveTo("pages-on-device", XCUIScreen.main.screenshot())
    }

    /// Continue my book (Siri): the library opens the book you are partway through. Silent in screenshot runs.
    func testContinueMyBook() {
        let app = XCUIApplication()
        app.launchArguments += ["UITEST_SNAPSHOT", "-kernel.onboarded", "YES", "UITEST_CONTINUE"]
        app.launch()
        XCTAssertTrue(app.staticTexts["The Optimist"].waitForExistence(timeout: 15))
        sleep(2)
        saveTo("continue-my-book", XCUIScreen.main.screenshot())
    }

    private func saveTo(_ name: String, _ shot: XCUIScreenshot) {
        let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? shot.pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/\(name).png"))
    }
}
