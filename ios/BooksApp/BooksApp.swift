import SwiftUI

@main
struct BooksApp: App {
    var body: some Scene {
        WindowGroup {
            WebView(url: URL(string: "https://books.heyitsmejosh.com")!)
                .ignoresSafeArea()
        }
    }
}
