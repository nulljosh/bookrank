import SwiftUI
import Charts
import UniformTypeIdentifiers

/// Your reading in numbers, under the library: the same counts as readingStats in goal.js, plus, with Goodreads
/// signed in, the books you finished each year and your average rating.
struct ReadingStats: View {
    let store: DataStore
    @State private var storage = false

    var body: some View {
        let books = store.summaryIndex.filter { $0.slug != "sample" }
        if !books.isEmpty {
            let mins = books.map { minutes($0.content) }.reduce(0, +)
            let tiles: [(String, String)] = [
                ("\(books.count)", books.count == 1 ? "book" : "books"),
                ("\(books.map { parseChapters($0.content).count }.reduce(0, +))", "chapters"),
                (mins >= 60 ? "\(Int((Double(mins) / 60).rounded())) hr" : "\(mins) min", "to listen"),
                ("\(books.map { $0.listen?.marks?.count ?? 0 }.reduce(0, +))", "highlights"),
                ("\(books.map { $0.notes?.keys.filter { Int($0) != nil }.count ?? 0 }.reduce(0, +))", "notes")]
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
                yearShare(books, mins)
                Button("Storage on this device", systemImage: "internaldrive") { storage = true }.font(.kernel(.footnote))
                    .sheet(isPresented: $storage) { StorageView(store: store) }
            }
        }
    }

    /// Your year as a card to share: books finished on Goodreads and added here this year, highlights, hours, one highlight.
    private func yearShare(_ books: [SummaryEntry], _ mins: Int) -> some View {
        let year = Calendar.current.component(.year, from: .now), y = String(year)
        let finished = store.goodreadsRead.filter { $0.readAt?.hasPrefix(y) == true }.count
        let added = books.filter { $0.createdAt?.hasPrefix(y) == true }.count
        let marks = books.flatMap { e in (e.listen?.marks ?? []).map { (e, $0) } }
        let top = dailyFive(marks, text: { $0.1.text }, day: y, n: 1).first
        var rows: [(String, String)] = finished > 0 ? [("\(finished)", finished == 1 ? "book finished" : "books finished")] : []
        rows += [("\(added)", added == 1 ? "book summarized" : "books summarized"), ("\(marks.count)", "highlights"), (mins >= 60 ? "\(Int((Double(mins) / 60).rounded())) hr" : "\(mins) min", "to listen")]
        let card = YearCard(year: year, rows: Array(rows.prefix(4)), quote: top?.1.text, book: top?.0.title ?? "")
        return ShareLink(item: card, preview: SharePreview("Kernel \(y)")) { Label("Share your \(y)", systemImage: "square.and.arrow.up") }
            .font(.kernel(.footnote))
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

/// Your year on Kernel gold: the year, up to four numbers, one highlight. Same card as yearCard in card.js.
struct YearCard: Transferable {
    let year: Int, rows: [(String, String)], quote: String?, book: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { c in try await c.png() }
    }

    @MainActor func png() throws -> Data {
        let r = ImageRenderer(content: face); r.scale = 1
        let data = NSMutableData()
        guard let cg = r.cgImage, let d = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { throw CocoaError(.fileWriteUnknown) }
        CGImageDestinationAddImage(d, cg, nil); CGImageDestinationFinalize(d)
        return data as Data
    }

    @MainActor var face: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: "\(year)").font(.custom("KernelSans-Bold", fixedSize: 120))
            Text("in books").font(.custom("KernelSans-Medium", fixedSize: 40)).padding(.bottom, 56)
            ForEach(rows, id: \.1) { v, l in
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(v).font(.custom("KernelSans-Bold", fixedSize: 60)).frame(width: 220, alignment: .leading)
                    Text(l).font(.custom("KernelSans-Medium", fixedSize: 34))
                }
                .padding(.bottom, 14)
            }
            Spacer()
            if let quote {
                Text("“\(quote)”").font(.custom("KernelSans-Semibold", fixedSize: 34)).lineLimit(3).padding(.bottom, 10)
                Text(book).font(.custom("KernelSans-Medium", fixedSize: 28)).lineLimit(1)
            }
            HStack { Spacer(); Text("Kernel.").font(.custom("KernelSans-Bold", fixedSize: 34)) }.padding(.top, 40)
        }
        .foregroundStyle(Color(red: 0x1d / 255, green: 0x1d / 255, blue: 0x1f / 255))
        .padding(80)
        .frame(width: 1080, height: 1080, alignment: .topLeading)
        .background(Color(red: 0xf5 / 255, green: 0xb8 / 255, blue: 0x3d / 255))
    }
}
