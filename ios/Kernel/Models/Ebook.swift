import Foundation
import PDFKit
import Compression

/// An EPUB (no DRM) or PDF you own becomes a book: "# Title", then "## " per section. Same EPUB rules as epub.js;
/// a PDF uses its outline for chapters, or ten pages at a time when it has none.
/// ponytail: plain text only; images and tables are dropped.
enum Ebook {
    struct Failure: Error { let message: String }

    static func markdown(_ url: URL) throws -> (title: String, markdown: String) {
        url.pathExtension.lowercased() == "pdf" ? try pdf(url) : try epub(Data(contentsOf: url))
    }

    // MARK: PDF
    static func pdf(_ url: URL) throws -> (title: String, markdown: String) {
        guard let doc = PDFDocument(url: url), doc.pageCount > 0 else { throw Failure(message: "Could not open that PDF.") }
        let title = (doc.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? url.deletingPathExtension().lastPathComponent
        let text = { (r: Range<Int>) in r.compactMap { doc.page(at: $0)?.string }.joined(separator: "\n\n").replacingOccurrences(of: "[ \\t]+", with: " ", options: .regularExpression) }
        var parts: [(String, Range<Int>)] = []
        let marks = (0..<(doc.outlineRoot?.numberOfChildren ?? 0)).compactMap { doc.outlineRoot?.child(at: $0) }
            .compactMap { o in o.destination?.page.map { (o.label ?? "", doc.index(for: $0)) } }.sorted { $0.1 < $1.1 }
        if marks.count >= 2 {
            for (i, m) in marks.enumerated() { parts.append((m.0, m.1..<(i + 1 < marks.count ? marks[i + 1].1 : doc.pageCount))) }
        } else {
            for s in stride(from: 0, to: doc.pageCount, by: 10) { let e = min(s + 10, doc.pageCount); parts.append(("Pages \(s + 1) to \(e)", s..<e)) }
        }
        var md = "# \(title)\n"
        for (name, r) in parts where !r.isEmpty { let t = text(r).trimmingCharacters(in: .whitespacesAndNewlines); if t.count >= 200 { md += "\n## \(name)\n\n\(t)\n" } }
        guard md.contains("\n## ") else { throw Failure(message: "No text in that PDF (it may be scanned pages; use Choose page photos).") }
        return (title, md)
    }

    // MARK: EPUB
    static func epub(_ data: Data) throws -> (title: String, markdown: String) {
        let files = try unzip(data), str = { (n: String) in files[n].flatMap { String(data: $0, encoding: .utf8) } ?? "" }
        guard let opfPath = str("META-INF/container.xml").firstMatch(of: /full-path="([^"]+)"/)?.1, case let opf = str(String(opfPath)), !opf.isEmpty else { throw Failure(message: "That file is not an EPUB.") }
        let dir = opfPath.contains("/") ? String(opfPath[...opfPath.lastIndex(of: "/")!]) : ""
        var items: [String: String] = [:]
        for m in opf.matches(of: /<item\b[^>]*>/) {
            let tag = String(m.0)
            if let id = tag.firstMatch(of: /id="([^"]+)"/)?.1, let href = tag.firstMatch(of: /href="([^"]+)"/)?.1 { items[String(id)] = String(href) }
        }
        let title = text(String(opf.firstMatch(of: /<dc:title[^>]*>([\s\S]*?)<\/dc:title>/)?.1 ?? "Untitled"))
        var md = "# \(title)\n", n = 0
        for m in opf.matches(of: /<itemref\b[^>]*idref="([^"]+)"/) {
            let s = section(str(dir + (items[String(m.1)]?.removingPercentEncoding ?? "")))
            guard s.text.count >= 200 else { continue }   // covers, title pages, copyright
            n += s.title.isEmpty ? 1 : 0
            md += "\n## \(s.title.isEmpty ? "Section \(n)" : s.title)\n\n\(s.text)\n"
        }
        guard md.contains("\n## ") else { throw Failure(message: "No readable text in that EPUB (it may have DRM).") }
        return (title, md)
    }

    static func section(_ xhtml: String) -> (title: String, text: String) {
        let body = xhtml.firstMatch(of: /<body[\s\S]*<\/body>/).map { String($0.0) } ?? xhtml
        let title = text(String(body.firstMatch(of: /<h[1-3][^>]*>([\s\S]*?)<\/h[1-3]>/)?.1 ?? ""))
        let parts = body.matches(of: /<(p|li|h[4-6])[^>]*>([\s\S]*?)<\/(?:p|li|h[4-6])>/).map { m in (m.1.lowercased() == "li" ? "- " : "") + text(String(m.2)) }
            .filter { !$0.replacingOccurrences(of: "- ", with: "").isEmpty }
        return (title, parts.joined(separator: "\n\n"))
    }

    static func text(_ s: String) -> String {
        let plain = s.replacing(/<[^>]+>/, with: "")
            .replacingOccurrences(of: "&nbsp;", with: " ").replacingOccurrences(of: "&quot;", with: "\"").replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">").replacingOccurrences(of: "&amp;", with: "&")
        return plain.replacing(/\s+/, with: " ").trimmingCharacters(in: .whitespaces)
    }

    /// The files of a zip by name; stored and deflated entries only, which is all EPUBs use.
    static func unzip(_ d: Data) throws -> [String: Data] {
        let b = [UInt8](d)
        func u16(_ p: Int) -> Int { Int(b[p]) | Int(b[p + 1]) << 8 }
        func u32(_ p: Int) -> Int { u16(p) | u16(p + 2) << 16 }
        var end = b.count - 22
        while end >= 0 && u32(end) != 0x06054b50 { end -= 1 }
        guard end >= 0 else { throw Failure(message: "That file is not an EPUB.") }
        var files: [String: Data] = [:], p = u32(end + 16)
        for _ in 0..<u16(end + 10) {
            let method = u16(p + 10), size = u32(p + 20), full = u32(p + 24), nameLen = u16(p + 28), local = u32(p + 42)
            let name = String(decoding: b[(p + 46)..<(p + 46 + nameLen)], as: UTF8.self)
            let start = local + 30 + u16(local + 26) + u16(local + 28), raw = Array(b[start..<(start + size)])
            if method == 0 { files[name] = Data(raw) }
            else if method == 8 {
                var out = [UInt8](repeating: 0, count: max(full, 1))
                let n = compression_decode_buffer(&out, out.count, raw, raw.count, nil, COMPRESSION_ZLIB)   // Apple's ZLIB is raw deflate
                files[name] = Data(out.prefix(n))
            }
            p += 46 + nameLen + u16(p + 30) + u16(p + 32)
        }
        return files
    }
}

extension DataStore {
    /// A whole new book from Markdown (an imported EPUB or PDF).
    func addBook(title: String, markdown: String) async throws {
        let slug = title.lowercased().replacing(/[^a-z0-9]+/, with: "-").trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        _ = try await API.call("POST", "/rest/bookrank_summaries", json: [
            "slug": slug.isEmpty ? "untitled" : slug, "title": title, "content": markdown, "updated_at": Date().formatted(.iso8601)])
        await loadSummaries()
    }
}
