import Foundation

/// Kindle highlights from My Clippings.txt (on a Kindle plugged in by USB, under documents/). Each book's new
/// highlights become a "Kindle highlights" chapter on its summary, or a new book. Same parse as kindle.js:
/// notes and bookmarks are skipped and the same line twice is kept once.
enum Kindle {
    struct Book: Equatable { let title: String; let author: String; var lines: [String] }

    static func parse(_ text: String) -> [Book] {
        var books: [Book] = []
        for entry in text.replacingOccurrences(of: "\u{FEFF}", with: "").replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "==========") {
            let l = entry.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
            guard l.count > 2, l[1].range(of: "Your Highlight|Votre surlignement|Ihre Markierung|Tu subrayado", options: [.regularExpression, .caseInsensitive]) != nil else { continue }
            let line = l.dropFirst(3).joined(separator: " ").trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }
            let head = l[0].trimmingCharacters(in: .whitespaces)
            var title = head, author = ""
            if let m = head.wholeMatch(of: /(.*?)\s*\(([^()]*)\)\s*/) { title = String(m.1); author = String(m.2) }
            if let i = books.firstIndex(where: { $0.title == title }) { if !books[i].lines.contains(line) { books[i].lines.append(line) } }
            else { books.append(Book(title: title, author: author, lines: [line])) }
        }
        return books
    }

    /// Readwise's CSV export as the same books, or nil when the file is not one. Same as parseReadwise in kindle.js.
    static func parseReadwise(_ text: String) -> [Book]? {
        let rows = csv(text.replacingOccurrences(of: "\u{FEFF}", with: ""))
        guard let head = rows.first, let h = head.firstIndex(of: "Highlight"), let t = head.firstIndex(of: "Book Title") else { return nil }
        let a = head.firstIndex(of: "Book Author")
        var books: [Book] = []
        for r in rows.dropFirst() where r.count > max(h, t) {
            let title = r[t].trimmingCharacters(in: .whitespaces), line = r[h].replacing(/\s+/, with: " ").trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty, !line.isEmpty else { continue }
            if let i = books.firstIndex(where: { $0.title == title }) { if !books[i].lines.contains(line) { books[i].lines.append(line) } }
            else { books.append(Book(title: title, author: a.flatMap { r.indices.contains($0) ? r[$0] : nil } ?? "", lines: [line])) }
        }
        return books
    }

    /// CSV rows, quotes and newlines inside quotes included. Same as csv() in goodreads-export.js.
    static func csv(_ text: String) -> [[String]] {
        var rows: [[String]] = [[]], cell = "", quoted = false
        var it = Array(text).makeIterator(), next = it.next()
        while let c = next {
            next = it.next()
            if quoted { if c == "\"" { if next == "\"" { cell.append("\""); next = it.next() } else { quoted = false } } else { cell.append(c) } }
            else if c == "\"" { quoted = true }
            else if c == "," { rows[rows.count - 1].append(cell); cell = "" }
            else if c == "\n" || c == "\r" || c == "\r\n" { rows[rows.count - 1].append(cell); cell = ""; rows.append([]) }
            else { cell.append(c) }
        }
        rows[rows.count - 1].append(cell)
        return rows.filter { $0.contains { !$0.isEmpty } }
    }

    /// The chapter to add: only the lines the summary does not already have, as a list. "" when nothing is new.
    static func chapter(_ content: String, _ lines: [String]) -> String {
        lines.filter { !content.contains($0) }.map { "- \($0)" }.joined(separator: "\n")
    }
}

extension DataStore {
    /// Adds each book's new Kindle highlights; returns what happened in one sentence.
    func importKindle(_ books: [Kindle.Book], heading: String = "Kindle highlights") async -> String {
        let norm = { (s: String) in s.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces) }
        let same = { (h: String, t: String) in let w = Set(t.split(separator: " ")); return h.split(separator: " ").allSatisfy(w.contains) || t.replacingOccurrences(of: " ", with: "").contains(h.replacingOccurrences(of: " ", with: "")) }
        var lines = 0, updated = 0, made = 0
        for b in books {
            if let e = summaryIndex.first(where: { !norm($0.title).isEmpty && same(norm($0.title), norm(b.title)) }) {
                let body = Kindle.chapter(e.content, b.lines)
                guard !body.isEmpty, (try? await addChapter(to: e.slug, title: e.title, chapter: heading, text: body)) != nil else { continue }
                updated += 1; lines += body.components(separatedBy: "\n").count
            } else if (try? await addChapter(to: nil, title: b.title, chapter: heading, text: Kindle.chapter("", b.lines))) != nil {
                made += 1; lines += b.lines.count
            }
        }
        return lines == 0 ? "Nothing new in that file." : "Added \(lines) \(heading.lowercased()): \(updated) books updated, \(made) new."
    }
}
