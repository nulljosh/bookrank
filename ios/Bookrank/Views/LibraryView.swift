import SwiftUI

struct LibraryView: View {
    @State private var store = DataStore()
    @State private var auth = AuthStore()
    @AppStorage("spine-theme") private var theme: String = "system"
    @State private var showAccount = false
    @State private var query = ""
    @State private var openShelves: Set<String> = ["Currently reading"]
    @State private var showSample = false
    var speaker = Speaker.shared
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        NavigationStack {
            list
                .navigationDestination(isPresented: $showSample) { SummaryDetailView(slug: "sample", store: store) }
                .navigationTitle("Summaries")
                #if os(iOS)
                .navigationBarTitleDisplayMode(sizeClass == .regular ? .inline : .automatic)
                #endif
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showAccount = true
                        } label: {
                            Image(systemName: auth.isSignedIn ? "person.crop.circle.fill" : "person.crop.circle")
                        }
                        .accessibilityLabel(auth.isSignedIn ? "Account" : "Sign in")
                    }
                }
                .sheet(isPresented: $showAccount) { AccountView(auth: auth, store: store) }
        }
        // Playback follows you off the chapter: a bar along the bottom with pause and stop,
        // on every screen, for as long as something is playing or paused.
        .safeAreaInset(edge: .bottom) { if speaker.playing || speaker.paused || speaker.loading { MiniPlayer(store: store) } }
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

    @ViewBuilder
    private var list: some View {
        if !auth.isSignedIn {
            ContentUnavailableView {
                Label("Your summaries", systemImage: "books.vertical")
            } description: {
                Text("Sign in to read them chapter by chapter.")
            } actions: {
                Button("Sign in") { showAccount = true }.buttonStyle(.borderedProminent).tint(Color(red: 239 / 255, green: 160 / 255, blue: 72 / 255)).foregroundStyle(Color(red: 0.10, green: 0.07, blue: 0.03))
                Button("Try a sample chapter") {
                    store.loadSample()
                    showSample = true
                }
            }
        } else if let error = store.summaryError {
            ContentUnavailableView("Could not load", systemImage: "exclamationmark.triangle", description: Text(error))
        } else if store.summaryIndex.isEmpty {
            ContentUnavailableView("No summaries yet", systemImage: "books.vertical", description: Text("Summaries on this account show up here."))
        } else {
            // Books you are partway through come first; no group headers.
            let started = { (e: SummaryEntry) in e.listen?.for == e.updatedAt && ((e.listen?.pos.ch ?? 0) > 0 || (e.listen?.pos.line ?? 0) > 0) }
            let rows = store.summaryIndex.filter(started) + store.summaryIndex.filter { !started($0) }
            let q = query.trimmingCharacters(in: .whitespaces).lowercased()
            let shown = q.isEmpty ? rows : rows.filter { $0.title.lowercased().contains(q) || $0.content.lowercased().contains(q) }
            // The Goodreads shelves, folded so a few hundred read books do not bury the
            // summaries. Currently reading starts open; a search opens whatever it hits.
            let shelves = [("Currently reading", store.goodreadsReading), ("Read on Goodreads, no summary yet", store.goodreadsQueue), ("Want to read", store.goodreadsToRead)]
                .map { ($0.0, q.isEmpty ? $0.1 : $0.1.filter { $0.title.lowercased().contains(q) || $0.author.lowercased().contains(q) }) }
                .filter { !$0.1.isEmpty }
            List {
                ForEach(shown) { entry in
                NavigationLink { SummaryDetailView(slug: entry.slug, store: store) } label: {
                    HStack(spacing: 14) {
                        Thumb(url: store.cover(for: entry))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title).font(.body)
                            if let pos = entry.listen?.pos, started(entry) {
                                Text("Resume · Ch \(pos.ch + 1)").font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                }
                ForEach(shelves, id: \.0) { shelf in
                    let (label, books) = shelf
                    Section {
                        if openShelves.contains(label) || !q.isEmpty {
                            ForEach(books) { GoodreadsRow(book: $0) }
                        }
                    } header: {
                        Button { openShelves.formSymmetricDifference([label]) } label: {
                            HStack {
                                Text("\(label) (\(books.count))")
                                Spacer()
                                Image(systemName: "chevron.right").rotationEffect(.degrees(openShelves.contains(label) || !q.isEmpty ? 90 : 0))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Search your summaries")
            .overlay { if shown.isEmpty && shelves.isEmpty && !q.isEmpty { ContentUnavailableView.search(text: query) } }
            .task(id: store.summaryIndex.count) { await store.loadGoodreads(auth.user?.userMetadata["goodreads"]?.stringValue) }
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
    }
}

/// The bar that keeps playback reachable: chapter and book, play/pause, stop.
private struct MiniPlayer: View {
    let store: DataStore
    var speaker = Speaker.shared
    var body: some View {
        HStack(spacing: 14) {
            Button(speaker.playing && !speaker.paused ? "Pause" : "Play", systemImage: speaker.loading ? "stop.fill" : (speaker.playing && !speaker.paused ? "pause.fill" : "play.fill")) { speaker.toggle() }
                .labelStyle(.iconOnly).font(.title2).contentTransition(.symbolEffect(.replace))
            VStack(alignment: .leading, spacing: 1) {
                Text(speaker.chapters.indices.contains(speaker.ch) ? speaker.chapters[speaker.ch].title : "Listening").font(.subheadline).lineLimit(1)
                if let t = speaker.slug.flatMap({ store.summary(for: $0)?.title }) { Text(t).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
            }
            Spacer(minLength: 8)
            Button("Stop", systemImage: "xmark") { speaker.stop() }.labelStyle(.iconOnly).foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20).padding(.vertical, 10)
        .frame(maxWidth: 680)
        .frame(maxWidth: .infinity)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }
}

/// One Goodreads book: cover, title, author, and "4/5 · Aug 2026" on the right. Tapping opens it on Goodreads.
private struct GoodreadsRow: View {
    let book: DataStore.GoodreadsBook
    var body: some View {
        let row = HStack(spacing: 14) {
            Thumb(url: book.cover)
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title).font(.body).lineLimit(2)
                Text(book.author).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if let meta = book.meta { Text(meta).font(.footnote).foregroundStyle(.tertiary) }
        }
        if let url = book.url.flatMap(URL.init) { Link(destination: url) { row }.foregroundStyle(.primary) } else { row }
    }
}

/// ponytail: 36×52 cover or a flat placeholder; matched by title from the bundled shelf.
private struct Thumb: View {
    let url: String?
    var body: some View {
        AsyncImage(url: url.flatMap(URL.init)) { img in img.resizable().scaledToFill() } placeholder: { Color.secondary.opacity(0.12).overlay(Image(systemName: "book.closed").font(.footnote).foregroundStyle(.tertiary)) }
            .frame(width: 36, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .accessibilityHidden(true)   // the title beside it says everything; VoiceOver would read "image" first
    }
}
