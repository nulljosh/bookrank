import AppIntents

/// Play or pause Kernel from Control Center or the Action button. An audio playback intent, so the system runs it
/// in the app's own process even though the control lives in the widget extension; the extension only names it.
struct ToggleListeningIntent: AudioPlaybackIntent {
    static let title: LocalizedStringResource = "Play or Pause Kernel"
    static let description = IntentDescription("Plays or pauses the book open in Kernel.")

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        await MainActor.run { if Speaker.shared.slug != nil, !Speaker.shared.chapters.isEmpty { Speaker.shared.toggle() } }
        #endif
        return .result()
    }
}
