import SwiftUI

/// The Listen menu: every listening shortcut in one place, so the menu bar doubles as the keyboard map.
/// The same keys work from the iPad's keyboard (hold ⌘ to see them).
struct ListenCommands: Commands {
    @Binding var palette: Bool
    var speaker = Speaker.shared

    var body: some Commands {
        CommandMenu("Listen") {
            Button("Find a Book or Action…") { palette = true }.keyboardShortcut("k", modifiers: .command)
            Divider()
            Button(speaker.playing && !speaker.paused ? "Pause" : "Play") { speaker.toggle() }.keyboardShortcut("p", modifiers: [.command, .shift])
            Button("Back a Line") { speaker.nudge(-1) }.keyboardShortcut(.leftArrow, modifiers: [.command, .option])
            Button("Forward a Line") { speaker.nudge(1) }.keyboardShortcut(.rightArrow, modifiers: [.command, .option])
            Button("Previous Chapter") { speaker.skip(-1) }.keyboardShortcut("[", modifiers: .command)
            Button("Next Chapter") { speaker.skip(1) }.keyboardShortcut("]", modifiers: .command)
            Button("Stop") { speaker.stop() }.keyboardShortcut(".", modifiers: .command)
        }
    }
}

/// ⌘K: type to find a book or a listening action; Return runs the first match.
struct CommandPalette: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    var speaker = Speaker.shared

    private struct Item: Identifiable { let id: String; let title: String; let detail: String; let icon: String; let run: () -> Void }

    private var items: [Item] {
        let actions = [
            Item(id: "play", title: speaker.playing && !speaker.paused ? "Pause" : "Play", detail: "⇧⌘P", icon: "playpause") { speaker.toggle() },
            Item(id: "next", title: "Next chapter", detail: "⌘]", icon: "forward.end") { speaker.skip(1) },
            Item(id: "prev", title: "Previous chapter", detail: "⌘[", icon: "backward.end") { speaker.skip(-1) },
            Item(id: "stop", title: "Stop", detail: "⌘.", icon: "stop") { speaker.stop() }]
        let books = DataStore.shelf().map { e in Item(id: e.slug, title: e.title, detail: "Open", icon: "book.closed") { NoteTap.shared.slug = e.slug } }
        let q = query.trimmingCharacters(in: .whitespaces)
        let all = (speaker.slug == nil ? [] : actions) + books
        return q.isEmpty ? all : all.filter { $0.title.localizedCaseInsensitiveContains(q) }
    }

    var body: some View {
        let shown = items
        VStack(spacing: 0) {
            TextField("Find a book or action", text: $query)
                .textFieldStyle(.plain).font(.kernel(.title3)).padding(14)
                .onSubmit { if let f = shown.first { f.run(); dismiss() } }
            Divider()
            List(shown) { i in
                Button { i.run(); dismiss() } label: {
                    HStack { Label(i.title, systemImage: i.icon).lineLimit(1); Spacer(); Text(i.detail).foregroundStyle(.secondary).font(.kernel(.footnote)) }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
        #if os(macOS)
        .frame(width: 520, height: 360)
        #else
        .presentationDetents([.medium, .large])
        #endif
    }
}
