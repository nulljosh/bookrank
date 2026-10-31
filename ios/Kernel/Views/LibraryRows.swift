import SwiftUI

// Rows at the top of the library, split out of LibraryView.swift.

/// The weekly goal: a gold ring and the minutes so far.
struct GoalRow: View {
    var body: some View {
        let g = Goal.shared
        let f = min(1, Double(g.minutes) / Double(max(g.target, 1)))
        return HStack(spacing: 14) {
            ZStack {
                Circle().inset(by: 2.5).stroke(amber.opacity(0.2), lineWidth: 5)
                Circle().inset(by: 2.5).trim(from: 0, to: f).stroke(amber, style: StrokeStyle(lineWidth: 5, lineCap: .round)).rotationEffect(.degrees(-90))
            }
            .frame(width: 36, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(g.met ? "Weekly goal met" : g.streak > 1 ? "\(g.streak)-day streak" : "This week").font(.kernel(.footnote, weight: .semibold)).foregroundStyle(amber)
                Text("\(g.minutes) of \(g.target) min").font(.kernel(.headline)).monospacedDigit()
            }
            Spacer(minLength: 8)
            // The week as seven dots, the way Books shows it: gold where you listened, a ring on today.
            let cal = Calendar.current
            let names = cal.veryShortStandaloneWeekdaySymbols
            let today = cal.dateComponents([.day], from: Goal.week(), to: cal.startOfDay(for: .now)).day ?? 0
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    VStack(spacing: 4) {
                        Text(names[(cal.firstWeekday - 1 + i) % 7]).font(.kernel(.caption2)).foregroundStyle(.secondary)
                        Circle().fill(g.days.contains(i) ? amber : amber.opacity(0.15)).frame(width: 9, height: 9)
                            .overlay { if i == today { Circle().strokeBorder(amber, lineWidth: 1.5).frame(width: 15, height: 15) } }
                            .frame(width: 15, height: 15)
                    }
                }
            }
            .accessibilityHidden(true)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

/// Continue: bigger cover, where you are and what is left, a gold progress line.
struct ContinueCard: View {
    let entry: SummaryEntry
    let store: DataStore

    var body: some View {
        let chapters = parseChapters(entry.content)
        let ch = min(entry.listen?.pos.ch ?? 0, max(0, chapters.count - 1))
        let left = chapters.isEmpty ? minutes(entry.content) : minutes(chapters[ch...].map(\.text).joined())
        return HStack(spacing: 16) {
            Thumb(url: store.cover(for: entry), width: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text("Continue").font(.kernel(.footnote, weight: .semibold)).foregroundStyle(amber)
                Text(entry.title).font(.kernel(.headline)).lineLimit(2)
                Text("Chapter \(ch + 1) of \(max(chapters.count, 1)) · \(duration(left)) left").font(.kernel(.footnote)).foregroundStyle(.secondary)
                ProgressView(value: Double(ch), total: Double(max(chapters.count, 1))).tint(amber).padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}
