import SwiftUI

struct LibraryView: View {
    @State private var store = DataStore.shared
    @Environment(\.openWindow) private var openWindow
    @State private var auth = AuthStore()
    @AppStorage("spine-theme") private var theme: String = "system"
    @State private var showAddPages = false
    @State private var openSlug: String?
    @State private var showAccount = false
    @State private var query = ""
    @State private var meaning: [Meaning.Hit] = []
    @AppStorage("kernel.sort") private var sort = "recent"   // recent, title, progress, short; same keys as the web
    @AppStorage("kernel.show") private var show = "all"      // all, started, new
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
                    .toolbar { accountButton }.highlights(store)
            } content: {
                if let slug = selected {
                    SummaryDetailView(slug: slug, store: store, chapter: $chapter, find: query).id(slug)
                        .navigationSplitViewColumnWidth(min: 280, ideal: 360, max: 560)
                } else {
                    ContentUnavailableView("Pick a book", systemImage: "books.vertical", description: Text("Its chapters open here."))
                        .navigationTitle("Summaries")
                }
            } detail: {
                if let slug = selected, let ch = chapter {
                    ChapterView(index: ch, store: store).id("\(slug)/\(ch)")
                } else {
                    ContentUnavailableView("Pick a chapter", systemImage: "text.book.closed", description: Text("Read it here, or press play to listen."))
                }
            }
            .onChange(of: selected) { _, _ in chapter = nil }
            #else
            if sizeClass == .regular {
                // iPad: the books down the side, a picked book (and its chapters) in the detail column.
                // ponytail: two columns, not three; the chapter pushes inside the book column.
                NavigationSplitView {
                    iosList.navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 460)
                } detail: {
                    NavigationStack {
                        ContentUnavailableView("Pick a book", systemImage: "books.vertical", description: Text("Its chapters open here."))
                    }
                }
            } else {
                NavigationStack { iosList }
            }
            #endif
        }
        .sheet(isPresented: $showAccount) { AccountView(auth: auth, store: store) }
        .task(id: NoteTap.shared.slug) {   // a tapped reminder: open its book
            guard let s = NoteTap.shared.slug else { return }
            NoteTap.shared.slug = nil
            #if os(macOS)
            selected = s
            #else
            openSlug = s
            #endif
        }
        .sheet(isPresented: $showAddPages) { AddPagesView(store: store) }
        .onAppear {
            if CommandLine.flag("UITEST_ACCOUNT") { showAccount = true }   // screenshots of the Account sheet
            if CommandLine.flag("UITEST_PLAYER") {   // screenshots of the player bar, silent
                store.loadSample(); speaker.showPausedForScreenshot(chapters: parseChapters(store.summaryMarkdown(for: "sample")))
            }
            #if os(macOS)
            // Mac store shots: `-UITEST_OPEN slug`, `-UITEST_CHAPTER n`.
            if let open = UserDefaults.standard.string(forKey: "UITEST_OPEN") {
                NSApp.windows.first?.setFrame(NSRect(x: 40, y: 40, width: 1440, height: 900), display: true)
                selected = open
                let ch = UserDefaults.standard.string(forKey: "UITEST_CHAPTER").flatMap { Int($0) }   // launch arguments arrive as strings
                Task { try? await Task.sleep(for: .milliseconds(600)); chapter = ch }   // after onChange(of: selected) clears it
            }
            #endif
        }
        // First launch, signed out, after the splash; never in screenshot modes.
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
        case .goodreads: Task { await store.loadGoodreads(nil) }
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
        if store.summaryIndex.count > 1 {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Picker("Sort", selection: $sort) {
                        Text("Recently edited").tag("recent"); Text("Title").tag("title"); Text("Progress").tag("progress"); Text("Shortest first").tag("short")
                    }
                    Picker("Show", selection: $show) {
                        Text("All books").tag("all"); Text("In progress").tag("started"); Text("Not started").tag("new"); Text("Finished").tag("finished")
                        ForEach(Topics.shelf(store.summaryIndex.map(\.title)), id: \.self) { Text(LocalizedStringKey($0)).tag("topic:" + $0) }
                    }
                } label: { Image(systemName: "line.3.horizontal.decrease") }
                .accessibilityLabel("Sort and filter")
            }
        }
        #if os(iOS)
        // iPhone: Settings (your account) sits in a bottom bar, search at the top (#86).
        if sizeClass == .compact {
            ToolbarItem(placement: .bottomBar) {
                Button { showAccount = true } label: { Label("Settings", systemImage: "gearshape").labelStyle(.titleAndIcon) }
            }
        } else { accountItem }
        #else
        accountItem
        #endif
    }

    private var accountItem: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Button { showAccount = true } label: { Image(systemName: auth.isSignedIn ? "person.crop.circle.fill" : "person.crop.circle") }
                .accessibilityLabel(auth.isSignedIn ? "Account" : "Sign in")
        }
    }

    #if os(iOS)
    private var iosList: some View {
        list
            .navigationDestination(isPresented: $showSample) { SummaryDetailView(slug: "sample", store: store) }
            .navigationDestination(item: $openSlug) { SummaryDetailView(slug: $0, store: store) }
            .navigationTitle("Summaries")
            .navigationBarTitleDisplayMode(sizeClass == .regular ? .inline : .automatic)
            .toolbar { accountButton }.highlights(store)
    }
    #endif

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
        } else if store.summaryError != nil {
            LoadFailed { await store.loadSummaries() }
        } else if store.summaryIndex.isEmpty {
            ContentUnavailableView("No summaries yet", systemImage: "books.vertical", description: Text("Summaries on this account show up here."))
        } else {
            // Books you are partway through come first; no group headers.
            let rows = store.summaryIndex.filter { show == "all" || (Topics.keep(show, $0) ?? ((show == "started") == started($0))) }.sorted(by: sort, started: started)
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
            #if os(iOS)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search your summaries")   // at the top (#86)
            #else
            .searchable(text: $query, prompt: "Search your summaries")
            #endif
            .overlay { if shown.isEmpty && shelves.isEmpty && meaning.isEmpty && !q.isEmpty { ContentUnavailableView.search(text: query) } }
            .task(id: q) {   // search by meaning once typing stops, on the device
                meaning = []
                guard q.count >= 4, (try? await Task.sleep(for: .milliseconds(500))) != nil else { return }
                meaning = await Meaning.shared.search(q, in: store.summaryIndex)
            }
            .task(id: store.summaryIndex.count) {
                let id = auth.user?.userMetadata["goodreads"]?.stringValue
                await store.loadGoodreads(id)
                // Signed in to Goodreads: refresh the shelves on open when the last sync is over an hour old.
                if let at = Goodreads.shared.data?.at, at.timeIntervalSinceNow < -3600 || CommandLine.flag("GOODREADS_SYNC"), await Goodreads.shared.sync() { await store.loadGoodreads(id) }
            }
        }
    }

    @ViewBuilder
    private func listRows(_ shown: [SummaryEntry], _ shelves: [(String, [DataStore.GoodreadsBook])], _ q: String) -> some View {
        // The book you are partway through gets a card on top; it leaves the plain rows so it shows once.
        let cont = q.isEmpty ? shown.first(where: started) : nil
        if Goal.shared.target > 0 && q.isEmpty { GoalRow().listRowSeparator(.hidden) }
        if let cont {
            #if os(macOS)
            ContinueCard(entry: cont, store: store).tag(cont.slug)
            #else
            NavigationLink { SummaryDetailView(slug: cont.slug, store: store) } label: { ContinueCard(entry: cont, store: store) }
                .listRowSeparator(.hidden)
            #endif
        }
        if q.isEmpty { TodaysFive(store: store) }
        // Your collections, A to Z, then the books in none. A search shows one plain list.
        let plain = shown.filter { $0.slug != cont?.slug }
        let names = q.isEmpty ? store.collections.filter { n in plain.contains { $0.collection == n } } : []
        ForEach(names, id: \.self) { name in
            Section(name) { ForEach(plain.filter { $0.collection == name }) { bookLink($0) } }
        }
        let rest = plain.filter { names.isEmpty || $0.collection == nil }
        if names.isEmpty { ForEach(rest) { bookLink($0) } }
        else if !rest.isEmpty { Section("Library") { ForEach(rest) { bookLink($0) } } }
        if !q.isEmpty { MeaningResults(hits: meaning, store: store) }
        ForEach(shelves, id: \.0) { shelf in
            let (label, books) = shelf
            let open = openShelves.contains(label) || !q.isEmpty
            Section {
                if open { ForEach(books) { GoodreadsRow(book: $0, store: store) } }
            } header: {
                Button { withAnimation(.snappy) { openShelves.formSymmetricDifference([label]) } } label: {
                    HStack(spacing: 8) {
                        Image(systemName: Self.shelfIcon[label] ?? "books.vertical").foregroundStyle(.secondary)
                        Text(label)
                        Text("\(books.count)").monospacedDigit().foregroundStyle(.secondary)
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
        if q.isEmpty { ReadingStats(store: store) }
    }

    @ViewBuilder
    private func bookLink(_ entry: SummaryEntry) -> some View {
        #if os(macOS)
        summaryRow(entry).tag(entry.slug).contextMenu { Button("Open in New Window") { openWindow(id: "book", value: entry.slug) } }
        #else
        NavigationLink { SummaryDetailView(slug: entry.slug, store: store, find: query) } label: { summaryRow(entry) }
        #endif
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
                // Where a search matched inside the book: chapter and the line, cut around the words.
                if let f = findLine(entry.content, query) {
                    Text("Ch \(f.ch + 1) · \(snippet(f.text, query))").font(.kernel(.footnote)).foregroundStyle(.secondary).lineLimit(2)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
