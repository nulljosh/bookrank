import SwiftUI

@main
struct SpineApp: App {
    var body: some Scene {
        WindowGroup {
            WebView(url: URL(string: "https://spine.heyitsmejosh.com")!)
                .ignoresSafeArea()
        }
    }
}
