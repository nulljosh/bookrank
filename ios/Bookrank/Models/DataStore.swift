import Foundation

@Observable
@MainActor
final class DataStore {
    let books: [Book]
    let library: Library
    let picks: [TopPick]

    /// Summaries are private per-account (see library.html), so they are fetched rather
    /// than bundled. Empty until `loadSummaries()` runs, and empty again after sign-out.
    private(set) var summaryIndex: [SummaryEntry] = []
    private(set) var summaryError: String?

    init() {
        books = Self.load("books")
        library = Self.load("library")
        picks = Self.load("picks")
    }

    /// One fetch for the whole shelf. Twenty rows for one owner is small enough that
    /// pulling `content` up front costs less than a second round trip per summary, and
    /// it keeps `summaryMarkdown(for:)` synchronous so the reader view stays unchanged.
    /// ponytail: fetch-everything; page it if a shelf ever runs to hundreds of rows.
    func loadSummaries() async {
        do {
            summaryIndex = try await supabase
                .from("bookrank_summaries")
                .select("slug,title,content")
                .order("title")
                .execute()
                .value
            summaryError = nil
        } catch {
            summaryIndex = []
            summaryError = error.localizedDescription
        }
    }

    func clearSummaries() {
        summaryIndex = []
        summaryError = nil
    }

    func summaryMarkdown(for slug: String) -> String {
        summaryIndex.first { $0.slug == slug }?.content
            ?? "This summary isn't on your shelf."
    }

    private static func load<T: Decodable>(_ name: String) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            fatalError("Missing or malformed \(name).json in app bundle")
        }
        return decoded
    }
}
