import AppIntents

/// Shortcuts and Siri: add a summary from any text, play or pause the book you have open, skip to the next chapter.
/// The listening ones act on the book loaded in the app; with none loaded they say so instead of guessing.

struct AddSummaryIntent: AppIntent {
    static let title: LocalizedStringResource = "Add a summary"
    static let description = IntentDescription("Saves text as a new book in Kernel.")
    @Parameter(title: "Title") var bookTitle: String
    @Parameter(title: "Text", inputOptions: String.IntentInputOptions(multiline: true)) var text: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines), name = bookTitle.trimmingCharacters(in: .whitespaces)
        guard !body.isEmpty, !name.isEmpty else { return .result(dialog: "Give it a title and some text.") }
        let slug = name.lowercased().replacing(/[^a-z0-9]+/, with: "-").trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        do {
            _ = try await API.call("POST", "/rest/bookrank_summaries", json: ["slug": slug.isEmpty ? "untitled" : slug, "title": name,
                                                                           "content": "## Summary\n\n\(body)\n", "updated_at": Date().formatted(.iso8601)])
        } catch { return .result(dialog: "Sign in to Kernel first, then try again.") }
        return .result(dialog: "Saved \(name) to Kernel.")
    }
}

struct PlayPauseIntent: AppIntent {
    static let title: LocalizedStringResource = "Play or pause"
    static let description = IntentDescription("Plays or pauses the book open in Kernel.")

    @MainActor func perform() async throws -> some IntentResult & ProvidesDialog {
        let s = Speaker.shared
        guard s.slug != nil, !s.chapters.isEmpty else { return .result(dialog: "Open a book in Kernel first.") }
        s.toggle()
        return .result(dialog: s.paused || !s.playing ? "Paused." : "Playing \(s.chapters[s.ch].title).")
    }
}

struct NextChapterIntent: AppIntent {
    static let title: LocalizedStringResource = "Next chapter"
    static let description = IntentDescription("Skips to the next chapter of the book open in Kernel.")

    @MainActor func perform() async throws -> some IntentResult & ProvidesDialog {
        let s = Speaker.shared
        guard s.slug != nil, s.ch + 1 < s.chapters.count else { return .result(dialog: s.slug == nil ? "Open a book in Kernel first." : "That was the last chapter.") }
        s.skip(1)
        return .result(dialog: "Playing \(s.chapters[s.ch].title).")
    }
}

struct KernelShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: PlayPauseIntent(), phrases: ["Play or pause \(.applicationName)", "Pause \(.applicationName)"], shortTitle: "Play or pause", systemImageName: "playpause")
        AppShortcut(intent: NextChapterIntent(), phrases: ["Next chapter in \(.applicationName)", "Skip the chapter in \(.applicationName)"], shortTitle: "Next chapter", systemImageName: "forward.end")
        AppShortcut(intent: AddSummaryIntent(), phrases: ["Add a summary to \(.applicationName)"], shortTitle: "Add a summary", systemImageName: "doc.badge.plus")
    }
}
