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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Medium shows the week; small keeps to Continue.
private struct WeekView: View {
    let entry: FeedEntry
    @Environment(\.widgetFamily) private var family
    var body: some View {
        if family == .systemMedium { WeekWidgetView(feed: entry.feed) } else { ContinueWidgetView(feed: entry.feed) }
    }
}

@main
struct KernelWidgetBundle: WidgetBundle {
    var body: some Widget { ContinueWidget() }
}
