import SwiftUI

struct LibraryView: View {
    @State private var store = DataStore()
    @AppStorage("spine-theme") private var theme: String = "system"
    @State private var showAllRankings = false

    private let visibleRankCount = 20

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    header
                    outFromLibrary
                    topPicks
                    summaries
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
            }
        }
        .preferredColorScheme(theme == "dark" ? .dark : theme == "light" ? .light : nil)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Spine")
                .font(.custom("Georgia", size: 40))
                .italic()
                .fontWeight(.black)
            Text("\(store.books.count) books ranked by Goodreads rating, volume & cultural relevance")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var outFromLibrary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("Out From The Library")
                Spacer()
                DueDateBadge(dueDateString: store.library.dueDate)
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(store.library.loans) { loan in
                    loanRow(loan)
                    if loan.id != store.library.loans.last?.id { Divider() }
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
                    if let slug = loan.summarySlug {
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

    private var summaries: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Summaries")
            VStack(alignment: .leading, spacing: 0) {
                ForEach(store.summaryIndex) { entry in
                    NavigationLink { SummaryDetailView(slug: entry.slug, store: store) } label: {
                        HStack(alignment: .top, spacing: 18) {
                            Text("·").foregroundStyle(.tertiary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.title).font(.subheadline.weight(.medium))
                                Text(entry.author).font(.caption).foregroundStyle(.secondary)
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
                HStack(spacing: 6) {
                    Text(String(format: "%.2f/5", book.rating)).font(.caption2.weight(.medium)).foregroundStyle(.secondary)
                    Text(book.reviewCount).font(.caption2).foregroundStyle(.tertiary)
                    ForEach(book.badges, id: \.self) { badge in
                        BadgeLabel(text: badge)
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
