import SwiftUI

/// What the Home Screen widgets show, written by the app into the shared App Group and read by the widget
/// extension: the book you are partway through and the week's listening. Built into both targets.
struct WidgetFeed: Codable, Equatable {
    var title: String? = nil, slug: String? = nil, chapter: Int = 0, chapters: Int = 0, left: Int = 0
    var minutes: Int = 0, target: Int = 0, days: [Int] = []

    #if os(macOS)
    static let group = "QMM486NPYC.com.heyitsmejosh.spine"   // a Mac App Group carries the team id
    #else
    static let group = "group.com.heyitsmejosh.spine"
    #endif
    static let key = "kernel.widget"
    static var defaults: UserDefaults? { UserDefaults(suiteName: group) }

    static func load() -> WidgetFeed {
        guard let d = defaults?.data(forKey: key), let f = try? JSONDecoder().decode(WidgetFeed.self, from: d) else { return WidgetFeed() }
        return f
    }
    /// True when it changed, so the app reloads the widgets only then.
    @discardableResult func save() -> Bool {
        guard self != Self.load(), let d = try? JSONEncoder().encode(self) else { return false }
        Self.defaults?.set(d, forKey: Self.key)
        return true
    }
    /// Sample shown in the widget gallery and in screenshot runs.
    static let sample = WidgetFeed(title: "The Optimist", slug: "the-optimist", chapter: 3, chapters: 14, left: 261, minutes: 38, target: 60, days: [0, 1, 2])

    /// "45 min", "4 hr 21 min": the apps' duration, for the widgets and the Live Activity.
    static func time(_ m: Int) -> String { m < 60 ? "\(m) min" : m % 60 == 0 ? "\(m / 60) hr" : "\(m / 60) hr \(m % 60) min" }

    var url: URL { URL(string: slug.map { "kernel://book/\($0)" } ?? "kernel://library")! }
}

private let gold = Color(red: 0.647, green: 0.384, blue: 0.0)
private let goldDark = Color(red: 0.961, green: 0.722, blue: 0.239)

/// "Continue": the book you are partway through, its chapter and the time left. Tap opens it.
struct ContinueWidgetView: View {
    let feed: WidgetFeed
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(feed.title == nil ? "Kernel" : "Continue").font(.caption.weight(.semibold)).foregroundStyle(scheme == .dark ? goldDark : gold)
            Text(feed.title ?? "Pick a book to start").font(.headline).lineLimit(3).minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            if feed.title != nil {
                Text("Chapter \(feed.chapter + 1) of \(feed.chapters)").font(.caption).foregroundStyle(.secondary)
                Text("\(WidgetFeed.time(feed.left)) left").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// The week as a ring of minutes against the goal, and seven dots for the days you listened.
struct WeekWidgetView: View {
    let feed: WidgetFeed
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let tint = scheme == .dark ? goldDark : gold
        HStack(spacing: 16) {
            ContinueWidgetView(feed: feed)
            VStack(spacing: 8) {
                ZStack {
                    Circle().stroke(.quaternary, lineWidth: 8)
                    Circle().trim(from: 0, to: feed.target > 0 ? min(1, Double(feed.minutes) / Double(feed.target)) : 0)
                        .stroke(tint, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(feed.minutes)").font(.title3.weight(.bold)).monospacedDigit()
                        Text(feed.target > 0 ? "of \(feed.target) min" : "min").font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 84, height: 84)
                HStack(spacing: 5) {
                    ForEach(0..<7, id: \.self) { d in Circle().fill(feed.days.contains(d) ? tint : Color.secondary.opacity(0.25)).frame(width: 7, height: 7) }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Listened on \(feed.days.count) days this week")
            }
        }
    }
}
