import Foundation

extension DataStore {
    /// Everything you have in one zip: a Markdown file per book with its chapter notes, your highlights and notes
    /// together, every row as JSON (positions, collections, share links), and your Goodreads shelves if this device
    /// has them. Same contents as the web's export. Nil if the zip could not be made.
    func writeExport() -> URL? {
        let fm = FileManager.default, tmp = fm.temporaryDirectory
        let day = Date.now.formatted(.iso8601.year().month().day())
        let dir = tmp.appending(path: "Kernel \(day)", directoryHint: .isDirectory)
        try? fm.removeItem(at: dir); try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        for e in summaryIndex {
            let notes = (e.notes ?? [:]).sorted { (Int($0.key) ?? 0) < (Int($1.key) ?? 0) }
                .map { "## Note, chapter \((Int($0.key) ?? 0) + 1)\n\n\($0.value)" }.joined(separator: "\n\n")
            try? "# \(e.title)\n\n\(e.content)\n\(notes.isEmpty ? "" : "\n\(notes)\n")".write(to: dir.appending(path: "\(e.slug).md"), atomically: true, encoding: .utf8)
        }
        try? exportMarkdown(summaryIndex).write(to: dir.appending(path: "Highlights.md"), atomically: true, encoding: .utf8)
        let enc = JSONEncoder(); enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? enc.encode(summaryIndex).write(to: dir.appending(path: "kernel.json"))
        if let g = Goodreads.shared.data { try? enc.encode(g.shelves).write(to: dir.appending(path: "goodreads.json")) }
        // ponytail: reading a folder "for uploading" is the system's own zipper; no zip library needed.
        var out: URL?
        NSFileCoordinator().coordinate(readingItemAt: dir, options: .forUploading, error: nil) { zipped in
            let dest = tmp.appending(path: "Kernel \(day).zip")
            try? fm.removeItem(at: dest)
            if (try? fm.copyItem(at: zipped, to: dest)) != nil { out = dest }
        }
        return out
    }
}
