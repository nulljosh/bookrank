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
                .select("id,slug,title,content,updated_at,listen")
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

    func cover(for title: String) -> String? { books.first { $0.title.caseInsensitiveCompare(title) == .orderedSame }?.cover }

    func summary(for slug: String) -> SummaryEntry? { summaryIndex.first { $0.slug == slug } }

    /// Persist listen progress + scripts on the row (same shape the web writes).
    func saveListen(_ state: ListenState, for slug: String) async {
        guard let i = summaryIndex.firstIndex(where: { $0.slug == slug }), let id = summaryIndex[i].rowID else { return }
        summaryIndex[i].listen = state
        struct Patch: Encodable { let listen: ListenState }
        _ = try? await supabase.from("bookrank_summaries").update(Patch(listen: state)).eq("id", value: id).execute()
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
