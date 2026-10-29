import SwiftUI

struct LibraryView: View {
    @State private var store = DataStore()
    @State private var auth = AuthStore()
    @AppStorage("spine-theme") private var theme: String = "system"
    @State private var showAddPages = false
    @State private var openSlug: String?
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
            if sizeClass == .regular {
                // iPad: the books down the side, a picked book (and its chapters) in the detail column.
                // ponytail: two columns, not the Mac's three; the chapter pushes inside the book column.
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
            // Mac store screenshots: a 1440x900 window opened on a book (`-UITEST_OPEN slug`) and chapter (`-UITEST_CHAPTER n`).
            if let open = UserDefaults.standard.string(forKey: "UITEST_OPEN") {
                NSApp.windows.first?.setFrame(NSRect(x: 40, y: 40, width: 1440, height: 900), display: true)
                selected = open
                let ch = UserDefaults.standard.string(forKey: "UITEST_CHAPTER").flatMap { Int($0) }   // launch arguments arrive as strings
                Task { try? await Task.sleep(for: .milliseconds(600)); chapter = ch }   // after onChange(of: selected) clears it
            }
            #endif
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

    #if os(iOS)
    private var iosList: some View {
        list
            .navigationDestination(isPresented: $showSample) { SummaryDetailView(slug: "sample", store: store) }
            .navigationDestination(item: $openSlug) { SummaryDetailView(slug: $0, store: store) }
            .navigationTitle("Summaries")
            .navigationBarTitleDisplayMode(sizeClass == .regular ? .inline : .automatic)
            .toolbar { accountButton }
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
        if Goal.shared.target > 0 && q.isEmpty { goalRow.listRowSeparator(.hidden) }
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
    }

    /// The weekly goal: a gold ring and the minutes so far.
    private var goalRow: some View {
        let g = Goal.shared
        let f = min(1, Double(g.minutes) / Double(max(g.target, 1)))
        return HStack(spacing: 14) {
            ZStack {
                Circle().inset(by: 2.5).stroke(amber.opacity(0.2), lineWidth: 5)
                Circle().inset(by: 2.5).trim(from: 0, to: f).stroke(amber, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90))
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(g.met ? "Weekly goal met" : g.streak > 1 ? "\(g.streak)-day streak" : "This week").font(.kernel(.footnote, weight: .semibold)).foregroundStyle(amber)
                Text("\(g.minutes) of \(g.target) min").font(.kernel(.headline)).monospacedDigit()
            }
            Spacer(minLength: 8)
            // The week as seven dots, the way Books shows it: gold where you listened, a ring on today.
            let cal = Calendar.current
            let names = cal.veryShortStandaloneWeekdaySymbols
            let today = cal.dateComponents([.day], from: Goal.week(), to: cal.startOfDay(for: .now)).day ?? 0
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: 4) {
                        Text(names[(cal.firstWeekday - 1 + i) % 7]).font(.kernel(.caption2)).foregroundStyle(.secondary)
                        Circle().fill(g.days.contains(i) ? amber : amber.opacity(0.15)).frame(width: 9, height: 9)
                            .overlay { if i == today { Circle().strokeBorder(amber, lineWidth: 1.5).frame(width: 15, height: 15) } }
                            .frame(width: 15, height: 15)
                    }
                }
            }
            .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
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
