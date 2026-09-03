import SwiftUI

/// The #1 ranked book plus the next few, and a sense of the shelf's size. Trims the
/// iOS `LibraryView` header + top of "All Rankings" down to what fits a watch face.
struct ShelfView: View {
    let store: BookStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Bookrank")
                    .font(.headline)
                Text("\(store.books.count) books ranked")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let top = store.books.first {
                    Divider().padding(.vertical, 2)
                    Text("#1 RANKED")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text(top.title)
                        .font(.subheadline.weight(.semibold))
                    Text(top.author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let rating = top.rating {
                        Text(String(format: "%.2f/5", rating))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                let rest = store.books.dropFirst().prefix(6)
                if !rest.isEmpty {
                    Divider().padding(.vertical, 2)
                    ForEach(Array(rest)) { book in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(String(format: "%02d", book.rank))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Text(book.title)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}
