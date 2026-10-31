import Foundation

/// Browse by topic: a book's topics from its title, on the device, from topics.json (the same list topics.js reads).
/// A book can sit in more than one topic.
enum Topics {
    /// Topic names in file order, each with one case-insensitive whole-word pattern.
    static let all: [(name: String, re: NSRegularExpression)] = {
        guard let url = Bundle.main.url(forResource: "topics", withExtension: "json"), let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: [String]] else { return [] }
        // JSONSerialization drops key order, so read the names in the order the file lists them.
        let text = String(decoding: data, as: UTF8.self)
        return obj.keys.sorted { text.range(of: "\"\($0)\"")!.lowerBound < text.range(of: "\"\($1)\"")!.lowerBound }.compactMap { name in
            (try? NSRegularExpression(pattern: "\\b(?:\(obj[name]!.joined(separator: "|")))\\b", options: .caseInsensitive)).map { (name, $0) }
        }
    }()

    static func of(_ title: String) -> [String] {
        all.filter { $0.re.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)) != nil }.map(\.name)
    }

    /// For the "finished" or a "topic:<name>" Show filter, whether the book stays; nil for any other filter.
    static func keep(_ show: String, _ e: SummaryEntry) -> Bool? {
        show == "finished" ? e.notes?["finished"] != nil : show.hasPrefix("topic:") ? of(e.title).contains(String(show.dropFirst(6))) : nil
    }

    /// The topics two books or more share.
    static func shelf(_ titles: [String]) -> [String] {
        all.map(\.name).filter { t in titles.filter { of($0).contains(t) }.count >= 2 }
    }
}
