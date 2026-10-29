import WidgetKit
import SwiftUI

/// Kernel's Home Screen widgets: Continue (small) and Continue with the week (medium). They read the feed the
/// app writes to the App Group; nothing here reaches the network.
struct FeedEntry: TimelineEntry { let date: Date; let feed: WidgetFeed }

struct FeedProvider: TimelineProvider {
    func placeholder(in context: Context) -> FeedEntry { FeedEntry(date: .now, feed: .sample) }
    func getSnapshot(in context: Context, completion: @escaping (FeedEntry) -> Void) {
        completion(FeedEntry(date: .now, feed: context.isPreview ? .sample : WidgetFeed.load()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<FeedEntry>) -> Void) {
        // The app reloads the widgets whenever the feed changes; this is only a fallback refresh.
        completion(Timeline(entries: [FeedEntry(date: .now, feed: WidgetFeed.load())], policy: .after(.now.addingTimeInterval(3600))))
    }
}

struct ContinueWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Continue", provider: FeedProvider()) { entry in
            WeekView(entry: entry)
                .widgetURL(entry.feed.url)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Continue")
        .description("The book you are partway through, and your week.")
        #if os(iOS)
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
        #else
        .supportedFamilies([.systemSmall, .systemMedium])
        #endif
    }
}

/// Medium shows the week; small keeps to Continue; the Lock Screen gets one or two plain lines.
private struct WeekView: View {
    let entry: FeedEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        let f = entry.feed
        switch family {
        case .systemMedium: WeekWidgetView(feed: f)
        #if os(iOS)
        case .accessoryInline: Text(f.title.map { "Kernel: \($0)" } ?? "Kernel")
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(f.title ?? "Kernel").font(.headline).lineLimit(1)
                Text(f.title == nil ? "Pick a book" : "Ch \(f.chapter + 1) · \(WidgetFeed.time(f.left)) left").font(.caption)
                if f.target > 0 { Text("\(f.minutes) of \(f.target) min this week").font(.caption2) }
            }
        #endif
        default: ContinueWidgetView(feed: f)
        }
    }
}

#if os(iOS)
/// The Live Activity while listening: the Lock Screen banner and the Dynamic Island.
struct ListenLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ListenAttributes.self) { ctx in
            ListenActivityView(title: ctx.attributes.title, state: ctx.state)
                .widgetURL(URL(string: "kernel://book/\(ctx.attributes.slug)"))
        } dynamicIsland: { ctx in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Image(systemName: ctx.state.playing ? "waveform" : "pause.fill").foregroundStyle(.yellow) }
                DynamicIslandExpandedRegion(.center) { Text(ctx.attributes.title).font(.headline).lineLimit(1) }
                DynamicIslandExpandedRegion(.bottom) { Text("\(ctx.state.chapter) · \(WidgetFeed.time(ctx.state.left)) left").font(.caption).foregroundStyle(.secondary).lineLimit(1) }
            } compactLeading: {
                Image(systemName: ctx.state.playing ? "waveform" : "pause.fill").foregroundStyle(.yellow)
            } compactTrailing: {
                Text(ctx.state.left >= 60 ? "\(ctx.state.left / 60)h" : "\(ctx.state.left)m").font(.caption2).monospacedDigit()
            } minimal: {
                Image(systemName: "book.fill").foregroundStyle(.yellow)
            }
            .widgetURL(URL(string: "kernel://book/\(ctx.attributes.slug)"))
        }
    }
}

#endif

/// Control Center (and the Lock Screen and Action button): one tap plays or pauses the book open in Kernel.
@available(iOS 18.0, macOS 26.0, *)
struct ListenControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.heyitsmejosh.spine.listen") {
            ControlWidgetButton(action: ToggleListeningIntent()) {
                Label(WidgetFeed.load().title ?? "Kernel", systemImage: "book")
            }
        }
        .displayName("Play or Pause Kernel")
        .description("Plays or pauses the book you are listening to.")
    }
}

@main
struct KernelWidgetBundle: WidgetBundle {
    var body: some Widget {
        ContinueWidget()
        #if os(iOS)
        ListenLiveActivity()
        #endif
        if #available(iOS 18.0, macOS 26.0, *) { ListenControl() }
    }
}
