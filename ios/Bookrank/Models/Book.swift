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
    let slug: String
    let title: String
    let content: String
}
