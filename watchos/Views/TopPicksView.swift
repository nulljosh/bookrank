import SwiftUI

/// `picks.json`, the same curated list the iOS "Top Picks" section renders.
struct TopPicksView: View {
    let store: BookStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("Top Picks")
                    .font(.headline)
                ForEach(store.picks) { pick in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(pick.title)
                            .font(.caption.weight(.medium))
                        Text(pick.blurb)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}
