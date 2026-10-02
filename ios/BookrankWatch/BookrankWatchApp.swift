import SwiftUI

@main
struct BookrankWatchApp: App {
    @StateObject private var lines = Lines()

    var body: some Scene {
        WindowGroup {
            ContentView(lines: lines)
        }
    }
}
