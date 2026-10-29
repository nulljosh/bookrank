#if os(iOS)
import ActivityKit
import Foundation

/// Starts, updates and ends the listening Live Activity from the player's state. KernelApp calls it whenever the
/// player plays, pauses, stops or changes chapter. Screenshot and player test runs stay out of it.
@MainActor enum LiveListen {
    private static var activity: Activity<ListenAttributes>?

    static func update() {
        guard !CommandLine.flag("UITEST_SNAPSHOT"), !CommandLine.flag("UITEST_PLAYER"), ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let s = Speaker.shared
        guard let slug = s.slug, slug != "sample", s.playing || s.paused, s.chapters.indices.contains(s.ch) else {
            if let a = activity { Task { await a.end(nil, dismissalPolicy: .immediate) }; activity = nil }
            return
        }
        let state = ListenAttributes.ContentState(chapter: s.chapters[s.ch].title, index: s.ch, total: s.chapters.count,
                                                  playing: s.playing && !s.paused, left: minutes(s.chapters[s.ch...].map(\.text).joined()))
        let content = ActivityContent(state: state, staleDate: nil)
        if let a = activity, a.attributes.slug == slug { Task { await a.update(content) }; return }
        if let a = activity { Task { await a.end(nil, dismissalPolicy: .immediate) } }
        let title = DataStore.shared.summary(for: slug)?.title ?? "Kernel"
        activity = try? Activity.request(attributes: ListenAttributes(title: title, slug: slug), content: content)
    }
}
#endif
