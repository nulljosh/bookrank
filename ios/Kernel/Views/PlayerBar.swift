import SwiftUI

// Shared pieces of the library: the player bar, Goodreads rows, covers, durations and Kernel gold.

/// Listening time at about 180 words a minute (~1,100 characters), never under one. Same rule as listen.js `minutes`.
/// utf8.count is constant time on native strings, so rows can call it on every render.
func minutes(_ text: String) -> Int { max(1, Int((Double(text.utf8.count) / 1100).rounded())) }

/// "45 min", "4 hr 21 min", "2 hr".
func duration(_ m: Int) -> String { m < 60 ? "\(m) min" : m % 60 == 0 ? "\(m / 60) hr" : "\(m / 60) hr \(m % 60) min" }

/// Kernel gold (brand/BRAND.md): #a56200 in light, #f5b83d in dark. `onAmber` is the text on it.
let amber = Color("AccentColor")
let onAmber = Color("OnAccent")

/// The bar that keeps playback reachable: a progress line, chapter and book, play/pause, stop.
/// Mac: ⌘⇧P plays or pauses, ⌘. stops.
struct MiniPlayer: View {
    let store: DataStore
    var speaker = Speaker.shared
    @State private var full = false
    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: min(max(speaker.progress, 0), 1)).progressViewStyle(.linear).tint(amber).accessibilityHidden(true)
                .padding(.horizontal, 20).padding(.top, 8)
            HStack(spacing: 12) {
                // A line back or forward; whole chapters are in the book's list and on the lock screen.
                Button("Back a line", systemImage: "gobackward") { speaker.nudge(-1) }.labelStyle(.iconOnly).foregroundStyle(.secondary)
                Button(speaker.playing && !speaker.paused ? "Pause" : "Play", systemImage: speaker.loading ? "stop.fill" : (speaker.playing && !speaker.paused ? "pause.fill" : "play.fill")) { speaker.toggle() }
                    .labelStyle(.iconOnly).font(.kernel(.title2)).contentTransition(.symbolEffect(.replace))
                    .keyboardShortcut("p", modifiers: [.command, .shift])
                Button("Forward a line", systemImage: "goforward") { speaker.nudge(1) }.labelStyle(.iconOnly).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(speaker.chapters.indices.contains(speaker.ch) ? speaker.chapters[speaker.ch].title : "Listening").font(.kernel(.subheadline)).lineLimit(1)
                    // The book and which voice is speaking; on the Mac, hovering explains a fallback.
                    Text([speaker.slug.flatMap { store.summary(for: $0)?.title }, speaker.voice.isEmpty ? nil : speaker.voice].compactMap { $0 }.joined(separator: " · "))
                        .font(.kernel(.caption)).foregroundStyle(.secondary).lineLimit(1)
                        .help(speaker.status)
                }
                .padding(.leading, 4)
                .contentShape(Rectangle())
                .onTapGesture { full = true }   // the title opens the full player
                .accessibilityAddTraits(.isButton).accessibilityHint("Opens the full player").accessibilityIdentifier("nowPlayingTitle")
                Spacer(minLength: 8)
                // Speed, as a menu so the bar stays one line. ⌘⇧P pauses, ⌘. stops.
                Menu {
                    Picker("Speed", selection: Binding(get: { speaker.rate }, set: { speaker.rate = $0 })) {
                        ForEach([Float(0.75), 1, 1.25, 1.5, 1.75, 2], id: \.self) { Text("\($0, specifier: "%g")×").tag($0) }
                    }
                    .pickerStyle(.inline)
                    Picker("Sleep timer", selection: Binding(get: { speaker.sleep }, set: { speaker.sleep = $0 })) {
                        Text("Off").tag(0)
                        ForEach([15, 30, 45, 60], id: \.self) { Text("\($0) min").tag($0) }
                        Text("End of chapter").tag(-1)
                    }
                    .pickerStyle(.menu)
                    Toggle("Natural voice", isOn: Binding(get: { speaker.natural }, set: { speaker.natural = $0 }))
                } label: {
                    HStack(spacing: 4) {
                        if speaker.sleep != 0 { Image(systemName: "moon.fill").foregroundStyle(amber).accessibilityLabel("Sleep timer on") }
                        Text("\(speaker.rate, specifier: "%g")×").monospacedDigit()
                    }
                    .font(.kernel(.footnote, weight: .medium))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }
                .menuStyle(.button).buttonStyle(.plain).fixedSize()
                .accessibilityLabel("Speed, \(speaker.rate.formatted()) times")
                Button("Stop", systemImage: "xmark") { speaker.stop() }.labelStyle(.iconOnly).foregroundStyle(.secondary)
                    .keyboardShortcut(".", modifiers: .command)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20).padding(.vertical, 10)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .barGlass()
        .sheet(isPresented: $full) { NowPlaying(store: store) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Now playing")
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

/// One Goodreads book: cover, title, author, your stars and the month on the right. Tapping opens it on Goodreads.
struct GoodreadsRow: View {
    let book: DataStore.GoodreadsBook
    var store: DataStore? = nil   // set: the row offers Summarize this book (Add pages with the title filled in)
    @State private var summarizing = false
    var body: some View {
        link
            .contextMenu { if store != nil { Button("Summarize this book", systemImage: "doc.badge.plus") { summarizing = true } } }
            .swipeActions { if store != nil { Button("Summarize", systemImage: "doc.badge.plus") { summarizing = true }.tint(amber) } }
            .sheet(isPresented: $summarizing) { if let store { AddPagesView(store: store, title: book.title) } }
    }
    @ViewBuilder private var link: some View {
        let row = HStack(spacing: 14) {
            Thumb(url: book.cover)
            VStack(alignment: .leading, spacing: 3) {
                Text(book.title).font(.kernel(.body)).lineLimit(2)
                Text(book.author).font(.kernel(.footnote)).foregroundStyle(.secondary).lineLimit(1)
                // Currently reading: the latest Goodreads progress. Read: the start of your review.
                if let p = book.progress {
                    ProgressView(value: Double(p), total: 100).tint(amber).padding(.top, 2)
                    Text(book.page.flatMap { pg in book.of.map { "Page \(pg) of \($0)" } } ?? "\(p)% done")
                        .font(.kernel(.caption)).foregroundStyle(.secondary).monospacedDigit()
                }
                if let r = book.review { Text(r).font(.kernel(.footnote)).foregroundStyle(.secondary).lineLimit(2).padding(.top, 2) }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                if let r = book.rating { Stars(r) }
                if let when = book.when { Text(when).font(.kernel(.caption)).foregroundStyle(.secondary) }
            }
        }
        .padding(.vertical, 2)
        if let url = book.url.flatMap(URL.init) { Link(destination: url) { row }.foregroundStyle(.primary) } else { row }
    }
}

/// Five small stars, the rating filled, halves included. VoiceOver reads "3.5 of 5 stars".
private struct Stars: View {
    let n: Double
    init(_ n: Double) { self.n = n }
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { i in Image(systemName: n >= Double(i) + 1 ? "star.fill" : n >= Double(i) + 0.5 ? "star.leadinghalf.filled" : "star") }
        }
        .font(.kernel(.caption2)).foregroundStyle(amber)
        .accessibilityElement(children: .ignore).accessibilityLabel("\(n.formatted()) of 5 stars")
    }
}

/// ponytail: a 36×52 cover (or wider, same shape) or a flat placeholder; matched by title from the bundled shelf.
struct Thumb: View {
    let url: String?
    var width: CGFloat = 36
    var body: some View {
        AsyncImage(url: url.flatMap(URL.init)) { img in img.resizable().scaledToFill() } placeholder: { Color.secondary.opacity(0.12).overlay(Image(systemName: "book.closed").font(.kernel(.footnote)).foregroundStyle(.tertiary)) }
            .frame(width: width, height: width * 52 / 36)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .accessibilityHidden(true)   // the title beside it says everything; VoiceOver would read "image" first
    }
}

extension View {
    /// The player floats as Liquid Glass on iOS 26 and macOS 26; earlier systems keep the plain bar.
    @ViewBuilder func barGlass() -> some View {
        if #available(iOS 26, macOS 26, *) {
            glassEffect(.regular, in: .rect(cornerRadius: 28)).padding(.horizontal, 12).padding(.bottom, 4)
        } else {
            background(.bar).overlay(alignment: .top) { Divider() }
        }
    }
}
