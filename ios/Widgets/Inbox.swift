import Foundation

/// What the share extension saved (text, or a web page's address), waiting in the App Group until Kernel opens
/// and turns it into a summary on your account. The extension never needs your sign-in.
enum Inbox {
    struct Item: Codable, Equatable { var title: String; var text: String; var url: String? }
    private static let key = "kernel.inbox"

    static func add(_ item: Item) {
        var all = peek(); all.append(item)
        if let d = try? JSONEncoder().encode(all) { WidgetFeed.defaults?.set(d, forKey: key) }
    }
    static func peek() -> [Item] {
        guard let d = WidgetFeed.defaults?.data(forKey: key), let all = try? JSONDecoder().decode([Item].self, from: d) else { return [] }
        return all
    }
    /// Hands over everything waiting and empties the inbox.
    static func take() -> [Item] { let all = peek(); WidgetFeed.defaults?.removeObject(forKey: key); return all }

    /// The readable paragraphs of a web page: the text of every <p> long enough to be prose, in order.
    /// ponytail: no readability scoring; nav and footer paragraphs are short and mostly drop under the bar.
    static func article(fromHTML html: String) -> [String] {
        let body = html.replacing(/(?s)<(script|style|nav|footer|header)[^>]*>.*?<\/\1>/, with: "")
        return body.matches(of: /(?s)<p[^>]*>(.*?)<\/p>/).map { plain(String($0.1)) }.filter { $0.count >= 60 }
    }
    private static func plain(_ s: String) -> String {
        s.replacing(/<[^>]+>/, with: "")
            .replacingOccurrences(of: "&nbsp;", with: " ").replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&rsquo;", with: "’").replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">").replacingOccurrences(of: "&amp;", with: "&")
            .replacing(/\s+/, with: " ").trimmingCharacters(in: .whitespaces)
    }
}
