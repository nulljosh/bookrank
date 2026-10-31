import Foundation

/// Search by meaning: every line of your books that says something becomes a vector from /api/embed (the same
/// model as the web, kept on disk per book version so a book is read once); a search is one more vector and the
/// closest lines win. Same lines and floor as meaning.js. Apple's on-device NLEmbedding was tried first and
/// ranked the right line last (2026-10-28), so this goes through the server.
actor Meaning {
    static let shared = Meaning()
    struct Hit: Identifiable, Sendable {
        let slug: String, title: String, ch: Int, line: Int, chapter: String, text: String, score: Double
        var id: String { "\(slug)/\(ch)/\(line)" }
    }
    private struct Row: Codable { let ch: Int, line: Int, chapter: String, text: String, v: [Double] }
    private struct Kept: Codable { let version: String, rows: [Row] }
    private var index: [String: Kept] = [:]
    private static let dir = URL.applicationSupportDirectory.appending(path: "meaning")

    /// ponytail: a plain scan over every line; fine to tens of thousands, an index past that.
    func search(_ q: String, in books: [SummaryEntry], limit: Int = 5, floor: Double = 0.6) async -> [Hit] {
        guard let qv = await Self.embed([q])?.first else { return [] }
        var hits: [Hit] = []
        for b in books {
            for r in await rows(b) where !r.text.localizedCaseInsensitiveContains(q) {   // word matches already show above
                let s = cosine(qv, r.v)
                if s >= floor { hits.append(Hit(slug: b.slug, title: b.title, ch: r.ch, line: r.line, chapter: r.chapter, text: r.text, score: s)) }
            }
        }
        return Array(hits.sorted { $0.score > $1.score }.prefix(limit))
    }

    /// Connections: the lines in your other books closest in meaning to one line of yours. The line's own vector
    /// comes from its book's index when it is there, so most of the time this asks the server for nothing.
    func related(to text: String, from slug: String, in books: [SummaryEntry], limit: Int = 3, floor: Double = 0.7) async -> [Hit] {
        var v: [Double]? = nil
        if let own = books.first(where: { $0.slug == slug }) { v = await rows(own).first { $0.text == text }?.v }
        if v == nil { v = await Self.embed([text])?.first }
        guard let v else { return [] }
        var hits: [Hit] = []
        for b in books where b.slug != slug {
            for r in await rows(b) { let s = cosine(v, r.v); if s >= floor { hits.append(Hit(slug: b.slug, title: b.title, ch: r.ch, line: r.line, chapter: r.chapter, text: r.text, score: s)) } }
        }
        return Array(hits.sorted { $0.score > $1.score }.prefix(limit))
    }

    private func rows(_ b: SummaryEntry) async -> [Row] {
        let version = b.updatedAt ?? "\(b.content.count)", file = Self.dir.appending(path: "\(b.slug).json")
        if let k = index[b.slug] ?? (try? JSONDecoder().decode(Kept.self, from: Data(contentsOf: file))), k.version == version { index[b.slug] = k; return k.rows }
        var lines: [(ch: Int, line: Int, chapter: String, text: String)] = []
        for (ch, c) in parseChapters(b.content).enumerated() {
            for (line, l) in Speaker.blocks(c.text).enumerated() where !(l.md ?? "").hasPrefix("#") && l.line.count >= 30 { lines.append((ch, line, c.title, l.line)) }
        }
        var out: [Row] = []
        for start in stride(from: 0, to: lines.count, by: 100) {
            let part = Array(lines[start..<min(start + 100, lines.count)])
            guard let vs = await Self.embed(part.map(\.text)), vs.count == part.count else { return out }   // offline: what there is, not kept
            out += zip(part, vs).map { Row(ch: $0.ch, line: $0.line, chapter: $0.chapter, text: $0.text, v: $1) }
        }
        let k = Kept(version: version, rows: out)
        index[b.slug] = k
        try? FileManager.default.createDirectory(at: Self.dir, withIntermediateDirectories: true)
        try? JSONEncoder().encode(k).write(to: file, options: .atomic)
        return out
    }

    private static func embed(_ texts: [String]) async -> [[Double]]? {
        // Screenshot runs have no account: a few word groups stand in for the model so the section can be seen.
        if CommandLine.flag("UITEST_SNAPSHOT") {
            let groups = [["network", "graph", "connect", "relationship", "linked", "social"], ["visual", "chart", "picture", "see"], ["learn", "model", "predict"]]
            return texts.map { t in [0.05] + groups.map { g in Double(g.filter { t.lowercased().contains($0) }.count) } }
        }
        struct Out: Decodable { let vectors: [[Double]] }
        guard let data = try? await API.call("POST", "https://kernel.jaybulb.com/api/embed", json: ["texts": texts]) else { return nil }
        return (try? JSONDecoder().decode(Out.self, from: data))?.vectors
    }

    private func cosine(_ a: [Double], _ b: [Double]) -> Double {
        var d = 0.0, x = 0.0, y = 0.0
        for i in a.indices { d += a[i] * b[i]; x += a[i] * a[i]; y += b[i] * b[i] }
        return d / max((x * y).squareRoot(), 1e-9)
    }
}

import SwiftUI

/// "Close in meaning" under the library's word matches. A hit opens its book with the line found.
struct MeaningResults: View {
    let hits: [Meaning.Hit]
    let store: DataStore
    var title: LocalizedStringKey = "Close in meaning"

    var body: some View {
        if !hits.isEmpty {
            Section(title) {
                ForEach(hits) { h in
                    #if os(macOS)
                    row(h).tag(h.slug)
                    #else
                    NavigationLink { SummaryDetailView(slug: h.slug, store: store, find: h.text) } label: { row(h) }
                    #endif
                }
            }
        }
    }

    private func row(_ h: Meaning.Hit) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(h.title).font(.kernel(.body))
            Text("Ch \(h.ch + 1) · \(h.text)").font(.kernel(.footnote)).foregroundStyle(.secondary).lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}

/// One highlight's connections: the same idea elsewhere in your books, from the search-by-meaning index.
struct ConnectionsView: View {
    let text: String, slug: String, store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var hits: [Meaning.Hit]? = nil
    var body: some View {
        NavigationStack {
            List {
                Text(text).font(.kernelItalic(.body)).foregroundStyle(.secondary)
                if let hits {
                    if hits.isEmpty { Text("Nothing close in your other books yet.").foregroundStyle(.secondary) }
                    MeaningResults(hits: hits, store: store, title: "Also in your books")
                } else {
                    HStack(spacing: 8) { ProgressView(); Text("Looking across your books…").foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Connections")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task { hits = await Meaning.shared.related(to: text, from: slug, in: store.summaryIndex) }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 420)
        #endif
    }
}
