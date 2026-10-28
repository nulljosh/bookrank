import SwiftUI

@main
struct KernelWatchApp: App {
    @StateObject private var lines = Lines()

    var body: some Scene {
        WindowGroup {
            ContentView(lines: lines)
        }
    }
}
