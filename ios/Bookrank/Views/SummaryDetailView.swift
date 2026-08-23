import SwiftUI

private struct Chapter: Identifiable {
    let id = UUID()
    let heading: String
    let body: String
}

private func parseSummary(_ markdown: String) -> (title: String, chapters: [Chapter]) {
    let lines = markdown.components(separatedBy: "\n")
    var title = "Summary"
    var chapters: [Chapter] = []
    var currentHeading: String?
    var currentBody: [String] = []

    func flush() {
        if let heading = currentHeading {
            chapters.append(Chapter(heading: heading, body: currentBody.joined(separator: "\n")))
        }
        currentBody = []
    }

    for line in lines {
        if line.hasPrefix("# ") {
            title = String(line.dropFirst(2))
        } else if line.hasPrefix("## ") {
            flush()
            currentHeading = String(line.dropFirst(3))
        } else {
            currentBody.append(line)
        }
    }
    flush()
    return (title, chapters)
}

// ponytail: chapter-tap navigation instead of a sticky-sidebar scroll-spy TOC — same jump-to-chapter
// outcome as the web version with far less code; add scroll-spy if users ask for inline sidebar reading.
struct SummaryDetailView: View {
    let slug: String
    let store: DataStore

    private var parsed: (title: String, chapters: [Chapter]) {
        parseSummary(store.summaryMarkdown(for: slug))
    }

    var body: some View {
        let data = parsed
        List(data.chapters) { chapter in
            NavigationLink(chapter.heading) {
                ChapterView(chapter: chapter)
            }
        }
        .navigationTitle(data.title)
        .overlay(alignment: .bottom) {
            Text("\(data.chapters.count) chapters · \(readMinutes(data.chapters)) min read")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
    }

    private func readMinutes(_ chapters: [Chapter]) -> Int {
        let words = chapters.reduce(0) { $0 + $1.body.split(separator: " ").count }
        return max(1, words / 200)
    }
}

// ponytail: hand-rolled block splitter (headings/bullets/rules/paragraphs) instead of a markdown
// package — this content only ever uses those four block types, and each block still renders
// inline bold/italic/links via AttributedString(markdown:). Reach for swift-markdown if summaries
// ever need tables or nested lists.
private enum Block: Identifiable {
    case heading(String)
    case bullets([String])
    case rule
    case paragraph(String)

    var id: String {
        switch self {
        case .heading(let s): return "h:\(s)"
        case .bullets(let items): return "b:\(items.joined())"
        case .rule: return "r:\(UUID())"
        case .paragraph(let s): return "p:\(s)"
        }
    }
}

private func parseBlocks(_ body: String) -> [Block] {
    var blocks: [Block] = []
    var paragraphLines: [String] = []
    var bulletLines: [String] = []

    func flushParagraph() {
        if !paragraphLines.isEmpty {
            blocks.append(.paragraph(paragraphLines.joined(separator: " ")))
            paragraphLines = []
        }
    }
    func flushBullets() {
        if !bulletLines.isEmpty {
            blocks.append(.bullets(bulletLines))
            bulletLines = []
        }
    }

    for rawLine in body.components(separatedBy: "\n") {
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.hasPrefix("### ") {
            flushParagraph(); flushBullets()
            blocks.append(.heading(String(line.dropFirst(4))))
        } else if line == "---" {
            flushParagraph(); flushBullets()
            blocks.append(.rule)
        } else if line.hasPrefix("- ") {
            flushParagraph()
            bulletLines.append(String(line.dropFirst(2)))
        } else if line.isEmpty {
            flushParagraph(); flushBullets()
        } else {
            flushBullets()
            paragraphLines.append(line)
        }
    }
    flushParagraph(); flushBullets()
    return blocks
}

private struct ChapterView: View {
    let chapter: Chapter

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(parseBlocks(chapter.body)) { block in
                    switch block {
                    case .heading(let text):
                        Text(.init(text))
                            .font(.title3.weight(.semibold))
                            .padding(.top, 8)
                    case .bullets(let items):
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(items, id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•").foregroundStyle(.secondary)
                                    Text(.init(item))
                                }
                            }
                        }
                    case .rule:
                        Divider()
                    case .paragraph(let text):
                        Text(.init(text))
                    }
                }
            }
            .textSelection(.enabled)
            .padding(24)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(chapter.heading)
    }
}
