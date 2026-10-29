import CoreSpotlight
import UniformTypeIdentifiers

/// Your books and highlights in Spotlight (and Siri suggestions). Rebuilt whenever the library loads; a result
/// opens its book. Kept on this device by the system, like the rest of the library cache.
enum Spotlight {
    static func index(_ books: [SummaryEntry]) {
        var items: [CSSearchableItem] = []
        for b in books where b.slug != "sample" {
            let a = CSSearchableItemAttributeSet(contentType: .text)
            a.title = b.title
            a.contentDescription = parseChapters(b.content).map(\.title).prefix(8).joined(separator: " · ")
            a.textContent = String(b.content.prefix(20000))
            items.append(CSSearchableItem(uniqueIdentifier: "book:\(b.slug)", domainIdentifier: "books", attributeSet: a))
            for m in b.listen?.marks ?? [] {
                let h = CSSearchableItemAttributeSet(contentType: .text)
                h.title = m.text; h.contentDescription = "Highlight in \(b.title)"
                items.append(CSSearchableItem(uniqueIdentifier: "mark:\(b.slug):\(m.ch):\(m.text.hashValue)", domainIdentifier: "highlights", attributeSet: h))
            }
        }
        let index = CSSearchableIndex.default()
        index.deleteAllSearchableItems { _ in index.indexSearchableItems(items) }
    }

    /// The book slug inside a tapped result's identifier ("book:<slug>" or "mark:<slug>:…").
    static func slug(from id: String) -> String? {
        let parts = id.split(separator: ":", maxSplits: 2)
        return parts.count >= 2 ? String(parts[1]) : nil
    }
}
