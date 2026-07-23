import SwiftUI

struct BadgeLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .medium))
            .tracking(0.6)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().stroke(.secondary.opacity(0.35), lineWidth: 1))
    }
}
