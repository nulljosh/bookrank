import ActivityKit
import SwiftUI

/// The Live Activity while Kernel plays: the book, the chapter, playing or paused, and the time left, on the
/// Lock Screen and in the Dynamic Island. The app starts, updates and ends it (LiveListen); the widget draws it.
struct ListenAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var chapter: String, index: Int, total: Int, playing: Bool, left: Int
    }
    var title: String
    var slug: String
}

private let goldDark = Color(red: 0.961, green: 0.722, blue: 0.239)

struct ListenActivityView: View {
    let title: String
    let state: ListenAttributes.ContentState
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state.playing ? "waveform" : "pause.fill")
                .font(.title2).foregroundStyle(goldDark).frame(width: 36)
                .accessibilityLabel(state.playing ? "Playing" : "Paused")
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).lineLimit(1)
                Text(state.chapter).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                Text("Chapter \(state.index + 1) of \(state.total) · \(WidgetFeed.time(state.left)) left").font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
    }
}
