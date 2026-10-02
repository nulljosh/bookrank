import SwiftUI

struct ContentView: View {
    @ObservedObject var lines: Lines
    @State private var current: (title: String, text: String)?

    var body: some View {
        if lines.entries.isEmpty {
            VStack(spacing: 12) {
                Text("Open Bookrank on your iPhone to bring a few lines here.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if let (title, text) = current {
                        Text(title)
                            .font(.caption2)
                            .foregroundStyle(Color(red: 239/255, green: 160/255, blue: 72/255))
                        Text(text)
                            .font(.body)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                current = lines.nextLine()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(current.map { "\($0.title): \($0.text)" } ?? "")
            .onAppear {
                current = lines.nextLine()
            }
        }
    }
}
