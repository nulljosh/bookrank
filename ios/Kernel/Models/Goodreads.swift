import SwiftUI
import WebKit

/// Goodreads has had no API or app sign-in since 2020, and its shelves went private on 2026-10-28,
/// so signing in means Goodreads' own sign-in page in a web view. The session lives in this device's
/// web data; `GR.sync()` from goodreads-parse.js reads the account's own shelves, ratings, reviews and
/// reading progress from goodreads.com inside a hidden web view. Nothing goes to our server.
@MainActor @Observable
final class Goodreads: NSObject, WKNavigationDelegate {
    static let shared = Goodreads()
    struct Progress: Codable, Hashable { let page: Int?; let of: Int?; let percent: Int }
    struct Synced: Codable {
        let user: String
        var shelves: [String: [DataStore.GoodreadsBook]]
        var status: [String: Progress]
        var at = Date()
    }
    private(set) var data: Synced?
    private(set) var syncing = false
    private(set) var error: String?
    var signedIn: Bool { data != nil }

    private let web = WKWebView(frame: .zero, configuration: Goodreads.config())
    private var loaded: CheckedContinuation<Void, Never>?
    private static let file = URL.applicationSupportDirectory.appending(path: "goodreads.json")

    nonisolated static func config() -> WKWebViewConfiguration {
        let c = WKWebViewConfiguration(); c.websiteDataStore = .default(); return c
    }

    override private init() {
        super.init()
        web.navigationDelegate = self
        data = (try? Data(contentsOf: Self.file)).flatMap { try? JSONDecoder().decode(Synced.self, from: $0) }
    }

    /// Read every shelf and the latest progress. False when Goodreads says nobody is signed in.
    @discardableResult
    func sync() async -> Bool {
        guard !syncing, let src = Bundle.main.url(forResource: "goodreads-parse", withExtension: "js").flatMap({ try? String(contentsOf: $0, encoding: .utf8) }) else { return false }
        syncing = true; error = nil
        defer { syncing = false }
        await withCheckedContinuation { loaded = $0; web.load(URLRequest(url: URL(string: "https://www.goodreads.com/robots.txt")!)) }
        do {
            _ = try await web.evaluateJavaScript(src)
            guard let json = try await web.callAsyncJavaScript("return await GR.sync()", contentWorld: .page) as? String,
                  let out = try? JSONDecoder().decode(Raw.self, from: Data(json.utf8)) else { error = "Goodreads sent something unexpected."; return false }
            guard out.signedIn, let user = out.user else { data = nil; try? FileManager.default.removeItem(at: Self.file); error = "Signed out of Goodreads."; return false }
            let status = out.status ?? [:]
            // Currently reading carries its latest "on page 230 of 368" or "85% done".
            var shelves = out.shelves ?? [:]
            shelves["currently-reading"] = shelves["currently-reading"]?.map { b in
                var b = b; if let p = b.bookId.flatMap({ status[$0] }) { b.progress = p.percent; b.page = p.page; b.of = p.of }; return b
            }
            let s = Synced(user: user, shelves: shelves, status: status)
            data = s
            try? JSONEncoder().encode(s).write(to: Self.file)
            return true
        } catch {
            self.error = "Could not reach Goodreads."
            return false
        }
    }
    private struct Raw: Decodable { let signedIn: Bool; let user: String?; let shelves: [String: [DataStore.GoodreadsBook]]?; let status: [String: Progress]? }

    /// Forget the account: the synced copy and every Goodreads cookie on this device.
    func signOut() async {
        data = nil
        try? FileManager.default.removeItem(at: Self.file)
        let store = WKWebsiteDataStore.default()
        let records = await store.dataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes())
        await store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records.filter { $0.displayName.contains("goodreads") })
    }

    nonisolated func webView(_ w: WKWebView, didFinish n: WKNavigation!) { Task { @MainActor in loaded?.resume(); loaded = nil } }
    nonisolated func webView(_ w: WKWebView, didFail n: WKNavigation!, withError e: Error) { Task { @MainActor in loaded?.resume(); loaded = nil } }
    nonisolated func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: Error) { Task { @MainActor in loaded?.resume(); loaded = nil } }
}

/// Goodreads' own sign-in page. Once a page on goodreads.com loads that is not a sign-in step, it syncs and closes.
struct GoodreadsSignIn: View {
    @Environment(\.dismiss) private var dismiss
    var onDone: () -> Void
    var body: some View {
        NavigationStack {
            WebPage(url: URL(string: "https://www.goodreads.com/user/sign_in")!) { url in
                guard url.host()?.hasSuffix("goodreads.com") == true, !url.path().contains("sign"), !url.path().hasPrefix("/ap/") else { return }
                Task { if await Goodreads.shared.sync() { onDone(); dismiss() } }
            }
            .navigationTitle("Goodreads")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 640)
        #endif
    }
}

/// A plain web view that reports each page it finishes.
private struct WebPage {
    let url: URL
    var finished: (URL) -> Void
    final class Coordinator: NSObject, WKNavigationDelegate {
        var finished: (URL) -> Void
        init(_ f: @escaping (URL) -> Void) { finished = f }
        func webView(_ w: WKWebView, didFinish n: WKNavigation!) { if let u = w.url { finished(u) } }
    }
    func makeCoordinator() -> Coordinator { Coordinator(finished) }
    func make(_ c: Coordinator) -> WKWebView {
        let w = WKWebView(frame: .zero, configuration: Goodreads.config())
        w.navigationDelegate = c
        w.load(URLRequest(url: url))
        return w
    }
}
#if os(iOS)
extension WebPage: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView { make(context.coordinator) }
    func updateUIView(_ v: WKWebView, context: Context) {}
}
#else
extension WebPage: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView { make(context.coordinator) }
    func updateNSView(_ v: WKWebView, context: Context) {}
}
#endif
