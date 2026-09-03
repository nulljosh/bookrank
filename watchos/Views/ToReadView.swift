import SwiftUI

/// `Library.toRead`, books flagged for later. `loans` is deliberately not shown here:
/// bookrank/CLAUDE.md's "no library checkout tracking" rule retired that feature, and
/// `library.json` always ships `loans: []`, so there is nothing real to port.
struct ToReadView: View {
    let store: BookStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("To Read")
                    .font(.headline)
                if store.library.toRead.isEmpty {
                    Text("Nothing queued.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.library.toRead) { loan in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(loan.title)
                                .font(.caption.weight(.medium))
                            Text(loan.author)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}
