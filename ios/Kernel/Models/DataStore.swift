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

    /// The linked Goodreads shelves: currently reading, want to read, and read books with no
    /// summary here yet (title match, same rule as the web), newest read first.
    struct GoodreadsBook: Identifiable, Codable, Hashable {
        let title: String; let author: String; let cover: String?; let url: String?; let readAt: String?; let rating: Double?   // Goodreads allows halves now
        // From a Goodreads sign-in only (Goodreads.swift): the review, the book id and the latest progress.
        var review: String? = nil; var bookId: String? = nil
        var progress: Int? = nil; var page: Int? = nil; var of: Int? = nil
        var id: String { title + author }
        /// "Aug 2026": the month the shelf says it was finished.
        var when: String? { readAt.flatMap { try? Date($0, strategy: .iso8601.year().month().day()) }?.formatted(.dateTime.month(.abbreviated).year()) }
    }
    private(set) var goodreadsReading: [GoodreadsBook] = []
    private(set) var goodreadsToRead: [GoodreadsBook] = []
    private(set) var goodreadsQueue: [GoodreadsBook] = []
    private(set) var goodreadsRead: [GoodreadsBook] = []   // the whole read shelf, for Your reading
    func loadGoodreads(_ id: String?) async {
        if CommandLine.flag("UITEST_SNAPSHOT") && Goodreads.shared.data == nil {   // screenshots: the shelves without a linked account
            let b = { (t: String, a: String, r: Double?, d: String?) in GoodreadsBook(title: t, author: a, cover: nil, url: nil, readAt: d, rating: r) }
            var r = GoodreadsBook(title: "The Man Who Solved the Market", author: "Gregory Zuckerman", cover: "https://covers.openlibrary.org/b/isbn/9780735217980-M.jpg", url: nil, readAt: nil, rating: nil); r.progress = 63; r.page = 230; r.of = 368
            goodreadsReading = [r]
            var q = b("How AI Thinks", "Nigel Toon", 4, "2026-09-28"); q.review = "Clear on how models actually work, without the hype. The chapter on training data is worth the price alone."
            goodreadsQueue = [q, b("Fiend", "Peter Stenson", 3.5, "2026-08-11")]
            goodreadsRead = goodreadsQueue + [b("Atomic Habits", "James Clear", 4, "2025-03-02"), b("Deep Work", "Cal Newport", 4.5, "2025-07-19"), b("Sapiens", "Yuval Noah Harari", 4, "2024-11-30")]
            goodreadsToRead = [b("System Design Interview", "Alex Xu", nil, nil)]
            return
        }
        var reading: [GoodreadsBook], read: [GoodreadsBook], toRead: [GoodreadsBook]
        if let g = Goodreads.shared.data {   // signed in to Goodreads on this device: every shelf, reviews, progress
            (reading, read, toRead) = (g.shelves["currently-reading"] ?? [], g.shelves["read"] ?? [], g.shelves["to-read"] ?? [])
        } else if let id {   // only a profile link: the public Currently Reading box is all Goodreads still shows
            struct Out: Decodable { let books: [GoodreadsBook]? }
            let url = URL(string: "https://bookrank.jaybulb.com/api/goodreads?user=\(id)&shelf=currently-reading")!
            let data = try? await URLSession.shared.data(from: url).0
            (reading, read, toRead) = (data.flatMap { try? JSONDecoder().decode(Out.self, from: $0) }?.books ?? [], [], [])
        } else { goodreadsReading = []; goodreadsToRead = []; goodreadsQueue = []; goodreadsRead = []; return }
        let norm = { (s: String) in s.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces) }
        // Split each title once: with 500 summaries and 500 read books this runs 250,000 times.
        let have = summaryIndex.map { norm($0.title) }.filter { !$0.isEmpty }.map { (words: Set($0.split(separator: " ")), flat: $0.replacingOccurrences(of: " ", with: "")) }
        goodreadsReading = reading
        goodreadsToRead = toRead
        goodreadsRead = read
        goodreadsQueue = read.filter { b in
            let t = norm(b.title), words = Set(t.split(separator: " ")), flat = t.replacingOccurrences(of: " ", with: "")
            return !have.contains { h in h.words.isSubset(of: words) || flat.contains(h.flat) }
        }.sorted { ($0.readAt ?? "") > ($1.readAt ?? "") }
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
        guard !CommandLine.flag("UITEST_SNAPSHOT"), let d = try? Data(contentsOf: cacheURL) else { return [] }
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
        if CommandLine.flag("UITEST_SNAPSHOT") { summaryIndex = Self.sampleShelf(); Spotlight.index(summaryIndex); return }
        do {
            let data = try await API.call("GET", "/rest/bookrank_summaries?select=id,slug,title,content,created_at,updated_at,listen,cover,share_token,collection,notes&order=title")
            summaryIndex = try JSONDecoder().decode([SummaryEntry].self, from: data)
            summaryError = nil
            writeCache()
            Spotlight.index(summaryIndex)
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
        // Two highlights on a book whose text is fine for the store, so Highlights has something to show.
        let marked = ListenState(for: "", chapters: [:], pos: .init(ch: 0, line: 0), marks: [
            .init(ch: 1, text: "Gephi is an open-source network-graph visualization tool, good for exploring relationships and connections as node-and-edge graphs."),
            .init(ch: 0, text: "ImageQuilts lets you compile grids of related images into a single collage, useful for quick visual analysis.")])
        let shelf: [SummaryEntry] = picks.compactMap { slug in
            guard let url = Bundle.main.url(forResource: slug, withExtension: "md") ?? Bundle.main.url(forResource: slug, withExtension: "md", subdirectory: "summaries"),
                  let text = try? String(contentsOf: url, encoding: .utf8) else { return nil }
            // The Optimist is partway through, so the store shots show the Continue card.
            let partway = slug == "the-optimist"
            return SummaryEntry(rowID: nil, slug: slug, title: titles[slug] ?? slug, content: text, updatedAt: partway ? "snapshot" : nil,
                                listen: partway ? ListenState(for: "snapshot", chapters: [:], pos: .init(ch: 3, line: 0)) : slug == "data-science" ? marked : nil, cover: covers[slug], shareToken: nil)
        }.sorted { $0.title < $1.title }
        // UITEST_SHELF=<n> in the environment: a long shelf (500 is Goodreads-sized), to check scrolling and search stay smooth.
        guard let n = Int(ProcessInfo.processInfo.environment["UITEST_SHELF"] ?? ""), !shelf.isEmpty else { return shelf }
        return (0..<n).map { i -> SummaryEntry in let e = shelf[i % shelf.count]
            return SummaryEntry(rowID: nil, slug: "\(e.slug)-\(i)", title: "\(e.title) \(i + 1)", content: e.content, updatedAt: nil, listen: nil, cover: e.cover, shareToken: nil) }
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
            if let id = e.rowID { _ = try? await patch(id, ["cover": url]) }
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
            guard (try? await patch(id, ["share_token": token])) != nil else { return nil }
            summaryIndex[i].shareToken = token
        }
        return URL(string: "https://bookrank.jaybulb.com/share.html?t=\(summaryIndex[i].shareToken!)")
    }
    func stopSharing(_ slug: String) async {
        guard let i = summaryIndex.firstIndex(where: { $0.slug == slug }), let id = summaryIndex[i].rowID else { return }
        _ = try? await patch(id, ["share_token": NSNull()])
        summaryIndex[i].shareToken = nil
    }

    /// One row update, the same PATCH the web's spark.js makes.
    /// Side data only (cover, share link, listen state). jaybulb-api stamps updated_at on every
    /// PATCH unless it is sent, and a new updated_at throws the saved listen position away
    /// (listen.for must equal it), so send the row's own value back unchanged.
    private func patch(_ id: String, _ fields: [String: Any]) async throws {
        var fields = fields
        if let at = summaryIndex.first(where: { $0.rowID == id })?.updatedAt { fields["updated_at"] = at }
        _ = try await API.call("PATCH", "/rest/bookrank_summaries?id=eq.\(id)", json: fields)
    }

    func summary(for slug: String) -> SummaryEntry? { summaryIndex.first { $0.slug == slug } }

    /// Your books as last kept on disk (the screenshot shelf in screenshot runs), for Siri and the command palette.
    static func shelf() -> [SummaryEntry] { CommandLine.flag("UITEST_SNAPSHOT") ? sampleShelf() : readCache() }
    /// The book you are partway through, from the rows kept on disk (or the screenshot shelf), for Continue my book.
    static func lastStarted() -> SummaryEntry? {
        shelf().first { e in e.listen?.for == e.updatedAt && ((e.listen?.pos.ch ?? 0) > 0 || (e.listen?.pos.line ?? 0) > 0) }
    }

    /// Your collections, A to Z. Same as the web's.
    var collections: [String] { Set(summaryIndex.compactMap(\.collection)).sorted { $0.localizedStandardCompare($1) == .orderedAscending } }
    /// Your note under a chapter; empty removes it. Side data, so updated_at stays.
    func setNote(_ text: String, ch: Int, for slug: String) async {
        guard let i = summaryIndex.firstIndex(where: { $0.slug == slug }) else { return }
        var notes = summaryIndex[i].notes ?? [:]
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        notes["\(ch)"] = t.isEmpty ? nil : String(t.prefix(4000))
        summaryIndex[i].notes = notes
        writeCache()
        if let id = summaryIndex[i].rowID { _ = try? await patch(id, ["notes": notes]) }
    }
    /// Put a book in a collection, or none. Side data, so updated_at stays.
    func setCollection(_ name: String?, for slug: String) async {
        guard let i = summaryIndex.firstIndex(where: { $0.slug == slug }) else { return }
        let name = String(name?.trimmingCharacters(in: .whitespaces).prefix(60) ?? "")
        summaryIndex[i].collection = name.isEmpty ? nil : name
        writeCache()
        if let id = summaryIndex[i].rowID { _ = try? await patch(id, ["collection": name.isEmpty ? NSNull() as Any : name]) }
    }

    /// Persist listen progress + scripts on the row (same shape the web writes).
    /// Highlights are merged with the row first, so another device's highlights survive; returns the merged list.
    @discardableResult
    func saveListen(_ state: ListenState, for slug: String) async -> [ListenState.Mark] {
        var state = state
        let local = state.marks ?? []
        guard let id = summary(for: slug)?.rowID else { return local }
        struct Row: Decodable { let listen: ListenState? }
        if let data = try? await API.call("GET", "/rest/bookrank_summaries?id=eq.\(id)&select=listen"),
           let row = try? JSONDecoder().decode([Row].self, from: data).first {
            let base = summary(for: slug)?.listen?.marks ?? []
            state.marks = ListenState.merge(base: base, local: local, server: row.listen?.marks ?? [])
        }
        guard let i = summaryIndex.firstIndex(where: { $0.slug == slug }) else { return state.marks ?? local }
        summaryIndex[i].listen = state
        writeCache()
        if let json = try? JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) { _ = try? await patch(id, ["listen": json]) }
        return state.marks ?? local
    }

    /// One markdown file per summary in a temp folder, for the share sheet (Files, AirDrop, Mail, anything).
    func writeExport() -> [URL] {
        let dir = FileManager.default.temporaryDirectory.appending(path: "kernel-export", directoryHint: .isDirectory)
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
