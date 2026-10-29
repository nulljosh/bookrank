import XCTest
@testable import Kernel

/// The app's pure rules, the same ones the web tests pin in *.test.js: chapters, the notes split into lines,
/// highlights merging, the offline catch-up, Kindle clippings, Today's five, durations and the morning line.
final class KernelTests: XCTestCase {
    func testChaptersPreferTopHeadings() {
        let md = "# Book\n\n# One\nA\n\n# Two\nB\n\n## Inner\nC"
        XCTAssertEqual(parseChapters(md).map(\.title), ["One", "Two"])   // a bare leading title is not a chapter
        XCTAssertEqual(parseChapters("# Only\n\n## A\nx\n## B\ny").map(\.title), ["A", "B"])
        XCTAssertEqual(parseChapters("no headings").map(\.title), ["Whole book"])
        XCTAssertTrue(parseChapters("  \n").isEmpty)
    }

    func testFindLineAndSnippet() {
        let f = findLine("# One\n\nNothing here.\n\n# Two\n\nThe kernel of the idea.", "kernel")
        XCTAssertEqual(f?.ch, 1)
        XCTAssertTrue(snippet(f?.text ?? "", "kernel").contains("kernel"))
        XCTAssertNil(findLine("# One\n\ntext", "absent"))
    }

    func testBlocksSplitParagraphsAndLists() {
        let lines = Speaker.blocks("First line\nsame paragraph.\n\n- a point\n- another\n\n---\n\n## Heading")
        XCTAssertEqual(lines.count, 4)
        XCTAssertEqual(lines.first?.line, "First line same paragraph.")
    }

    func testMarksMergeKeepsBothSidesAndHonoursRemovals() {
        typealias M = ListenState.Mark
        let base = [M(ch: 0, text: "a")], local = [M(ch: 0, text: "a"), M(ch: 1, text: "b")], server = [M(ch: 2, text: "c")]
        let merged = ListenState.merge(base: base, local: local, server: server)
        XCTAssertEqual(Set(merged), [M(ch: 1, text: "b"), M(ch: 2, text: "c")])   // "a" was removed on the other device
    }

    func testCatchUpLetsTheLaterPlaceWin() {
        let mine = ListenState(for: "v1", chapters: [:], pos: .init(ch: 2, line: 0, at: 1000), marks: [.init(ch: 0, text: "a")])
        let theirs = ListenState(for: "v1", chapters: [:], pos: .init(ch: 5, line: 3, at: 2000), marks: [.init(ch: 1, text: "b")])
        let out = ListenState.catchUp(mine, server: theirs)
        XCTAssertEqual(out.pos.ch, 5); XCTAssertEqual(out.marks?.count, 2)
        XCTAssertEqual(ListenState.catchUp(theirs, server: mine).pos.ch, 5)
        let edited = ListenState(for: "v0", chapters: [:], pos: .init(ch: 9, line: 0, at: 9999))
        XCTAssertEqual(ListenState.catchUp(mine, server: edited).pos.ch, 2)   // the text changed since: keep ours
    }

    func testKindleClippings() {
        let text = "The Book (Jane Doe)\r\n- Your Highlight on page 3 | Location 40-41\r\n\r\nA line worth keeping.\r\n==========\r\nThe Book (Jane Doe)\r\n- Your Note on page 4\r\n\r\nmy note\r\n==========\r\n"
        let books = Kindle.parse(text)
        XCTAssertEqual(books.first?.title, "The Book")
        XCTAssertEqual(books.first?.author, "Jane Doe")
        XCTAssertTrue(books.first?.lines.contains("A line worth keeping.") ?? false)
    }

    func testDailyFiveIsStableForADay() {
        let items = (0..<20).map { "line \($0)" }
        let a = dailyFive(items, text: { $0 }, day: "2026-10-29"), b = dailyFive(items, text: { $0 }, day: "2026-10-29")
        XCTAssertEqual(a, b); XCTAssertEqual(a.count, 5)
        XCTAssertNotEqual(a, dailyFive(items, text: { $0 }, day: "2026-10-30"))
    }

    func testDurations() {
        XCTAssertEqual(duration(45), "45 min"); XCTAssertEqual(duration(120), "2 hr"); XCTAssertEqual(duration(261), "4 hr 21 min")
        XCTAssertEqual(minutes(""), 1); XCTAssertEqual(minutes(String(repeating: "a", count: 11000)), 10)
    }

    func testArticleKeepsProseAndDropsChrome() {
        let html = "<html><nav><p>Home About Contact and some other links that are long enough to count</p></nav><script>var p = '<p>no</p>'</script><article><p>Short.</p><p>The first real paragraph of the article, long enough to be prose and kept.</p><p>A second paragraph with <a href='#'>a link</a> &amp; an entity, also long enough.</p></article><footer><p>Copyright notice that is long enough to pass the bar for prose here.</p></footer></html>"
        XCTAssertEqual(Inbox.article(fromHTML: html), ["The first real paragraph of the article, long enough to be prose and kept.", "A second paragraph with a link & an entity, also long enough."])
    }

    func testStudyAidsFromTheSummaryItself() {
        let book = "# One\n\nHabits are the **compound interest** of self-improvement, small changes adding up over the years.\n\n## Key takeaways\n- Small habits compound into remarkable results over time.\n- Focus on systems rather than goals for lasting change.\n\n# Two\n\nThe **habit loop** has four parts: cue, craving, response and reward, and each can be designed.\n\nEnvironment shapes behavior more than motivation does, so design the space around you.\n\n# Three\n\nMake good habits obvious with an **implementation intention** that names a time and place for the action."
        let ideas = Study.keyIdeas(book)
        XCTAssertEqual(ideas.first, "Small habits compound into remarkable results over time.")
        XCTAssertTrue(ideas[1].hasPrefix("The habit loop has four parts"))
        XCTAssertEqual(ideas.count, 3)
        XCTAssertEqual(Study.recap("# Two\n\nThe habit loop has four parts, and each one can be designed on purpose.\n\nEnvironment shapes behavior more than motivation does. Design the space around you and the habit follows."),
                       ["Environment shapes behavior more than motivation does.", "Design the space around you and the habit follows."])
        let qs = Study.quiz(book, book: book)
        XCTAssertEqual(qs.count, 3)
        XCTAssertTrue(qs[0].question.contains("_____") && !qs[0].question.contains("compound interest"))
        XCTAssertTrue(qs.allSatisfy { $0.choices.count == 3 && $0.choices.contains($0.answer) })
        XCTAssertEqual(Study.quiz(book, book: book), qs)
    }

    func testMorningLineIsReadable() {
        let content = "# Title\n\nShort.\n\n" + String(repeating: "A long readable paragraph with words. ", count: 10)
        let line = Nudge.line(from: content)
        XCTAssertNotNil(line); XCTAssertLessThanOrEqual(line?.count ?? 999, 171); XCTAssertFalse(line?.hasPrefix("#") ?? true)
    }
}
