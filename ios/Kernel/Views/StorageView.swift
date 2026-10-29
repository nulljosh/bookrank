import SwiftUI

/// What Kernel keeps on this device and how big it is: each book's voice lines, the meaning-search index, the
/// library copy. Remove a book's voice, or clear the index (it is rebuilt the next time you search by meaning).
struct StorageView: View {
    let store: DataStore
    var speaker = Speaker.shared
    @Environment(\.dismiss) private var dismiss
    @State private var refresh = 0

    private static let support = URL.applicationSupportDirectory
    private static func size(_ url: URL) -> Int64 {
        guard let e = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else {
            return Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
        }
        return e.compactMap { ($0 as? URL).flatMap { try? $0.resourceValues(forKeys: [.fileSizeKey]).fileSize } }.reduce(0) { $0 + Int64($1) }
    }
    private func bytes(_ n: Int64) -> String { n == 0 ? String(localized: "None") : n.formatted(.byteCount(style: .file)) }

    var body: some View {
        let _ = refresh
        let voices = ((try? FileManager.default.contentsOfDirectory(atPath: Self.support.appending(path: "voice").path)) ?? []).sorted()
            .map { slug in (slug, store.summary(for: slug)?.title ?? slug, Self.size(Narrator.offlineDir(slug)), speaker.offline.contains(slug)) }
            .filter { $0.2 > 0 }
        let meaning = Self.size(Self.support.appending(path: "meaning")), library = Self.size(Self.support.appending(path: "summaries.json"))
        NavigationStack {
            List {
                Section {
                    if voices.isEmpty { Text("No narration kept yet. Download a book, or listen on Wi-Fi.").foregroundStyle(.secondary) }
                    ForEach(voices, id: \.0) { slug, title, size, full in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(title).lineLimit(1)
                                Text(full ? "Downloaded" : "Chapters heard or fetched ahead").font(.kernel(.footnote)).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(bytes(size)).monospacedDigit().foregroundStyle(.secondary)
                        }
                        .swipeActions { Button("Remove", role: .destructive) { speaker.removeDownload(slug); refresh += 1 } }
                        .contextMenu { Button("Remove", systemImage: "trash", role: .destructive) { speaker.removeDownload(slug); refresh += 1 } }
                    }
                } header: { Text("Narration") } footer: { Text("Swipe or right-click a book to remove its voice. It plays again from the internet.") }
                Section("Other") {
                    LabeledContent("Search by meaning", value: bytes(meaning))
                    LabeledContent("Your library, for offline", value: bytes(library))
                    if meaning > 0 {
                        Button("Clear the search index", role: .destructive) { try? FileManager.default.removeItem(at: Self.support.appending(path: "meaning")); refresh += 1 }
                    }
                }
            }
            .navigationTitle("Storage")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        #if os(macOS)
        .frame(minWidth: 480, minHeight: 480)
        #endif
    }
}
