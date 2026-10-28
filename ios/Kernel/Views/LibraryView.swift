import SwiftUI

struct LibraryView: View {
    @State private var store = DataStore()
    @State private var auth = AuthStore()
    @AppStorage("spine-theme") private var theme: String = "system"
    @State private var showAccount = false
    @State private var query = ""
    @State private var openShelves: Set<String> = ["Currently reading"]
    private static let shelfIcon = ["Currently reading": "book", "Read on Goodreads, no summary yet": "checkmark.circle", "Want to read": "bookmark"]
    @State private var showSample = false
    @State private var selected: String?   // Mac: the book in the chapters column
    @State private var chapter: Int?        // Mac: the chapter in the text column
    var speaker = Speaker.shared
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        Group {
            #if os(macOS)
            // Mac: the books down the side, the chapters and their text fill the rest of the window.
            NavigationSplitView {
                list
                    .navigationSplitViewColumnWidth(min: 280, ideal: 340, max: 520)
                    .navigationTitle("Summaries")
                    .toolbar { accountButton }
            } content: {
                if let slug = selected {
                    SummaryDetailView(slug: slug, store: store, chapter: $chapter).id(slug)
                        .navigationSplitViewColumnWidth(min: 280, ideal: 360, max: 560)
                } else {
                    ContentUnavailableView("Pick a book", systemImage: "books.vertical", description: Text("Its chapters open here."))
                        .navigationTitle("Summaries")
                }
            } detail: {
                if let slug = selected, let ch = chapter {
                    ChapterView(index: ch).id("\(slug)/\(ch)")
                } else {
                    ContentUnavailableView("Pick a chapter", systemImage: "text.book.closed", description: Text("Read it here, or press play to listen."))
                }
            }
            .onChange(of: selected) { _, _ in chapter = nil }
            #else
            NavigationStack {
                list
                    .navigationDestination(isPresented: $showSample) { SummaryDetailView(slug: "sample", store: store) }
                    .navigationTitle("Summaries")
                    .navigationBarTitleDisplayMode(sizeClass == .regular ? .inline : .automatic)
                    .toolbar { accountButton }
            }
            #endif
        }
        .sheet(isPresented: $showAccount) { AccountView(auth: auth, store: store) }
        .onAppear { if CommandLine.flag("UITEST_ACCOUNT") { showAccount = true } }   // screenshots of the Account sheet
        // Playback follows you off the chapter: a bar along the bottom with pause and stop,
        // on every screen, for as long as something is playing or paused.
        .safeAreaInset(edge: .bottom) { if speaker.playing || speaker.paused || speaker.loading { MiniPlayer(store: store) } }
        .animation(.snappy, value: speaker.playing || speaker.paused || speaker.loading)
        #if os(macOS)
        .frame(minWidth: 1040, minHeight: 600)
        #endif
        .preferredColorScheme(theme == "dark" ? .dark : theme == "light" ? .light : nil)
        // Fires once the stored session has been read back, and again on sign-in or
        // sign-out, so the shelf follows the account without a manual refresh.
        .task(id: auth.user?.id) {
            if auth.isSignedIn {
                await store.loadSummaries()
                await Nudge.schedule(store.summaryIndex)
                #if os(iOS)
                WatchSync.shared.activate()
                WatchSync.shared.push(store.summaryIndex)
                #endif
            }
        }
    }

    private var accountButton: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button { showAccount = true } label: { Image(systemName: auth.isSignedIn ? "person.crop.circle.fill" : "person.crop.circle") }
                .accessibilityLabel(auth.isSignedIn ? "Account" : "Sign in")
        }
    }

    /// A book you are partway through.
    private func started(_ e: SummaryEntry) -> Bool { e.listen?.for == e.updatedAt && ((e.listen?.pos.ch ?? 0) > 0 || (e.listen?.pos.line ?? 0) > 0) }

    @ViewBuilder
    private var list: some View {
        if !auth.isSignedIn {
            ContentUnavailableView {
                Label("Your summaries", systemImage: "books.vertical")
            } description: {
                Text("Sign in to read them chapter by chapter.")
            } actions: {
                Button("Sign in") { showAccount = true }.buttonStyle(.borderedProminent).tint(amber).foregroundStyle(Color(red: 0.10, green: 0.07, blue: 0.03))
                Button("Try a sample chapter") {
                    store.loadSample()
                    #if os(macOS)
                    selected = "sample"
                    #else
                    showSample = true
                    #endif
                }
            }
        } else if let error = store.summaryError {
            ContentUnavailableView("Could not load", systemImage: "exclamationmark.triangle", description: Text(error))
        } else if store.summaryIndex.isEmpty {
            ContentUnavailableView("No summaries yet", systemImage: "books.vertical", description: Text("Summaries on this account show up here."))
        } else {
            // Books you are partway through come first; no group headers.
            let rows = store.summaryIndex.filter(started) + store.summaryIndex.filter { !started($0) }
            let q = query.trimmingCharacters(in: .whitespaces).lowercased()
            let shown = q.isEmpty ? rows : rows.filter { $0.title.lowercased().contains(q) || $0.content.lowercased().contains(q) }
            // The Goodreads shelves, folded so a few hundred read books do not bury the
            // summaries. Currently reading starts open; a search opens whatever it hits.
            let shelves = [("Currently reading", store.goodreadsReading), ("Read on Goodreads, no summary yet", store.goodreadsQueue), ("Want to read", store.goodreadsToRead)]
                .map { ($0.0, q.isEmpty ? $0.1 : $0.1.filter { $0.title.lowercased().contains(q) || $0.author.lowercased().contains(q) }) }
                .filter { !$0.1.isEmpty }
            Group {
                #if os(macOS)
                List(selection: $selected) { listRows(shown, shelves, q) }.listStyle(.sidebar)
                #else
                List { listRows(shown, shelves, q) }.frame(maxWidth: 680).frame(maxWidth: .infinity).listStyle(.plain)
                #endif
            }
            .searchable(text: $query, prompt: "Search your summaries")
            .overlay { if shown.isEmpty && shelves.isEmpty && !q.isEmpty { ContentUnavailableView.search(text: query) } }
            .task(id: store.summaryIndex.count) { await store.loadGoodreads(auth.user?.userMetadata["goodreads"]?.stringValue) }
        }
    }

    @ViewBuilder
    private func listRows(_ shown: [SummaryEntry], _ shelves: [(String, [DataStore.GoodreadsBook])], _ q: String) -> some View {
        ForEach(shown) { entry in
            #if os(macOS)
            summaryRow(entry).tag(entry.slug)
            #else
            NavigationLink { SummaryDetailView(slug: entry.slug, store: store) } label: { summaryRow(entry) }
            #endif
        }
        ForEach(shelves, id: \.0) { shelf in
            let (label, books) = shelf
            let open = openShelves.contains(label) || !q.isEmpty
            Section {
                if open { ForEach(books) { GoodreadsRow(book: $0) } }
            } header: {
                Button { withAnimation(.snappy) { openShelves.formSymmetricDifference([label]) } } label: {
                    HStack(spacing: 8) {
                        Image(systemName: Self.shelfIcon[label] ?? "books.vertical").foregroundStyle(.secondary)
                        Text(label)
                        Text("\(books.count)").monospacedDigit().foregroundStyle(.tertiary)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                            .rotationEffect(.degrees(open ? 90 : 0))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(label), \(books.count) books")
                .accessibilityHint(open ? "Hides the shelf" : "Shows the shelf")
            }
        }
    }

    private func summaryRow(_ entry: SummaryEntry) -> some View {
        HStack(spacing: 14) {
            Thumb(url: store.cover(for: entry))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title).font(.body)
                if let pos = entry.listen?.pos, started(entry) {
                    Text("Resume · Ch \(pos.ch + 1)").font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

let amber = Color(red: 239 / 255, green: 160 / 255, blue: 72 / 255)

/// The bar that keeps playback reachable: a progress line, chapter and book, play/pause, stop.
/// Mac: ⌘⇧P plays or pauses, ⌘. stops.
private struct MiniPlayer: View {
    let store: DataStore
    var speaker = Speaker.shared
    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: min(max(speaker.progress, 0), 1)).progressViewStyle(.linear).tint(amber).accessibilityHidden(true)
            HStack(spacing: 12) {
                Button("Previous chapter", systemImage: "backward.end.fill") { speaker.skip(-1) }.labelStyle(.iconOnly).foregroundStyle(.secondary)
                Button(speaker.playing && !speaker.paused ? "Pause" : "Play", systemImage: speaker.loading ? "stop.fill" : (speaker.playing && !speaker.paused ? "pause.fill" : "play.fill")) { speaker.toggle() }
                    .labelStyle(.iconOnly).font(.title2).contentTransition(.symbolEffect(.replace))
                    .keyboardShortcut("p", modifiers: [.command, .shift])
                Button("Next chapter", systemImage: "forward.end.fill") { speaker.skip(1) }.labelStyle(.iconOnly).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(speaker.chapters.indices.contains(speaker.ch) ? speaker.chapters[speaker.ch].title : "Listening").font(.subheadline).lineLimit(1)
                    // The book and which voice is speaking; on the Mac, hovering explains a fallback.
                    Text([speaker.slug.flatMap { store.summary(for: $0)?.title }, speaker.voice.isEmpty ? nil : speaker.voice].compactMap { $0 }.joined(separator: " · "))
                        .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        .help(speaker.status)
                }
                .padding(.leading, 4)
                Spacer(minLength: 8)
                // Speed, as a menu so the bar stays one line. ⌘⇧P pauses, ⌘. stops.
                Menu {
                    Picker("Speed", selection: Binding(get: { speaker.rate }, set: { speaker.rate = $0 })) {
                        ForEach([Float(0.75), 1, 1.25, 1.5, 1.75, 2], id: \.self) { Text("\($0, specifier: "%g")×").tag($0) }
                    }
                    .pickerStyle(.inline)
                    Toggle("Natural voice", isOn: Binding(get: { speaker.natural }, set: { speaker.natural = $0 }))
                } label: {
                    Text("\(speaker.rate, specifier: "%g")×").font(.footnote.weight(.medium)).monospacedDigit()
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
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Now playing")
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

/// One Goodreads book: cover, title, author, your stars and the month on the right. Tapping opens it on Goodreads.
private struct GoodreadsRow: View {
    let book: DataStore.GoodreadsBook
    var body: some View {
        let row = HStack(spacing: 14) {
            Thumb(url: book.cover)
            VStack(alignment: .leading, spacing: 3) {
                Text(book.title).font(.body).lineLimit(2)
                Text(book.author).font(.footnote).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                if let r = book.rating { Stars(r) }
                if let when = book.when { Text(when).font(.caption).foregroundStyle(.tertiary) }
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
        .font(.caption2).foregroundStyle(amber)
        .accessibilityElement(children: .ignore).accessibilityLabel("\(n.formatted()) of 5 stars")
    }
}

/// ponytail: a 36×52 cover (or wider, same shape) or a flat placeholder; matched by title from the bundled shelf.
struct Thumb: View {
    let url: String?
    var width: CGFloat = 36
    var body: some View {
        AsyncImage(url: url.flatMap(URL.init)) { img in img.resizable().scaledToFill() } placeholder: { Color.secondary.opacity(0.12).overlay(Image(systemName: "book.closed").font(.footnote).foregroundStyle(.tertiary)) }
            .frame(width: width, height: width * 52 / 36)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .accessibilityHidden(true)   // the title beside it says everything; VoiceOver would read "image" first
    }
}
