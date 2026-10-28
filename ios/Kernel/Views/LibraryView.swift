import SwiftUI

struct LibraryView: View {
    @State private var store = DataStore()
    @State private var auth = AuthStore()
    @AppStorage("spine-theme") private var theme: String = "system"
    @State private var showAddPages = false
    @State private var showAccount = false
    @State private var query = ""
    @State private var openShelves: Set<String> = ["Currently reading"]
    private static let shelfIcon = ["Currently reading": "book", "Read on Goodreads, no summary yet": "checkmark.circle", "Want to read": "bookmark"]
    @State private var showSample = false
    @State private var selected: String?   // Mac: the book in the chapters column
    @State private var chapter: Int?        // Mac: the chapter in the text column
    @AppStorage("kernel.onboarded") private var onboarded = false
    @State private var showOnboarding = false
    @State private var afterOnboarding: OnboardingChoice = .skip
    /// False while the launch splash is on screen, so the first-run pages wait for it.
    var splashDone = true
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
        .sheet(isPresented: $showAddPages) { AddPagesView(store: store) }
        .onAppear {
            if CommandLine.flag("UITEST_ACCOUNT") { showAccount = true }   // screenshots of the Account sheet
            if CommandLine.flag("UITEST_PLAYER") {   // screenshots of the player bar, silent
                store.loadSample(); speaker.showPausedForScreenshot(chapters: parseChapters(store.summaryMarkdown(for: "sample")))
            }
        }
        // First launch only, signed out. Waits for the splash, and stays out of the screenshot modes.
        .onChange(of: splashDone, initial: true) { _, done in
            if done && !onboarded && !auth.isSignedIn && !CommandLine.flag("UITEST_SNAPSHOT") && !CommandLine.flag("UITEST_ACCOUNT") { showOnboarding = true }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showOnboarding, onDismiss: runOnboardingChoice) {
            OnboardingView { choice in afterOnboarding = choice; showOnboarding = false }
        }
        #else
        .sheet(isPresented: $showOnboarding, onDismiss: runOnboardingChoice) {
            OnboardingView { choice in afterOnboarding = choice; showOnboarding = false }
        }
        #endif
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

    /// Runs once the first-run pages are gone, so the sample or sign-in opens on a clear screen.
    private func runOnboardingChoice() {
        onboarded = true
        let choice = afterOnboarding
        afterOnboarding = .skip
        switch choice {
        case .skip: break
        case .signIn: showAccount = true
        case .sample:
            guard !auth.isSignedIn else { break }   // the sample replaces the shelf; an account already has one
            store.loadSample()
            #if os(macOS)
            selected = "sample"
            #else
            showSample = true
            #endif
        }
    }

    @ToolbarContentBuilder
    private var accountButton: some ToolbarContent {
        if auth.isSignedIn {
            ToolbarItem(placement: .automatic) {
                Button("Add pages", systemImage: "plus") { showAddPages = true }
            }
        }
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
                Button("Sign in") { showAccount = true }
                    .buttonStyle(.borderedProminent).buttonBorderShape(.capsule).controlSize(.large).tint(amber).foregroundStyle(onAmber)
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
        // The book you are partway through gets a card on top; it leaves the plain rows so it shows once.
        let cont = q.isEmpty ? shown.first(where: started) : nil
        if let cont {
            #if os(macOS)
            continueCard(cont).tag(cont.slug)
            #else
            NavigationLink { SummaryDetailView(slug: cont.slug, store: store) } label: { continueCard(cont) }
                .listRowSeparator(.hidden)
            #endif
        }
        ForEach(shown.filter { $0.slug != cont?.slug }) { entry in
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
                        Image(systemName: "chevron.right").font(.kernel(.caption, weight: .semibold)).foregroundStyle(.tertiary)
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

    /// Continue: bigger cover, where you are and what is left, a gold progress line.
    private func continueCard(_ entry: SummaryEntry) -> some View {
        let chapters = parseChapters(entry.content)
        let ch = min(entry.listen?.pos.ch ?? 0, max(0, chapters.count - 1))
        let left = chapters.isEmpty ? minutes(entry.content) : minutes(chapters[ch...].map(\.text).joined())
        return HStack(spacing: 16) {
            Thumb(url: store.cover(for: entry), width: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("Continue").font(.kernel(.footnote, weight: .semibold)).foregroundStyle(amber)
                Text(entry.title).font(.kernel(.headline)).lineLimit(2)
                Text("Chapter \(ch + 1) of \(max(chapters.count, 1)) · \(duration(left)) left").font(.kernel(.footnote)).foregroundStyle(.secondary)
                ProgressView(value: Double(ch), total: Double(max(chapters.count, 1))).tint(amber).padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func summaryRow(_ entry: SummaryEntry) -> some View {
        HStack(spacing: 14) {
            Thumb(url: store.cover(for: entry))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title).font(.kernel(.body))
                Group {
                    if let pos = entry.listen?.pos, started(entry) { Text("Resume · Ch \(pos.ch + 1) · \(duration(minutes(entry.content)))") }
                    else { Text("\(duration(minutes(entry.content)))") }
                }
                .font(.kernel(.footnote)).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
