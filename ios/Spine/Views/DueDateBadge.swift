import SwiftUI

struct DueDateBadge: View {
    let dueDateString: String

    private var due: Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f.date(from: dueDateString) ?? .now
    }

    private var days: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: due)).day ?? 0
    }

    private var formattedDue: String {
        due.formatted(.dateTime.month(.abbreviated).day())
    }

    private var text: String {
        if days < 0 { return "Overdue · was due \(formattedDue)" }
        if days == 0 { return "Due today (\(formattedDue))" }
        return "Due \(formattedDue) · \(days) day\(days == 1 ? "" : "s") left"
    }

    private var color: Color {
        if days < 0 { return .red }
        if days <= 5 { return .primary }
        return .secondary
    }

    var body: some View {
        Text(text)
            .font(.system(.caption, design: .monospaced).weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(days < 0 ? Color.red : Color.secondary.opacity(0.3), lineWidth: 1)
            )
    }
}
