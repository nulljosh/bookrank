import Foundation

// Field-for-field the iOS models (ios/Bookrank/Models/Book.swift), decoding the same
// three JSON files. Rating and reviewCount stay optional here too -- see that file's
// comment on the export bug that silently dropped 40 of 111 ranked books for months
// by making them non-optional.

struct Book: Codable, Identifiable {
    var id: Int { rank }
    let rank: Int
    let title: String
    let goodreadsURL: String
    let author: String
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
