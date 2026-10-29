import SwiftUI
import Charts

/// Your reading in numbers, under the library: the same counts as readingStats in goal.js, plus, with Goodreads
/// signed in, the books you finished each year and your average rating.
struct ReadingStats: View {
    let store: DataStore

    var body: some View {
        let books = store.summaryIndex.filter { $0.slug != "sample" }
        if !books.isEmpty {
            let mins = books.map { minutes($0.content) }.reduce(0, +)
            let tiles: [(String, String)] = [
                ("\(books.count)", books.count == 1 ? "book" : "books"),
                ("\(books.map { parseChapters($0.content).count }.reduce(0, +))", "chapters"),
                (mins >= 60 ? "\(Int((Double(mins) / 60).rounded())) hr" : "\(mins) min", "to listen"),
                ("\(books.map { $0.listen?.marks?.count ?? 0 }.reduce(0, +))", "highlights"),
                ("\(books.map { $0.notes?.count ?? 0 }.reduce(0, +))", "notes")]
            Section("Your reading") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                    ForEach(tiles, id: \.1) { v, l in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(v).font(.kernel(.title3, weight: .semibold)).monospacedDigit()
                            Text(l).font(.kernel(.footnote)).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(12)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .listRowSeparator(.hidden)
                goodreads
            }
        }
    }

    /// Books finished per year (the last five) and the average of your ratings, from the Goodreads read shelf.
    @ViewBuilder private var goodreads: some View {
        let read = store.goodreadsRead
        let years = Dictionary(grouping: read.compactMap { $0.readAt?.prefix(4) }, by: { String($0) }).mapValues(\.count)
        let shown = years.keys.sorted().suffix(5)
        let rated = read.compactMap(\.rating)
        if !shown.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Finished on Goodreads, by year").font(.kernel(.footnote)).foregroundStyle(.secondary)
                Chart(shown, id: \.self) { y in
                    BarMark(x: .value("Year", y), y: .value("Books", years[y] ?? 0)).foregroundStyle(amber)
                        .annotation(position: .top) { Text("\(years[y] ?? 0)").font(.kernel(.caption)).foregroundStyle(.secondary) }
                }
                .chartYAxis(.hidden).frame(height: 120)
                if !rated.isEmpty {
                    Text("Average rating \((rated.reduce(0, +) / Double(rated.count)).formatted(.number.precision(.fractionLength(1)))) of 5, from \(rated.count) rated books")
                        .font(.kernel(.footnote)).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
