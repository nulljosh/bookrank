import Foundation

/// The parts of the player that need no state of their own: the notes split into lines, and the next chapter fetched ahead.
extension Speaker {
    // ponytail: same block rule as listen.js blocks(): paragraphs join, list items and
    // headings stand alone, rules drop. `line` is spoken, `md` is rendered.
    static func blocks(_ md: String) -> [ListenState.Line] {
        var out: [String] = []
        var open = false
        for raw in md.components(separatedBy: "\n") {
            let t = raw.trimmingCharacters(in: .whitespaces)
            if t.isEmpty || t.allSatisfy({ $0 == "-" }) { open = false; continue }
            let special = t.hasPrefix("- ") || t.hasPrefix("* ") || t.hasPrefix("#") || t.range(of: "^\\d+\\. ", options: .regularExpression) != nil
            if special || !open { out.append(t); open = !special } else { out[out.count - 1] += " " + t }
        }
        return out.map { .init(host: "A", line: plain($0), md: $0) }
    }
    static func plain(_ md: String) -> String {
        md.replacingOccurrences(of: "^([-*]|\\d+\\.) ", with: "", options: .regularExpression)
          .replacingOccurrences(of: "[#*_`>\\[\\]()]", with: " ", options: .regularExpression)
          .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
          .trimmingCharacters(in: .whitespaces)
    }

    /// On Wi-Fi, the next chapter's natural voice is fetched while this one plays and kept on the device,
    /// so a tunnel or a plane does not stop the book at the chapter break. Never on cellular or Low Data Mode.
    /// ponytail: one chapter ahead, kept with the book's other lines; the Storage screen is where they go away.
    func prefetchAudio(_ i: Int) {
        guard natural, let slug, slug != "sample", Net.shared.wifi else { return }
        let host = narrator, task = script(for: i)
        Task.detached(priority: .background) {
            guard let lines = await task.value else { return }
            try? FileManager.default.createDirectory(at: Narrator.offlineDir(slug), withIntermediateDirectories: true)
            for l in lines { guard Speaker.shared.slug == slug, Net.shared.wifi else { return }; _ = await Narrator.speak(l.line, host: host, ch: i, slug: slug) }
        }
    }
}
