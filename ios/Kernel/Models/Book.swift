import Foundation

struct Book: Codable, Identifiable {
    var id: Int { rank }
    let rank: Int
    let title: String
    let goodreadsURL: String
    let author: String
    // Optional: 40 of 111 ranked books have no Goodreads rating. They were
    // silently dropped from the app for months because these were non-optional.
    let rating: Double?
    let reviewCount: String?
    let badges: [String]
    let notes: String
    let cover: String?
}

/// One row of `bookrank_summaries`. The table has no author column — the shelf is
/// single-user and the author is already on the matching `Book`, so carrying a second
/// copy would just be another thing to drift.
struct SummaryEntry: Codable, Identifiable {
    var id: String { slug }
    let rowID: String?          // row uuid on jaybulb-api; nil for bundled entries
    let slug: String
    let title: String
    let content: String
    let updatedAt: String?
    var listen: ListenState?
    var cover: String?
    var shareToken: String?
    var collection: String? = nil   // your own group for the book, one name or none
    var notes: [String: String]? = nil   // your note per chapter, keyed by chapter index; not in listen, so old builds cannot drop it
    var createdAt: String? = nil         // when the book was added, for Your year

    enum CodingKeys: String, CodingKey { case rowID = "id", slug, title, content, updatedAt = "updated_at", listen, cover, shareToken = "share_token", collection, notes, createdAt = "created_at" }
}

/// Mirrors the web's `listen` jsonb: generated scripts per chapter plus the resume point.
struct ListenState: Codable {
    struct Line: Codable, Hashable {
        let host: String; let line: String
        var md: String? = nil   // local only: the markdown behind a "read the notes" line
        enum CodingKeys: String, CodingKey { case host, line }
        init(host: String, line: String, md: String? = nil) { self.host = host; self.line = line; self.md = md }
    }
    /// `at`: when this place was reached, ms since 1970, so a save sent late loses to a newer one. Old rows have none.
    struct Pos: Codable { var ch: Int; var line: Int; var at: Double? = nil }
    /// A saved line: its chapter and its text, so it survives a rebuilt script. Same shape as listen.js.
    struct Mark: Codable, Hashable { var ch: Int; var text: String }
    var `for`: String
    var chapters: [String: [Line]]
    var pos: Pos
    var marks: [Mark]? = nil

    /// Highlights from two devices, the same rule as mergeMarks in marks.js. `base` is what this device last saw on
    /// the row: lines another device added since are kept, lines it removed go, this device's own changes win on top.
    /// A listening save that waited offline, checked against the row as it is now: the place reached later wins,
    /// highlights from both sides stay. Same rule as catchUp in marks.js.
    static func catchUp(_ queued: ListenState, server: ListenState?) -> ListenState {
        guard let server, server.for == queued.for else { return queued }
        var out = queued
        if (server.pos.at ?? 0) > (queued.pos.at ?? 0) { out.pos = server.pos }
        out.marks = merge(base: [], local: queued.marks ?? [], server: server.marks ?? [])
        return out
    }

    static func merge(base: [Mark], local: [Mark], server: [Mark]) -> [Mark] {
        let b = Set(base), s = Set(server), l = Set(local)
        return local.filter { !b.contains($0) || s.contains($0) } + server.filter { !b.contains($0) && !l.contains($0) }
    }
}

extension [SummaryEntry] {
    /// The library in the order picked in Sort (recent, title, progress, short), books in progress first. Same orders as the web.
    /// ponytail: progress parses every book's chapters per call; cache it if a big library stutters.
    func sorted(by sort: String, started: @escaping (SummaryEntry) -> Bool) -> [SummaryEntry] {
        let frac = { (e: SummaryEntry) in started(e) ? Double((e.listen?.pos.ch ?? 0) + 1) / Double(Swift.max(1, parseChapters(e.content).count)) : 0 }
        let by: [SummaryEntry] = switch sort {
        case "title": self.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case "progress": self.sorted { frac($0) > frac($1) }
        case "short": self.sorted { $0.content.count < $1.content.count }
        default: self.sorted { ($0.updatedAt ?? "") > ($1.updatedAt ?? "") }
        }
        return by.filter(started) + by.filter { !started($0) }
    }
}
