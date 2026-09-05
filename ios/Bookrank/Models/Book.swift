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

struct LibraryLoan: Codable, Identifiable {
    var id: String { title }
    let title: String
    let author: String
    let summarySlug: String?
}

struct Library: Codable {
    let dueDate: String?
    let loans: [LibraryLoan]
    let toRead: [LibraryLoan]
}

struct TopPick: Codable, Identifiable {
    var id: String { title }
    let title: String
    let blurb: String
}

/// One row of `bookrank_summaries`. The table has no author column — the shelf is
/// single-user and the author is already on the matching `Book`, so carrying a second
/// copy would just be another thing to drift.
struct SummaryEntry: Codable, Identifiable {
    var id: String { slug }
    let rowID: String?          // Supabase uuid; nil for bundled entries
    let slug: String
    let title: String
    let content: String
    let updatedAt: String?
    var listen: ListenState?

    enum CodingKeys: String, CodingKey { case rowID = "id", slug, title, content, updatedAt = "updated_at", listen }
}

/// Mirrors the web's `listen` jsonb: generated scripts per chapter plus the resume point.
struct ListenState: Codable {
    struct Line: Codable { let host: String; let line: String }
    struct Pos: Codable { var ch: Int; var line: Int }
    var `for`: String
    var chapters: [String: [Line]]
    var pos: Pos
}
