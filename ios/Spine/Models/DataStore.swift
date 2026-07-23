import Foundation

@Observable
final class DataStore {
    let books: [Book]
    let library: Library
    let picks: [TopPick]
    let summaryIndex: [SummaryEntry]

    init() {
        books = Self.load("books")
        library = Self.load("library")
        picks = Self.load("picks")
        summaryIndex = Self.load("summaries-index")
    }

    func summaryMarkdown(for slug: String) -> String {
        guard let url = Bundle.main.url(forResource: slug, withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return "Summary not found."
        }
        return text
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
