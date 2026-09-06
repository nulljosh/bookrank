import SwiftUI

/// Chapters: the coarsest heading level that yields at least two, "# " before "## ", the
/// same rule as listen.js chapters(). A leading heading with nothing under it is the book
/// title, not a chapter. No headings = one chapter.
func parseChapters(_ markdown: String) -> [Speaker.Chapter] {
    func split(_ mark: String) -> [(title: String, text: String, body: String)] {
        var parts: [(String, String, String)] = []
        var cur: [String]? = nil
        for line in markdown.components(separatedBy: "\n") {
            if line.hasPrefix(mark + " ") {
                if let c = cur { parts.append(pack(c)) }
                cur = [line]
            } else if cur != nil { cur!.append(line) }
        }
        if let c = cur { parts.append(pack(c)) }
        func pack(_ ls: [String]) -> (String, String, String) {
            (String(ls[0].dropFirst(mark.count + 1)).trimmingCharacters(in: .whitespaces), ls.joined(separator: "\n"),
             ls.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return parts
    }
    let h1 = split("#").enumerated().filter { $0.offset > 0 || !$0.element.body.isEmpty }.map(\.element)
    let h2 = split("##")
    let parts = h1.count > 1 ? h1 : (h2.isEmpty ? h1 : h2)
    if parts.isEmpty { return markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [.init(title: "Whole book", text: markdown)] }
    return parts.map { .init(title: $0.title, text: $0.text) }
}

/// The listen view: progress bar, transcript with the spoken line and word highlighted,
/// auto-scroll, chapter menu and share link. Mirrors listen.js mount().
struct SummaryDetailView: View {
    let slug: String
    let store: DataStore
    var speaker = Speaker.shared
    @State private var shareURL: URL?

    var body: some View {
        let entry = store.summary(for: slug)
        VStack(spacing: 0) {
            ProgressView(value: speaker.progress).progressViewStyle(.linear).tint(.accentColor)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if speaker.loading { Text("Preparing this chapter…").foregroundStyle(.secondary) }
                        ForEach(speaker.lines.indices, id: \.self) { i in
                            LineView(line: speaker.lines[i], on: i == speaker.line && (speaker.playing || speaker.paused),
                                     word: i == speaker.line ? speaker.word : nil)
                                .id(i)
                                .onTapGesture { speaker.go(to: speaker.ch, line: i) }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: 680, alignment: .leading)
                    .frame(maxWidth: .infinity)
                }
                .onChange(of: speaker.line) { _, l in withAnimation { proxy.scrollTo(l, anchor: .center) } }
            }
        }
        .navigationTitle(entry?.title ?? "Summary")
        .toolbar {
            ListenControls()
            if let url = shareURL {
                ShareLink(item: url) { Label("Share", systemImage: "square.and.arrow.up") }
                    .contextMenu { Button("Stop sharing", role: .destructive) { Task { await store.stopSharing(slug); shareURL = nil } } }
            } else {
                Button("Share", systemImage: "square.and.arrow.up") { Task { shareURL = await store.shareURL(for: slug) } }
            }
        }
        .task {
            if let t = entry?.shareToken { shareURL = URL(string: "https://bookrank.heyitsmejosh.com/share.html?t=\(t)") }
            speaker.load(slug: slug, chapters: parseChapters(store.summaryMarkdown(for: slug)),
                         entry: entry) { await store.saveListen($0, for: slug) }
        }
        .overlay(alignment: .bottom) {
            Text(speaker.status.isEmpty ? "\(speaker.chapters.count) chapters" : speaker.status)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(.bar)
        }
    }
}

/// One spoken line. Host lines show "A"/"B"; note lines render their markdown. While a
/// line is being spoken the current word is marked, plain text only, formatting returns
/// when the line is done.
private struct LineView: View {
    let line: ListenState.Line
    let on: Bool
    let word: Range<Int>?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if line.md == nil { Text(line.host).font(.caption.weight(.semibold)).foregroundStyle(.tertiary).padding(.top, 3) }
            text
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(on ? Color.secondary.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 6))
        .foregroundStyle(on ? .primary : .secondary)
    }

    private var text: Text {
        if on, let w = word, let r = Range(NSRange(location: w.lowerBound, length: w.count), in: line.line) {
            return Text(line.line[..<r.lowerBound]) + Text(line.line[r]).foregroundStyle(Color.accentColor).bold() + Text(line.line[r.upperBound...])
        }
        if let md = line.md, let a = try? AttributedString(markdown: md.replacingOccurrences(of: "^([-*]|\\d+\\.) ", with: "• ", options: .regularExpression)
            .replacingOccurrences(of: "^#+ ", with: "", options: .regularExpression)) {
            return md.hasPrefix("#") ? Text(a).font(.title3.weight(.semibold)) : Text(a)
        }
        return Text(line.line)
    }
}
