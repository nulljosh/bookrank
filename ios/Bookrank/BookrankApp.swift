import SwiftUI

@main
struct BookrankApp: App {
    // Covers load through URLSession, so a bigger disk cache keeps them on screen offline.
    init() { URLCache.shared = URLCache(memoryCapacity: 20 << 20, diskCapacity: 200 << 20) }

    var body: some Scene {
        WindowGroup {
            LibraryView()
        }
    }
}
