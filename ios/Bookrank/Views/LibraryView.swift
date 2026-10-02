import SwiftUI

struct LibraryView: View {
    @State private var store = DataStore()
    @State private var auth = AuthStore()
    @AppStorage("spine-theme") private var theme: String = "system"
    @State private var showAccount = false
    @State private var query = ""
    @State private var showSample = false
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
                if !store.goodreadsQueue.isEmpty {
                    Section {
                        ForEach(store.goodreadsQueue) { b in
                            HStack(spacing: 14) {
                                Thumb(url: b.cover)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(b.title).font(.body).lineLimit(2)
                                    Text(b.author).font(.footnote).foregroundStyle(.secondary)
                                }
                            }
                        }
                    } header: {
                        Text("Read on Goodreads, no summary yet (\(store.goodreadsQueue.count))")
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Search your summaries")
            .overlay { if shown.isEmpty && !q.isEmpty { ContentUnavailableView.search(text: query) } }
            .task(id: store.summaryIndex.count) { await store.loadGoodreads(auth.user?.userMetadata["goodreads"]?.stringValue) }
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
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
