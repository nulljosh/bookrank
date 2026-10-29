import Foundation
import WidgetKit

extension WidgetFeed {
    /// The app's side: what the widgets should show now, from the player and the week, saved to the App Group.
    /// Called whenever listening is saved (through Goal.remind) and when the app opens; widgets reload only on change.
    @MainActor static func publish() {
        let s = Speaker.shared, g = Goal.shared
        var f = WidgetFeed(minutes: g.minutes, target: g.target, days: g.days.sorted())
        if CommandLine.flag("UITEST_SNAPSHOT") { f = .sample }
        else if let slug = s.slug, slug != "sample", s.chapters.indices.contains(s.ch) {
            f.title = DataStore.shared.summary(for: slug)?.title
            f.slug = slug; f.chapter = s.ch; f.chapters = s.chapters.count
            f.left = listening(s.chapters[s.ch...].map(\.text).joined())
        } else if let e = DataStore.lastStarted() {   // nothing loaded yet: the last book you were partway through
            let chs = parseChapters(e.content), ch = min(e.listen?.pos.ch ?? 0, max(chs.count - 1, 0))
            f.title = e.title; f.slug = e.slug; f.chapter = ch; f.chapters = chs.count
            f.left = chs.isEmpty ? 0 : listening(chs[ch...].map(\.text).joined())
        }
        if f.save() { WidgetCenter.shared.reloadAllTimelines() }
    }
}

/// The listening time of some text (the app's `minutes`, which the feed's own `minutes` field would shadow).
private func listening(_ text: String) -> Int { minutes(text) }

#if os(iOS)
import SwiftUI

/// The widgets at their Home Screen sizes, drawn in the app for screenshot runs (UITEST_WIDGETS), since a test
/// cannot place a widget on the Home Screen.
struct WidgetGallery: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.55), Color(red: 0.55, green: 0.42, blue: 0.25)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()   // a plain wallpaper
            VStack(spacing: 24) {
                // Lock Screen: the rectangular widget, and the Live Activity while listening.
                VStack(alignment: .leading, spacing: 1) {
                    Text("The Optimist").font(.headline)
                    Text("Ch 4 · \(WidgetFeed.time(261)) left").font(.caption)
                    Text("38 of 60 min this week").font(.caption2)
                }
                .foregroundStyle(.white).frame(width: 170, alignment: .leading)
                ListenActivityView(title: "The Optimist", state: .init(chapter: "Chapter 3: \"Where Are You?\"", index: 3, total: 14, playing: true, left: 261))
                    .foregroundStyle(.white).frame(width: 364).background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                tile(ContinueWidgetView(feed: .sample), width: 170)
                tile(WeekWidgetView(feed: .sample), width: 364)
            }
        }
    }
    private func tile(_ v: some View, width: CGFloat) -> some View {
        v.padding(16).frame(width: width, height: 170).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
#endif
