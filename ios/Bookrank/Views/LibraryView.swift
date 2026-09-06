import SwiftUI

struct LibraryView: View {
    @State private var store = DataStore()
    @State private var auth = AuthStore()
    @AppStorage("spine-theme") private var theme: String = "system"
    @State private var showAllRankings = false
    @State private var showAccount = false

    private let visibleRankCount = 20

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    header
                    outFromLibrary
                    toRead
                    summaries
                    topPicks
                    allRankings
                }
                .padding(24)
                .frame(maxWidth: 680, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        theme = (theme == "dark") ? "light" : "dark"
                    } label: {
                        Image(systemName: theme == "dark" ? "moon.fill" : "sun.max.fill")
                    }
                }
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
            if auth.isSignedIn { await store.loadSummaries() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bookrank")
                .font(.system(size: 40, weight: .black))
            Text("\(store.books.count) books ranked by Goodreads rating, volume & cultural relevance")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var outFromLibrary: some View {
        // ponytail: nothing checked out = no section at all, rather than an empty-state row.
        if !store.library.loans.isEmpty {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("Out From The Library")
                Spacer()
                if let due = store.library.dueDate {
                    DueDateBadge(dueDateString: due)
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(store.library.loans) { loan in
                    loanRow(loan)
                    if loan.id != store.library.loans.last?.id { Divider() }
                }
            }
        }
        }
    }

    private func loanRow(_ loan: LibraryLoan) -> some View {
        HStack(alignment: .top, spacing: 18) {
            Text("·").foregroundStyle(.tertiary)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(loan.title).font(.subheadline.weight(.medium))
                    if let slug = loan.summarySlug, !store.summaryIndex.isEmpty {
                        NavigationLink { SummaryDetailView(slug: slug, store: store) } label: {
                            BadgeLabel(text: "Summary")
                        }
                        .buttonStyle(.plain)
                    }
                }
                Text(loan.author).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var toRead: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("To Read")
            VStack(alignment: .leading, spacing: 0) {
                ForEach(store.library.toRead) { book in
                    loanRow(book)
                    if book.id != store.library.toRead.last?.id { Divider() }
                }
            }
        }
    }

    private var topPicks: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Top Picks")
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(store.picks.enumerated()), id: \.element.id) { i, pick in
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(String(format: "%02d", i + 1))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                        (Text(pick.title).fontWeight(.medium) + Text(": \(pick.blurb)"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if pick.id != store.picks.last?.id { Divider() }
                }
            }
        }
    }

    @ViewBuilder
    private var summaries: some View {
        // ponytail: signed out and empty means no section at all, same as the loans
        // list. The account button in the toolbar is the only prompt to sign in.
        if auth.isSignedIn {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("Summaries")
                if let error = store.summaryError {
                    Text(error).font(.caption).foregroundStyle(.secondary)
                } else if store.summaryIndex.isEmpty {
                    Text("No summaries on this account yet.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(store.summaryIndex) { entry in
                        NavigationLink { SummaryDetailView(slug: entry.slug, store: store) } label: {
                            HStack(alignment: .center, spacing: 14) {
                                Thumb(url: store.cover(for: entry))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.title).font(.subheadline.weight(.medium))
                                    if let pos = entry.listen?.pos, entry.listen?.for == entry.updatedAt, pos.ch > 0 || pos.line > 0 {
                                        Text("Resume · Ch \(pos.ch + 1)").font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        if entry.id != store.summaryIndex.last?.id { Divider() }
                    }
                }
            }
        }
    }

    private var allRankings: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("All Rankings")
            let visible = showAllRankings ? store.books : Array(store.books.prefix(visibleRankCount))
            VStack(alignment: .leading, spacing: 0) {
                ForEach(visible) { book in
                    rankingRow(book)
                    if book.id != visible.last?.id { Divider() }
                }
            }
            Button(showAllRankings ? "Show less" : "Show all \(store.books.count)") {
                withAnimation { showAllRankings.toggle() }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
    }

    private func rankingRow(_ book: Book) -> some View {
        HStack(alignment: .top, spacing: 18) {
            Text(String(format: "%02d", book.rank))
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(minWidth: 22, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                Link(book.title, destination: URL(string: book.goodreadsURL) ?? URL(string: "https://goodreads.com")!)
                    .font(.subheadline.weight(.medium))
                Text(book.author).font(.caption).foregroundStyle(.secondary)
                if let rating = book.rating {
                    HStack(spacing: 6) {
                        Text(String(format: "%.2f/5", rating)).font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                        if let reviews = book.reviewCount {
                            Text(reviews).font(.caption2).foregroundStyle(.tertiary)
                        }
                        ForEach(book.badges, id: \.self) { badge in
                            BadgeLabel(text: badge)
                        }
                    }
                }
                Text(book.notes).font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption2.weight(.medium))
            .tracking(1.2)
            .foregroundStyle(.primary)
    }
}

/// ponytail: 36×52 cover or a flat placeholder; matched by title from the bundled shelf.
private struct Thumb: View {
    let url: String?
    var body: some View {
        AsyncImage(url: url.flatMap(URL.init)) { img in img.resizable().scaledToFill() } placeholder: { Color.secondary.opacity(0.15) }
            .frame(width: 36, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
