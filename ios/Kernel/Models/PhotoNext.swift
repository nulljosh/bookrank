import Foundation

/// "Photograph next": books from your Goodreads shelves you mean to summarize, marked so the read list doubles as
/// the summary queue (#81). Marked books sort to the top of their shelf.
/// ponytail: kept on this device only; move it to the account when two devices need the same queue.
@MainActor @Observable
final class PhotoNext {
    static let shared = PhotoNext()
    private static let key = "kernel.photoNext"
    private(set) var ids = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])

    func toggle(_ id: String) {
        if ids.remove(id) == nil { ids.insert(id) }
        UserDefaults.standard.set(Array(ids), forKey: Self.key)
    }

    /// Marked books first, the rest in their shelf's own order.
    func ordered(_ books: [DataStore.GoodreadsBook]) -> [DataStore.GoodreadsBook] {
        books.filter { ids.contains($0.id) } + books.filter { !ids.contains($0.id) }
    }
}
