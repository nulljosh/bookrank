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
                .select("id,slug,title,content,updated_at,listen,cover,share_token")
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

    /// Same rule as listen.js matchCover(): the row's own cover, else books.json by exact
    /// title, then either title starting with the other, then a contains match.
    func cover(for entry: SummaryEntry) -> String? {
        if let c = entry.cover { return c }
        let norm = { (s: String) in s.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces) }
        let t = norm(entry.title); guard !t.isEmpty else { return nil }
        let withCover = books.filter { $0.cover != nil }
        func pick(_ f: (String) -> Bool) -> String? { withCover.first { f(norm($0.title)) }?.cover }
        return pick { $0 == t } ?? pick { $0.hasPrefix(t) || t.hasPrefix($0) } ?? pick { $0.contains(t) || t.contains($0) }
    }

    /// Share link for a summary: mints a token on first use. Nil while signed out.
    func shareURL(for slug: String) async -> URL? {
        guard let i = summaryIndex.firstIndex(where: { $0.slug == slug }), let id = summaryIndex[i].rowID else { return nil }
        if summaryIndex[i].shareToken == nil {
            let token = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
            struct Patch: Encodable { let share_token: String }
            guard (try? await supabase.from("bookrank_summaries").update(Patch(share_token: token)).eq("id", value: id).execute()) != nil else { return nil }
            summaryIndex[i].shareToken = token
        }
        return URL(string: "https://bookrank.heyitsmejosh.com/share.html?t=\(summaryIndex[i].shareToken!)")
    }
    func stopSharing(_ slug: String) async {
        guard let i = summaryIndex.firstIndex(where: { $0.slug == slug }), let id = summaryIndex[i].rowID else { return }
        // A struct with a nil field is dropped by JSONEncoder; a dictionary of optionals encodes null.
        _ = try? await supabase.from("bookrank_summaries").update(["share_token": nil] as [String: String?]).eq("id", value: id).execute()
        summaryIndex[i].shareToken = nil
    }

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
