import Foundation

/// Bookrank has no HTTP API of its own (see docs/API.md: WebMCP tools only, no REST
/// endpoint) and the ranked shelf, to-read list and top picks are all static content
/// bundled into the iOS app from `Resources/*.json` and read straight off disk (see
/// `ios/Bookrank/Models/DataStore.swift`) rather than fetched at runtime. The only thing
/// that does touch a network there is per-account chapter summaries via Supabase, which
/// need a sign-in flow that doesn't belong on a watch face and isn't the point of a
/// glanceable companion. So this is a full local port: the same three JSON files, copied
/// into this target's `Resources/` and read the same way -- no pairing step, nothing to
/// go stale offline, and no fake backend invented to justify one.
@Observable
final class BookStore {
    let books: [Book]
    let library: Library
    let picks: [TopPick]

    init() {
        books = Self.load("books")
        library = Self.load("library")
        picks = Self.load("picks")
    }

    private static func load<T: Decodable>(_ name: String) -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            fatalError("Missing or malformed \(name).json in watch app bundle")
        }
        return decoded
    }
}
