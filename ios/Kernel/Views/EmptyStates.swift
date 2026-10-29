import SwiftUI

/// The library could not load and nothing is kept on this device yet: say so plainly and offer another try.
struct LoadFailed: View {
    let retry: () async -> Void
    @State private var trying = false
    var body: some View {
        ContentUnavailableView {
            Label("Could not reach your library", systemImage: "wifi.exclamationmark")
        } description: {
            Text("Check your connection, then try again.")
        } actions: {
            Button(trying ? "Trying…" : "Try again") { Task { trying = true; await retry(); trying = false } }
                .disabled(trying)
        }
    }
}
