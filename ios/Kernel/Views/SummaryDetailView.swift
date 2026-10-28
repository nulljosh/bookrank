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

/// A book: just its chapters. Tap one to read or listen to it.
struct SummaryDetailView: View {
    let slug: String
    let store: DataStore
    var chapter: Binding<Int?>? = nil   // Mac: this column picks the chapter the text column shows
    var speaker = Speaker.shared
    @State private var shareURL: URL?
    #if os(iOS)
    #endif

    var body: some View {
        let entry = store.summary(for: slug)
        Group {
            #if os(macOS)
            List(selection: chapter ?? .constant(nil)) { rows(entry) }.listStyle(.inset)
            #else
            List { rows(entry) }.frame(maxWidth: 680).frame(maxWidth: .infinity).listStyle(.plain)
            #endif
        }
        // iPhone: the cover header already names the book, so the bar holds only controls (like Music's album
        // pages). The Mac keeps it as the window title.
        #if os(iOS)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        #else
        .navigationTitle(entry?.title ?? "Summary")
        #endif
        .toolbar {
            if let url = shareURL {
                ShareLink(item: url) { Label("Share", systemImage: "square.and.arrow.up") }
                    .contextMenu { Button("Stop sharing", role: .destructive) { Task { await store.stopSharing(slug); shareURL = nil } } }
            } else {
                Button("Share", systemImage: "square.and.arrow.up") { Task { shareURL = await store.shareURL(for: slug) } }
            }
        }
        .task {
            if let t = entry?.shareToken { shareURL = URL(string: "https://bookrank.jaybulb.com/share.html?t=\(t)") }
            speaker.load(slug: slug, chapters: parseChapters(store.summaryMarkdown(for: slug)),
                         entry: entry) { await store.saveListen($0, for: slug) }
        }
    }

    /// The book up top (cover, title, how many chapters), then one row per chapter.
    @ViewBuilder
    private func rows(_ entry: SummaryEntry?) -> some View {
        HStack(spacing: 16) {
            Thumb(url: entry.flatMap { store.cover(for: $0) }, width: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry?.title ?? "Summary").font(.kernel(.title2, weight: .bold)).lineLimit(3)
                Text("\(speaker.chapters.count) chapters · \(duration(minutes(speaker.chapters.map(\.text).joined())))").font(.kernel(.footnote)).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .listRowSeparator(.hidden)
        .selectionDisabled()
        .accessibilityElement(children: .combine)
        if !speaker.marks.isEmpty {
            Section("Highlights") {
                ForEach(speaker.marks, id: \.self) { m in
                    #if os(macOS)
                    markRow(m).tag(m.ch)
                    #else
                    NavigationLink { ChapterView(index: m.ch) } label: { markRow(m) }
                    #endif
                }
            }
        }
        ForEach(speaker.chapters.indices, id: \.self) { i in
            #if os(macOS)
            chapterRow(i).tag(i)
            #else
            NavigationLink { ChapterView(index: i) } label: { chapterRow(i) }
            #endif
        }
    }

    private func markRow(_ m: ListenState.Mark) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(m.text).lineLimit(3)
            if speaker.chapters.indices.contains(m.ch) { Text(speaker.chapters[m.ch].title).font(.kernel(.footnote)).foregroundStyle(.secondary).lineLimit(1) }
        }
        .padding(.vertical, 3)
    }

    private func chapterRow(_ i: Int) -> some View {
        HStack(spacing: 10) {
            Text(speaker.chapters[i].title).lineLimit(2)
            Spacer(minLength: 8)
            Text("\(duration(minutes(speaker.chapters[i].text)))").font(.kernel(.footnote)).foregroundStyle(.tertiary).monospacedDigit()
            if i == speaker.ch && (speaker.line > 0 || speaker.playing) {
                Label("Resume", systemImage: "play.circle").font(.kernel(.footnote)).foregroundStyle(.secondary).labelStyle(.titleAndIcon)
            }
        }
        .padding(.vertical, 3)
    }
}

