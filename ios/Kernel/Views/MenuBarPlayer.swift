#if os(macOS)
import SwiftUI

/// The Mac menu bar mini player: the book and chapter, play or pause, a line back or forward, the next chapter.
/// Only there while a book is loaded; the icon fills while it plays.
struct MenuBarPlayer: View {
    var speaker = Speaker.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if speaker.chapters.indices.contains(speaker.ch) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(speaker.chapters[speaker.ch].title).font(.kernel(.headline)).lineLimit(2)
                    Text("Chapter \(speaker.ch + 1) of \(speaker.chapters.count)").font(.kernel(.footnote)).foregroundStyle(.secondary)
                }
                HStack(spacing: 18) {
                    Button { speaker.nudge(-1) } label: { Image(systemName: "gobackward") }.help("Back a line").accessibilityLabel("Back a line")
                    Button { speaker.toggle() } label: { Image(systemName: speaker.playing && !speaker.paused ? "pause.fill" : "play.fill").font(.title2) }
                        .keyboardShortcut(.space, modifiers: []).help(speaker.playing && !speaker.paused ? "Pause" : "Play").accessibilityLabel(speaker.playing && !speaker.paused ? "Pause" : "Play")
                    Button { speaker.nudge(1) } label: { Image(systemName: "goforward") }.help("Forward a line").accessibilityLabel("Forward a line")
                    Button { speaker.skip(1) } label: { Image(systemName: "forward.end") }.help("Next chapter").accessibilityLabel("Next chapter").disabled(speaker.ch + 1 >= speaker.chapters.count)
                }
                .buttonStyle(.plain).font(.title3).foregroundStyle(.tint).frame(maxWidth: .infinity)
            } else {
                Text("Open a book in Kernel to listen here.").font(.kernel(.body)).foregroundStyle(.secondary)
            }
        }
        .padding(16).frame(width: 280).tint(amber)
    }
}

/// Screenshots: the menu bar player paused on the sample book, light and dark, written to SHOTS_DIR, then quit.
/// Run: KernelMac.app/Contents/MacOS/KernelMac -UITEST_MENUBAR_SHOT 1 (no window opens, nothing plays).
@MainActor func menuBarShots() {
    guard let url = Bundle.main.url(forResource: "sample", withExtension: "md"), let md = try? String(contentsOf: url, encoding: .utf8) else { exit(1) }
    Speaker.shared.showPausedForScreenshot(chapters: parseChapters(md))
    let dir = ProcessInfo.processInfo.environment["SHOTS_DIR"] ?? NSTemporaryDirectory()
    for (name, scheme) in [("light", ColorScheme.light), ("dark", .dark)] {
        let r = ImageRenderer(content: MenuBarPlayer().background(scheme == .dark ? Color(white: 0.16) : Color(white: 0.96)).environment(\.colorScheme, scheme))
        r.scale = 2
        if let cg = r.cgImage { try? NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: "\(dir)/menubar-\(name).png")) }
    }
    exit(0)
}
#endif
