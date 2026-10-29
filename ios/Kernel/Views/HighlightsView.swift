import SwiftUI
import UniformTypeIdentifiers

/// Every saved line from every book. A line opens its book at that line; Share sends it as a card. Same as the web's Highlights.
struct HighlightsView: View {
    let store: DataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let marks = store.summaryIndex.flatMap { e in (e.listen?.marks ?? []).map { (e, $0) } }
        NavigationStack {
            List(Array(marks.enumerated()), id: \.offset) { _, pair in
                let (e, m) = pair
                NavigationLink { SummaryDetailView(slug: e.slug, store: store, find: m.text) } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(m.text).font(.kernel(.body)).lineLimit(6)
                        HStack {
                            Text("\(e.title) · Ch \(m.ch + 1)").font(.kernel(.footnote)).foregroundStyle(.secondary).lineLimit(1)
                            Spacer()
                            ShareLink(item: HighlightCard(text: m.text, book: e.title), preview: SharePreview(e.title)) { Image(systemName: "square.and.arrow.up") }
                                .buttonStyle(.borderless).accessibilityLabel("Share as a card")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Highlights")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .automatic) {
                    ShareLink(item: MarkdownExport(text: exportMarkdown(store.summaryIndex)), preview: SharePreview("Kernel highlights.md")) { Label("Export", systemImage: "square.and.arrow.down") }
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 600)
        #endif
    }
}

/// A highlight as a 1080 square on Kernel gold, the line in Kernel Sans and the book under it. Same card as card.js.
/// Rendered only when it is shared.
struct HighlightCard: Transferable {
    let text: String, book: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { c in try await c.png() }
    }

    @MainActor func png() throws -> Data {
        let r = ImageRenderer(content: face); r.scale = 1
        let data = NSMutableData()
        guard let cg = r.cgImage, let d = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { throw CocoaError(.fileWriteUnknown) }
        CGImageDestinationAddImage(d, cg, nil); CGImageDestinationFinalize(d)
        return data as Data
    }

    @MainActor var face: some View {
        let ink = Color(red: 0x1d / 255, green: 0x1d / 255, blue: 0x1f / 255)
        return VStack(alignment: .leading) {
            Spacer()
            Text(text).font(.custom("KernelSans-Semibold", fixedSize: text.count > 220 ? 44 : 60)).lineSpacing(10).minimumScaleFactor(0.5)
            Spacer()
            HStack { Text(book).font(.custom("KernelSans-Medium", fixedSize: 34)).lineLimit(1); Spacer(); Text("Kernel.").font(.custom("KernelSans-Bold", fixedSize: 34)) }
        }
        .foregroundStyle(ink)
        .padding(80)
        .frame(width: 1080, height: 1080)
        .background(Color(red: 0xf5 / 255, green: 0xb8 / 255, blue: 0x3d / 255))
    }
}

extension View {
    /// The library's Highlights button and its sheet, shown once any book has a highlight.
    func highlights(_ store: DataStore) -> some View { modifier(HighlightsButton(store: store)) }
}

private struct HighlightsButton: ViewModifier {
    let store: DataStore
    @State private var open = false
    func body(content: Content) -> some View {
        content
            .toolbar {
                if store.summaryIndex.contains(where: { !($0.listen?.marks ?? []).isEmpty }) {
                    ToolbarItem(placement: .automatic) { Button("Highlights", systemImage: "highlighter") { open = true } }
                }
            }
            .sheet(isPresented: $open) { HighlightsView(store: store) }
    }
}

/// Every highlight as one Markdown file: a section per book, the chapter's title, each line as a quote.
/// Same layout as marksMarkdown in marks.js.
func exportMarkdown(_ books: [SummaryEntry]) -> String {
    var out = "# Highlights"
    for b in books {
        guard let marks = b.listen?.marks, !marks.isEmpty else { continue }
        let chs = parseChapters(b.content)
        out += "\n\n## \(b.title)\n"
        var last: Int?
        for m in marks.sorted(by: { $0.ch < $1.ch }) {
            if m.ch != last { out += "\n### \(chs.indices.contains(m.ch) ? chs[m.ch].title : "Chapter \(m.ch + 1)")\n"; last = m.ch }
            out += "\n> \(m.text)\n"
        }
    }
    return out + "\n"
}

/// The export as a .md file in the share sheet.
struct MarkdownExport: Transferable {
    let text: String
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: UTType(filenameExtension: "md") ?? .plainText) { Data($0.text.utf8) }
            .suggestedFileName("Kernel highlights.md")
    }
}

/// Today's five: the same five highlights as on the web today (dailyFive in marks.js), a different five tomorrow.
func dailyFive<T>(_ items: [T], text: (T) -> String, day: String, n: Int = 5) -> [T] {
    func h(_ s: String) -> UInt32 { var x: UInt32 = 0x811c9dc5; for u in s.utf16 { x = (x ^ UInt32(u)) &* 0x01000193 }; return x }
    return Array(items.sorted { (h(day + text($0)), text($0)) < (h(day + text($1)), text($1)) }.prefix(n))
}

/// Highlights come back a few at a time at the top of the library. Done hides them until tomorrow.
struct TodaysFive: View {
    let store: DataStore
    @AppStorage("kernel.reviewed") private var reviewed = ""

    var body: some View {
        let day = Date.now.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())   // local day, like the web
        let five = dailyFive(store.summaryIndex.flatMap { e in (e.listen?.marks ?? []).map { (e, $0) } }, text: { $0.1.text }, day: day)
        if !five.isEmpty && reviewed != day {
            Section {
                ForEach(five, id: \.1.text) { e, m in
                    #if os(macOS)
                    line(e, m).tag(e.slug)
                    #else
                    NavigationLink { SummaryDetailView(slug: e.slug, store: store, find: m.text) } label: { line(e, m) }
                    #endif
                }
                Button("Done for today") { withAnimation { reviewed = day } }.font(.kernel(.footnote)).foregroundStyle(.tint)
            } header: { Text("Today's five") }
        }
    }

    private func line(_ e: SummaryEntry, _ m: ListenState.Mark) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(m.text).font(.kernel(.body)).lineLimit(4)
            Text("\(e.title) · Ch \(m.ch + 1)").font(.kernel(.footnote)).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(.vertical, 2)
    }
}
