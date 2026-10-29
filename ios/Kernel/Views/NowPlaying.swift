import SwiftUI

/// The full player, opened from the mini player: the cover big, the book and chapter, where you
/// are in the chapter with the time left, the controls, and the chapters to jump between.
struct NowPlaying: View {
    let store: DataStore
    var speaker = Speaker.shared
    @Environment(\.dismiss) private var dismiss
    @State private var scrub: Double?
    @State private var goodreads: String?   // the book whose Goodreads page is open

    var body: some View {
        let entry = speaker.slug.flatMap { store.summary(for: $0) }
        let cover = entry.flatMap { store.cover(for: $0) }
        let on = speaker.playing && !speaker.paused
        let left = speaker.lines.indices.contains(speaker.line)
            ? minutes(speaker.lines[speaker.line...].map(\.line).joined(separator: " ")) : 0
        NavigationStack {
            VStack(spacing: 20) {
                Spacer(minLength: 8)
                Thumb(url: cover, width: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.3), radius: 24, y: 14)
                    .scaleEffect(on ? 1 : 0.92)
                    .animation(.spring(response: 0.45, dampingFraction: 0.8), value: on)
                VStack(spacing: 4) {
                    Text(speaker.chapters.indices.contains(speaker.ch) ? speaker.chapters[speaker.ch].title : "")
                        .font(.kernel(.title3, weight: .bold)).multilineTextAlignment(.center).lineLimit(2)
                    Text(entry?.title ?? "").font(.kernel(.subheadline)).foregroundStyle(.secondary).lineLimit(1)
                }
                VStack(spacing: 6) {
                    // Scrub by line: dragging picks the line, letting go plays from there. Only a finished drag
                    // plays; the slider setting its own value on layout must never start audio.
                    Slider(value: Binding(get: { scrub ?? Double(speaker.line) }, set: { scrub = $0 }),
                           in: 0...Double(max(speaker.lines.count - 1, 1))) { editing in
                        if !editing, let s = scrub { speaker.go(to: speaker.ch, line: Int(s.rounded())); scrub = nil }
                    }
                        .tint(amber)
                        .disabled(speaker.lines.count < 2)
                    HStack {
                        Text("Line \(min(speaker.line + 1, max(speaker.lines.count, 1))) of \(max(speaker.lines.count, 1))")
                        Spacer()
                        Text("\(duration(left)) left")
                    }
                    .font(.kernel(.caption)).foregroundStyle(.secondary).monospacedDigit()
                }
                HStack(spacing: 44) {
                    Button("Back a line", systemImage: "gobackward") { speaker.nudge(-1) }
                    Button(on ? "Pause" : "Play", systemImage: on ? "pause.circle.fill" : "play.circle.fill") { speaker.toggle() }
                        .font(.system(size: 64)).foregroundStyle(amber)
                        .contentTransition(.symbolEffect(.replace))
                    Button("Forward a line", systemImage: "goforward") { speaker.nudge(1) }
                }
                .labelStyle(.iconOnly).font(.kernel(.title2)).buttonStyle(.plain)
                HStack {
                    Menu {
                        Picker("Speed", selection: Binding(get: { speaker.rate }, set: { speaker.rate = $0 })) {
                            ForEach([Float(0.75), 1, 1.25, 1.5, 1.75, 2], id: \.self) { Text("\($0, specifier: "%g")×").tag($0) }
                        }
                    } label: { Text("\(speaker.rate, specifier: "%g")×").monospacedDigit() }
                    Spacer()
                    Menu {
                        Picker("Sleep timer", selection: Binding(get: { speaker.sleep }, set: { speaker.sleep = $0 })) {
                            Text("Off").tag(0)
                            ForEach([15, 30, 45, 60], id: \.self) { Text("\($0) min").tag($0) }
                            Text("End of chapter").tag(-1)
                        }
                        if let note = speaker.sleepNote { Text(note) }
                    } label: { Image(systemName: speaker.sleep == 0 ? "moon" : "moon.fill").accessibilityLabel("Sleep timer") }
                    Spacer()
                    Menu {
                        ForEach(speaker.chapters.indices, id: \.self) { i in
                            Button { speaker.go(to: i) } label: {
                                if i == speaker.ch { Label(speaker.chapters[i].title, systemImage: "speaker.wave.2") } else { Text(speaker.chapters[i].title) }
                            }
                        }
                        if Goodreads.shared.data != nil, let t = entry?.title {   // signed in to Goodreads on this device
                            Divider()
                            Button("Mark Read on Goodreads", systemImage: "checkmark.circle") { goodreads = t }
                        }
                    } label: { Image(systemName: "list.bullet").accessibilityLabel("Chapters") }
                }
                .font(.kernel(.headline)).foregroundStyle(.secondary).menuStyle(.button).buttonStyle(.plain)
                .padding(.horizontal, 24)
                .sheet(isPresented: Binding(get: { goodreads != nil }, set: { if !$0 { goodreads = nil } })) { GoodreadsBookPage(title: goodreads ?? "") }
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                // The cover's colour, washed over the sheet.
                AsyncImage(url: cover.flatMap(URL.init)) { $0.resizable().scaledToFill() } placeholder: { Color.clear }
                    .frame(width: 420, height: 420).clipped().blur(radius: 70).opacity(0.4)
                    .mask(RadialGradient(colors: [.black, .clear], center: .center, startRadius: 40, endRadius: 210))
                    .accessibilityHidden(true)
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "chevron.down") { dismiss() } } }
        }
        #if os(macOS)
        .frame(width: 460, height: 680)
        #endif
    }
}
