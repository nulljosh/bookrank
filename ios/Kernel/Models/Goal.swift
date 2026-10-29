import Foundation
import Observation
import UserNotifications

/// Weekly listening goal: minutes listened this week on this device, against a goal set in Account.
/// The Speaker adds five seconds for every five it plays. When a goal is set and the week is behind,
/// one reminder waits for the week's last evening at 18:00 saying how much is left; meeting the goal takes it away.
/// ponytail: counted per device, not synced; sync it on the row's listen JSON if people listen on two.
@Observable
final class Goal {
    static let shared = Goal()
    private let d = UserDefaults.standard
    private static let reminder = "kernel.goal.reminder"

    /// Minutes per week, 0 = off.
    var target: Int { didSet { d.set(target, forKey: "kernel.goal"); Task { await remind() } } }
    private(set) var seconds: Double
    /// Days of this week with any listening, 0 = the week's first day.
    private(set) var days: Set<Int> = []
    /// Days in a row with some listening, up to today or yesterday.
    var streak: Int {
        let last = d.double(forKey: "kernel.goal.lastDay")
        let today = Calendar.current.startOfDay(for: .now).timeIntervalSince1970
        return today - last <= 86400 ? d.integer(forKey: "kernel.goal.streak") : 0
    }

    private init() {
        target = d.integer(forKey: "kernel.goal")
        seconds = d.double(forKey: "kernel.goal.secs")
        days = Set(d.array(forKey: "kernel.goal.days") as? [Int] ?? [])
        roll()
        if CommandLine.flag("UITEST_SNAPSHOT") && target > 0 {   // screenshots: a week partway there, three days in a row
            seconds = 38 * 60; days = [0, 1, 2]
            d.set(3, forKey: "kernel.goal.streak"); d.set(Calendar.current.startOfDay(for: .now).timeIntervalSince1970, forKey: "kernel.goal.lastDay")
        }
    }

    /// A new week starts from zero.
    private func roll() {
        let w = Self.week().timeIntervalSince1970
        if d.double(forKey: "kernel.goal.week") != w { d.set(w, forKey: "kernel.goal.week"); seconds = 0; days = []; d.set(0.0, forKey: "kernel.goal.secs"); d.set([Int](), forKey: "kernel.goal.days") }
    }

    var minutes: Int { Int(seconds / 60) }
    var met: Bool { target > 0 && minutes >= target }

    static func week(_ now: Date = .now) -> Date { Calendar.current.dateInterval(of: .weekOfYear, for: now)?.start ?? now }

    func add(_ s: Double) {
        roll()
        let wasMet = met
        seconds += s
        d.set(seconds, forKey: "kernel.goal.secs")
        let cal = Calendar.current, today = cal.startOfDay(for: .now)
        if let i = cal.dateComponents([.day], from: Self.week(), to: today).day, days.insert(i).inserted { d.set(Array(days), forKey: "kernel.goal.days") }
        // The streak counts days, so only the first listen of a day moves it.
        let last = d.double(forKey: "kernel.goal.lastDay"), t = today.timeIntervalSince1970
        if last != t { d.set(t - last <= 86400 ? d.integer(forKey: "kernel.goal.streak") + 1 : 1, forKey: "kernel.goal.streak"); d.set(t, forKey: "kernel.goal.lastDay") }
        if met && !wasMet { Task { await remind() } }
    }

    /// Queue or clear the end-of-week reminder to match where the week stands. Safe to call any time.
    func remind() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminder])
        roll()
        guard target > 0, !met else { return }
        // The evening of the week's last day (Saturday where weeks start Sunday, Sunday where they start Monday).
        var last = DateComponents(); last.weekday = (Calendar.current.firstWeekday + 5) % 7 + 1; last.hour = 18
        // Only this week's evening: past it, a reminder would land next week carrying this week's numbers.
        let cal = Calendar.current
        guard let at = cal.nextDate(after: .now, matching: last, matchingPolicy: .nextTime),
              let end = cal.date(byAdding: .day, value: 7, to: Self.week()), at < end else { return }
        let when = cal.dateComponents([.year, .month, .day, .hour, .minute], from: at)
        let content = UNMutableNotificationContent()
        content.title = "Weekly goal"
        content.body = "\(target - minutes) minutes to go this week. One chapter gets you closer."
        content.sound = .default
        try? await center.add(UNNotificationRequest(identifier: Self.reminder, content: content,
                                                    trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: false)))
    }

    /// Setting a goal asks once for permission to remind.
    func set(_ minutes: Int) async {
        if minutes > 0 { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) }
        target = minutes
    }
}

/// A tapped reminder opens its book: the nudge carries the slug, the library watches `slug`.
@Observable
final class NoteTap: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NoteTap()
    var slug: String?
    var play = false   // "Continue my book": play once the book page has loaded it
    func userNotificationCenter(_ c: UNUserNotificationCenter, didReceive r: UNNotificationResponse) async {
        let s = r.notification.request.content.userInfo["slug"] as? String
        await MainActor.run { slug = s }
    }
    func userNotificationCenter(_ c: UNUserNotificationCenter, willPresent n: UNNotification) async -> UNNotificationPresentationOptions { [.banner, .sound] }
}
