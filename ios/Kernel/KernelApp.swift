import SwiftUI

extension CommandLine {
    /// Screenshot hooks. iOS takes the bare word; on the Mac AppKit opens a bare argument as a
    /// file and never shows the window, so launch with `-UITEST_SNAPSHOT 1` there.
    static func flag(_ name: String) -> Bool { arguments.contains(name) || UserDefaults.standard.bool(forKey: name) }
}

@main
struct KernelApp: App {
    // Covers load through URLSession, so a bigger disk cache keeps them on screen offline.
    init() { URLCache.shared = URLCache(memoryCapacity: 20 << 20, diskCapacity: 200 << 20) }
    // One splash per cold launch. Store screenshots skip it so they stay the same.
    @State private var showSplash = !CommandLine.flag("UITEST_SNAPSHOT")
    @AppStorage("spine-theme") private var theme: String = "system"

    var body: some Scene {
        WindowGroup {
            ZStack {
                LibraryView(splashDone: !showSplash)
                if showSplash {
                    SplashView { showSplash = false }
                        .transition(.identity)   // SplashView fades itself out before it calls back
                }
            }
            .preferredColorScheme(theme == "dark" ? .dark : theme == "light" ? .light : nil)
            .tint(amber)
        }
    }
}
