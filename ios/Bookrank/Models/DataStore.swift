import Foundation

@Observable
@MainActor
final class DataStore {
    /// ponytail: the shelf is gone from the UI (2026-09-21); books.json stays only for cover matching.
    let books: [Book]

    /// Summaries are private per-account (see library.html), so they are fetched rather
    /// than bundled. Empty until `loadSummaries()` runs, and empty again after sign-out.
    private(set) var summaryIndex: [SummaryEntry] = []
    private(set) var summaryError: String?

    /// Books on the linked Goodreads "read" shelf with no summary here yet (title match, same rule as the web).
    struct GoodreadsBook: Identifiable, Decodable { let title: String; let author: String; let cover: String?; let url: String?; var id: String { title + author } }
    private(set) var goodreadsQueue: [GoodreadsBook] = []
    func loadGoodreads(_ id: String?) async {
        guard let id, let url = URL(string: "https://bookrank.heyitsmejosh.com/api/goodreads?user=\(id)&shelf=read"),
              let (data, _) = try? await URLSession.shared.data(from: url) else { goodreadsQueue = []; return }
        struct Out: Decodable { let books: [GoodreadsBook]? }
        let all = (try? JSONDecoder().decode(Out.self, from: data))?.books ?? []
        let norm = { (s: String) in s.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces) }
        let have = summaryIndex.map { norm($0.title) }.filter { !$0.isEmpty }
        goodreadsQueue = all.filter { b in
            let t = norm(b.title), words = Set(t.split(separator: " "))
            return !have.contains { h in h.split(separator: " ").allSatisfy(words.contains) || t.replacingOccurrences(of: " ", with: "").contains(h.replacingOccurrences(of: " ", with: "")) }
        }
    }

    init() {
        books = Self.load("books")
        summaryIndex = Self.readCache()
    }

    // MARK: Offline copy
    // The last good fetch is kept on disk so the list, the text and any already-made Listen
    // scripts work with no connection. Sign-out and account deletion remove it.
    private static let cacheURL = URL.applicationSupportDirectory.appending(path: "summaries.json")
    private static func readCache() -> [SummaryEntry] {
        guard !CommandLine.arguments.contains("UITEST_SNAPSHOT"), let d = try? Data(contentsOf: cacheURL) else { return [] }
        return (try? JSONDecoder().decode([SummaryEntry].self, from: d)) ?? []
    }
    private func writeCache() {
        try? FileManager.default.createDirectory(at: Self.cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(summaryIndex).write(to: Self.cacheURL, options: [.atomic, .completeFileProtection])
    }

    /// One fetch for the whole shelf. Twenty rows for one owner is small enough that
    /// pulling `content` up front costs less than a second round trip per summary, and
    /// it keeps `summaryMarkdown(for:)` synchronous so the reader view stays unchanged.
    /// ponytail: fetch-everything; page it if a shelf ever runs to hundreds of rows.
    func loadSummaries() async {
        if CommandLine.arguments.contains("UITEST_SNAPSHOT") { summaryIndex = Self.sampleShelf(); return }
        do {
            summaryIndex = try await supabase
                .from("bookrank_summaries")
                .select("id,slug,title,content,updated_at,listen,cover,share_token")
                .order("title")
                .execute()
                .value
            summaryError = nil
            writeCache()
            Task { await fillCovers() }
        } catch {
            // Offline or the server failed: keep whatever is on disk and only show the error if there is nothing.
            if summaryIndex.isEmpty { summaryIndex = Self.readCache() }
            summaryError = summaryIndex.isEmpty ? error.localizedDescription : nil
        }
    }

    /// Screenshot automation only: a believable shelf from the bundled sample summaries.
    private static func sampleShelf() -> [SummaryEntry] {
        let picks = ["the-optimist", "the-contrarian", "ai-in-business", "data-science", "statistics-for-dummies", "good-feng-shui"]
        let titles = ["the-optimist": "The Optimist", "the-contrarian": "The Contrarian", "ai-in-business": "AI in Business For Dummies",
                      "data-science": "Data Science For Dummies", "statistics-for-dummies": "Statistics For Dummies", "good-feng-shui": "Good Feng Shui"]
        // Verified by eye against the real editions (2026-10-02); the real shelf reads covers from its rows.
        let covers = ["the-optimist": "https://covers.openlibrary.org/b/id/15154965-M.jpg",
                      "the-contrarian": "https://covers.openlibrary.org/b/id/11433880-M.jpg",
                      "ai-in-business": "https://images-na.ssl-images-amazon.com/images/P/1394377347.01.L.jpg",
                      "data-science": "https://covers.openlibrary.org/b/id/13285377-M.jpg",
                      "statistics-for-dummies": "https://covers.openlibrary.org/b/id/9700982-M.jpg",
                      "good-feng-shui": "https://covers.openlibrary.org/b/id/14016705-M.jpg"]
        return picks.compactMap { slug in
            guard let url = Bundle.main.url(forResource: slug, withExtension: "md") ?? Bundle.main.url(forResource: slug, withExtension: "md", subdirectory: "summaries"),
                  let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            return SummaryEntry(rowID: nil, slug: slug, title: titles[slug] ?? slug, content: text, updatedAt: nil, listen: nil, cover: covers[slug], shareToken: nil)
        }.sorted { $0.title < $1.title }
    }

    /// Signed-out preview: one short original summary so anyone, including App Review, can press Listen without an account.
    func loadSample() {
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "md") ?? Bundle.main.url(forResource: "sample", withExtension: "md", subdirectory: "summaries"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        summaryIndex = [SummaryEntry(rowID: nil, slug: "sample", title: "The Art of War, a sample", content: text, updatedAt: nil, listen: nil, cover: nil, shareToken: nil)]
    }

    func clearSummaries() {
        summaryIndex = []
        summaryError = nil
        try? FileManager.default.removeItem(at: Self.cacheURL)
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

    /// Same as the web's resolveCover(): rows with no saved cover and no books.json match get an
    /// Open Library lookup (work cover, then ISBN/edition images, each probed), saved to the row so
    /// every device finds it. A miss is retried next load, never cached.
    private func fillCovers() async {
        for e in summaryIndex where cover(for: e) == nil {
            guard let url = await lookupCover(e.title), let i = summaryIndex.firstIndex(where: { $0.slug == e.slug }) else { continue }
            summaryIndex[i].cover = url
            if let id = e.rowID { _ = try? await supabase.from("bookrank_summaries").update(["cover": url]).eq("id", value: id).execute() }
        }
        writeCache()
    }
    private func lookupCover(_ title: String) async -> String? {
        struct Doc: Decodable { let cover_i: Int?; let isbn: [String]?; let edition_key: [String]? }
        struct Out: Decodable { let docs: [Doc] }
        for param in ["title", "q"] {
            var c = URLComponents(string: "https://openlibrary.org/search.json")!
            c.queryItems = [.init(name: param, value: title), .init(name: "limit", value: "2"), .init(name: "fields", value: "cover_i,isbn,edition_key")]
            guard let (data, _) = try? await URLSession.shared.data(from: c.url!), let out = try? JSONDecoder().decode(Out.self, from: data) else { continue }
            for d in out.docs {
                let urls = (d.cover_i.map { ["https://covers.openlibrary.org/b/id/\($0)-M.jpg"] } ?? [])
                    + (d.isbn ?? []).prefix(4).map { "https://covers.openlibrary.org/b/isbn/\($0)-M.jpg?default=false" }
                    + (d.edition_key ?? []).prefix(3).map { "https://covers.openlibrary.org/b/olid/\($0)-M.jpg?default=false" }
                for u in urls where await loads(u) { return u }
            }
        }
        return nil
    }
    private func loads(_ u: String) async -> Bool {
        guard let url = URL(string: u), let (_, r) = try? await URLSession.shared.data(from: url) else { return false }
        return (r as? HTTPURLResponse)?.statusCode == 200
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
        writeCache()
        struct Patch: Encodable { let listen: ListenState }
        _ = try? await supabase.from("bookrank_summaries").update(Patch(listen: state)).eq("id", value: id).execute()
    }

    /// One markdown file per summary in a temp folder, for the share sheet (Files, AirDrop, Mail, anything).
    func writeExport() -> [URL] {
        let dir = FileManager.default.temporaryDirectory.appending(path: "bookrank-export", directoryHint: .isDirectory)
        try? FileManager.default.removeItem(at: dir)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return summaryIndex.compactMap { e in
            let url = dir.appending(path: "\(e.slug).md")
            return (try? "# \(e.title)\n\n\(e.content)\n".write(to: url, atomically: true, encoding: .utf8)) != nil ? url : nil
        }
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
