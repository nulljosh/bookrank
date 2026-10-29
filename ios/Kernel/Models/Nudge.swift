import Foundation
import UserNotifications

/// Daily review nudge: one local notification at 9:00 with one of your highlights or a line from one of your summaries, so a book you
/// finished comes back a little at a time. Seven days are queued at once and re-queued each launch, so it
/// keeps going without a server. Off by default; the toggle in Account asks for permission.
enum Nudge {
    static let key = "bookrank.nudge"
    private static let prefix = "bookrank.nudge."
    static var enabled: Bool { UserDefaults.standard.bool(forKey: key) }
    /// The hour the morning line arrives, so nothing comes before you are up. 9 unless you pick another.
    static var hour: Int { UserDefaults.standard.object(forKey: "kernel.nudgeHour") as? Int ?? 9 }
    private static let recapID = "kernel.recap"

    /// The week's last evening at 19:00: minutes listened and on how many days. Requeued whenever listening is saved,
    /// so the numbers are as of the last time you listened. ponytail: no background refresh; a week with no launch says nothing new.
    static func recap() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [recapID])
        guard UserDefaults.standard.bool(forKey: recapID) else { return }
        let cal = Calendar.current
        var last = DateComponents(); last.weekday = (cal.firstWeekday + 5) % 7 + 1; last.hour = 19
        guard let at = cal.nextDate(after: .now, matching: last, matchingPolicy: .nextTime),
              let end = cal.date(byAdding: .day, value: 7, to: Goal.week()), at < end else { return }
        let g = Goal.shared, content = UNMutableNotificationContent()
        content.title = String(localized: "Your week in Kernel")
        content.body = g.minutes == 0 ? String(localized: "No listening this week yet. A chapter takes about five minutes.")
            : String(localized: "\(g.minutes) minutes listened, on \(g.days.count) days.")
        try? await center.add(UNNotificationRequest(identifier: recapID, content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: cal.dateComponents([.year, .month, .day, .hour, .minute], from: at), repeats: false)))
    }

    /// A readable paragraph: not a heading, a sentence or two, cut at a sentence end under ~170 characters.
    static func line(from content: String) -> String? {
        let paras = content.components(separatedBy: "\n\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.hasPrefix("#") && $0.count >= 60 && !$0.contains("|") && !$0.hasPrefix("-") && !$0.hasPrefix("*") }
        guard let p = paras.randomElement() else { return nil }
        let flat = p.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "\n", with: " ")
        guard flat.count > 170 else { return flat }
        let head = String(flat.prefix(170))
        if let end = head.lastIndex(where: { ".!?".contains($0) }), head.distance(from: head.startIndex, to: end) > 60 { return String(head[...end]) }
        return head.trimmingCharacters(in: .whitespaces) + "…"
    }

    static func enable(_ on: Bool, entries: [SummaryEntry]) async -> Bool {
        let center = UNUserNotificationCenter.current()
        if on {
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else {
                UserDefaults.standard.set(false, forKey: key); return false
            }
            UserDefaults.standard.set(true, forKey: key)
            await schedule(entries)
        } else {
            UserDefaults.standard.set(false, forKey: key)
            center.removePendingNotificationRequests(withIdentifiers: (0..<7).map { prefix + "\($0)" })
        }
        return on
    }

    /// Extract random lines from entries for watch sync. Returns up to `count` dicts with "title" and "text" keys.
    static func lines(from entries: [SummaryEntry], count: Int = 30) -> [[String: String]] {
        var result: [[String: String]] = []
        var tried = Set<Int>()
        while result.count < count && tried.count < entries.count {
            guard let index = (0..<entries.count).randomElement(), !tried.contains(index) else { continue }
            tried.insert(index)
            let entry = entries[index]
            guard let text = line(from: entry.content) else { continue }
            result.append(["title": entry.title, "text": text])
        }
        return result
    }

    /// Re-queue the next seven mornings. Safe to call on every launch.
    static func schedule(_ entries: [SummaryEntry]) async {
        guard enabled, !entries.isEmpty else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<7).map { prefix + "\($0)" })
        let cal = Calendar.current
        // Your own highlights come back first; a random line from a book fills the other days.
        var marked = entries.flatMap { e in (e.listen?.marks ?? []).map { (e, $0.text) } }.shuffled()
        for day in 0..<7 {
            let pick: (SummaryEntry, String)? = marked.popLast() ?? entries.randomElement().flatMap { e in line(from: e.content).map { (e, $0) } }
            guard let (entry, text) = pick, let date = cal.date(byAdding: .day, value: day, to: Date()) else { continue }
            var when = cal.dateComponents([.year, .month, .day], from: date)
            when.hour = hour; when.minute = 0
            if let at = cal.date(from: when), at <= Date() { continue }   // today's hour already passed
            let content = UNMutableNotificationContent()
            content.title = entry.title
            content.body = text
            content.sound = .default
            content.userInfo = ["slug": entry.slug]   // a tap opens the book
            try? await center.add(UNNotificationRequest(identifier: prefix + "\(day)", content: content, trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: false)))
        }
    }
}