/// One chapter: the text, one Listen button. The spoken line and word are highlighted
/// and followed. Mirrors listen.js mount().
struct ChapterView: View {
    let index: Int
    var speaker = Speaker.shared

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    if speaker.loading { Text("Preparing this chapter…").foregroundStyle(.secondary) }
                    ForEach(speaker.lines.indices, id: \.self) { i in
                        LineView(line: speaker.lines[i], on: i == speaker.line && (speaker.playing || speaker.paused),
                                 dim: speaker.playing || speaker.paused,
                                 word: i == speaker.line ? speaker.word : nil,
                                 marked: speaker.isMarked(speaker.lines[i], in: speaker.ch))
                            .contextMenu {
                                let m = speaker.isMarked(speaker.lines[i], in: speaker.ch)
                                Button(m ? "Remove highlight" : "Highlight", systemImage: m ? "highlighter.badge.minus" : "highlighter") { speaker.toggleMark(speaker.lines[i]) }
                            }
                            .id(i)
                            .onTapGesture { speaker.go(to: speaker.ch, line: i) }
                    }
                }
                .padding(24)
                .frame(maxWidth: 680, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: speaker.line) { _, l in withAnimation { proxy.scrollTo(l, anchor: .center) } }
            // A long paragraph is taller than the screen, so centring the line is not enough: slide the
            // anchor down the line as the word moves through it, so the spoken word stays on screen.
            .onChange(of: speaker.word) { _, w in
                guard let w, speaker.lines.indices.contains(speaker.line) else { return }
                let len = max(1, speaker.lines[speaker.line].line.count)
                guard len > 320 else { return }
                let f = min(max(Double(w.lowerBound) / Double(len), 0.12), 0.8)
                withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo(speaker.line, anchor: UnitPoint(x: 0.5, y: f)) }
            }
        }
        // The chapter's own heading opens the text, so on iPhone the bar holds only the controls.
        #if os(iOS)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        #else
        .navigationTitle(speaker.chapters.indices.contains(speaker.ch) ? speaker.chapters[speaker.ch].title : "")
        #endif
        .toolbar { ListenControls() }
        .task { if speaker.ch != index { speaker.open(index) } }
    }
}

/// One spoken line. Host lines show "A"/"B"; note lines render their markdown. While a
/// line is being spoken the current word is marked, plain text only, formatting returns
/// when the line is done.
private struct LineView: View {
    @Environment(\.colorScheme) private var colorScheme
    let line: ListenState.Line
    let on: Bool
    let dim: Bool   // only dim the other lines while something is being read
    let word: Range<Int>?
    var marked = false

    var body: some View {
        // One narrator, so no speaker label; a little air between lines for reading.
        text
        .lineSpacing(5)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(on ? Color.secondary.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .leading) { if marked { Capsule().fill(amber).frame(width: 3).padding(.vertical, 6) } }
        .foregroundStyle(on || !dim ? .primary : .secondary)
    }

    private var text: Text {
        if on, let w = word, let r = Range(NSRange(location: w.lowerBound, length: w.count), in: line.line) {
            // Highlighter pass over the word being read: the app's accent (navy, yellow in dark) behind
            // it, with the text flipped to read on top. The rest of the line stays dim.
            var word = AttributedString(String(line.line[r]))
            word.backgroundColor = Color.accentColor
            word.foregroundColor = colorScheme == .dark ? .black : .white  // navy takes white, yellow takes black
            word.inlinePresentationIntent = .stronglyEmphasized
            return Text(line.line[..<r.lowerBound]).foregroundStyle(.secondary) + Text(word) + Text(line.line[r.upperBound...]).foregroundStyle(.secondary)
        }
        if let md = line.md, let a = try? AttributedString(markdown: md.replacingOccurrences(of: "^([-*]|\\d+\\.) ", with: "• ", options: .regularExpression)
            .replacingOccurrences(of: "^#+ ", with: "", options: .regularExpression)) {
            // "# " is the chapter's own title, so it leads; "##" and below are its sections.
            if md.hasPrefix("# ") { return Text(a).font(.kernel(.title2, weight: .bold)) }
            return md.hasPrefix("#") ? Text(a).font(.kernel(.title3, weight: .semibold)) : Text(a)
        }
        return Text(line.line)
    }
}
