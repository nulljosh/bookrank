import Foundation

extension Inbox {
    /// Turns what the share extension saved into books on your account: the shared text as is, or a web page's
    /// paragraphs with a link back. Anything that cannot be saved yet (signed out, offline) waits for next time.
    @MainActor static func importAll(into store: DataStore) async {
        for item in take() {
            var paras = item.text.isEmpty ? [] : item.text.components(separatedBy: "\n\n")
            if paras.isEmpty, let s = item.url, let u = URL(string: s),
               let (data, _) = try? await URLSession.shared.data(from: u), let html = String(data: data, encoding: .utf8) {
                paras = article(fromHTML: html)
            }
            let source = item.url.flatMap(URL.init(string:)).map { "\n\n[From \($0.host() ?? $0.absoluteString)](\($0.absoluteString))" } ?? ""
            let md = "## \(item.title)\n\n" + (paras.isEmpty ? (item.url ?? "") : paras.joined(separator: "\n\n")) + source
            do { try await store.addBook(title: item.title, markdown: md) } catch { add(item); ErrorLog.note("Share import: \(error.localizedDescription)") }
        }
    }
}
