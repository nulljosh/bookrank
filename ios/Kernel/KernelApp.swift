import SwiftUI
import CoreSpotlight
import UserNotifications
import CoreText

extension CommandLine {
    /// Screenshot hooks. iOS takes the bare word; on the Mac AppKit opens a bare argument as a
    /// file and never shows the window, so launch with `-UITEST_SNAPSHOT 1` there.
    static func flag(_ name: String) -> Bool { arguments.contains(name) || UserDefaults.standard.bool(forKey: name) }
}

@main
struct KernelApp: App {
    // Covers load through URLSession, so a bigger disk cache keeps them on screen offline.
    init() {
        URLCache.shared = URLCache(memoryCapacity: 20 << 20, diskCapacity: 200 << 20)
        UNUserNotificationCenter.current().delegate = NoteTap.shared   // a tapped reminder opens its book
        // Screenshot runs: act as if Siri ran Continue my book (the player stays silent under UITEST_SNAPSHOT).
        // Screenshot runs: one line in the error log so Account shows Export error log.
        if CommandLine.flag("UITEST_ERRORLOG") { try? "2026-10-29T08:00:00Z GET /rest/v1/bookrank_summaries: 503 The server said 503.\n".write(to: ErrorLog.file, atomically: true, encoding: .utf8) }
        if CommandLine.flag("UITEST_CONTINUE"), let e = DataStore.lastStarted() { NoteTap.shared.play = true; NoteTap.shared.slug = e.slug }
        #if os(macOS)
        if CommandLine.flag("UITEST_MENUBAR_SHOT") { DispatchQueue.main.async { MainActor.assumeIsolated { menuBarShots() } } }
        #endif
        #if os(iOS)
        // Navigation titles are UIKit's; give them Kernel Sans too. Register it first: UIFont(name:) finds nothing until then.
        _ = kernelFontsRegistered
        let bar = UINavigationBar.appearance()
        if let big = UIFont(name: "KernelSans-Bold", size: 34) { bar.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: big)] }
        if let small = UIFont(name: "KernelSans-Semibold", size: 17) { bar.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: small)] }
        #endif
    }
    // One splash per cold launch. Store screenshots skip it so they stay the same.
    @State private var showSplash = !CommandLine.flag("UITEST_SNAPSHOT")
    @AppStorage("spine-theme") private var theme: String = "system"
    @State private var palette = CommandLine.flag("UITEST_PALETTE")

    var body: some Scene {
        WindowGroup {
            ZStack {
                LibraryView(splashDone: !showSplash)
                    .onContinueUserActivity(Handoff.type) { a in if let s = a.userInfo?["slug"] as? String { NoteTap.shared.slug = s } }
                    .onOpenURL { u in if u.host() == "book", let s = u.pathComponents.last, s != "/" { NoteTap.shared.slug = s } }   // a widget
                    .task { WidgetFeed.publish(); await Inbox.importAll(into: DataStore.shared) }   // what was shared to Kernel
                    #if os(iOS)
                    .onChange(of: Speaker.shared.playing) { LiveListen.update() }
                    .onChange(of: Speaker.shared.paused) { LiveListen.update() }
                    .onChange(of: Speaker.shared.ch) { LiveListen.update() }
                    #endif
                    .onContinueUserActivity(CSSearchableItemActionType) { a in   // a Spotlight result
                        if let id = a.userInfo?[CSSearchableItemActivityIdentifier] as? String, let s = Spotlight.slug(from: id) { NoteTap.shared.slug = s }
                    }
                #if os(iOS)
                if CommandLine.flag("UITEST_WIDGETS") { WidgetGallery() }   // screenshots of the Home Screen widgets
                if CommandLine.flag("UITEST_GOODREADS_PAGE") { GoodreadsBookPage(title: "Atomic Habits") }   // screenshots: Mark Read on Goodreads
                if CommandLine.flag("UITEST_SHARE") {   // screenshots of the share sheet, as Safari would show it
                    ShareView(title: "The Psychology of Money", text: "", url: URL(string: "https://example.com/psychology-of-money")) { _ in }
                }
                #endif
                if showSplash {
                    SplashView { showSplash = false }
                        .transition(.identity)   // SplashView fades itself out before it calls back
                }
            }
            .preferredColorScheme(theme == "dark" || theme == "black" ? .dark : theme == "light" || theme == "sepia" ? .light : nil)
            .tint(amber)
            .font(.kernel(.body))
            .modifier(CalmMotion())
            .sheet(isPresented: $palette) { CommandPalette().tint(amber) }
        }
        .commands { ListenCommands(palette: $palette) }
        #if os(macOS)
        // A book in its own window (right-click a book > Open in New Window), sharing the library's data.
        WindowGroup("Book", id: "book", for: String.self) { $slug in
            NavigationStack { SummaryDetailView(slug: slug ?? "", store: DataStore.shared) }
                .preferredColorScheme(theme == "dark" || theme == "black" ? .dark : theme == "light" || theme == "sepia" ? .light : nil)
                .tint(amber).font(.kernel(.body)).modifier(CalmMotion())
                .frame(minWidth: 640, minHeight: 560)
        }
        MenuBarExtra("Kernel", systemImage: Speaker.shared.playing && !Speaker.shared.paused ? "book.fill" : "book", isInserted: .constant(Speaker.shared.slug != nil)) {
            MenuBarPlayer()
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}

/// Kernel Sans (fonts/, built by scripts/gen_font.py), registered from the bundle once so
/// neither Info.plist needs a font list.
private let kernelFontsRegistered: Void = {
    for name in ["Regular", "Medium", "Semibold", "Bold", "Italic", "BoldItalic"] {
        if let url = Bundle.main.url(forResource: "KernelSans-\(name)", withExtension: "otf") ?? Bundle.main.url(forResource: "KernelSans-\(name)", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}()

extension Font {
    /// Kernel Sans at a text style's size, scaling with Dynamic Type.
    static func kernel(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> Font {
        _ = kernelFontsRegistered
        let w = weight ?? (style == .headline ? .semibold : .regular)
        let name = switch w {
        case .bold, .heavy, .black: "KernelSans-Bold"
        case .semibold: "KernelSans-Semibold"
        case .medium: "KernelSans-Medium"
        default: "KernelSans-Regular"
        }
        return .custom(name, size: size(style), relativeTo: style)
    }

    /// Kernel Sans italic, for quotes: highlights, Today's five, a Goodreads quote. Bold for the share card.
    static func kernelItalic(_ style: Font.TextStyle, bold: Bool = false) -> Font {
        _ = kernelFontsRegistered
        return .custom(bold ? "KernelSans-BoldItalic" : "KernelSans-Italic", size: size(style), relativeTo: style)
    }

    private static func size(_ style: Font.TextStyle) -> CGFloat {
        #if os(macOS)
        switch style {
        case .largeTitle: 26; case .title: 22; case .title2: 17; case .title3: 15
        case .headline, .body: 13; case .callout: 12; case .subheadline, .footnote: 11
        default: 10   // ponytail: Kernel Sans sets tighter than SF, so footnote (chapter minutes) sits a point above the system size
        }
        #else
        switch style {
        case .largeTitle: 34; case .title: 28; case .title2: 22; case .title3: 20
        case .headline, .body: 17; case .callout: 16; case .subheadline: 15
        case .footnote: 13; case .caption: 12; default: 11
        }
        #endif
    }
}

/// With Reduce Motion on, nothing slides, springs or scrolls itself: every change lands at once.
private struct CalmMotion: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduce
    func body(content: Content) -> some View { content.transaction { if reduce { $0.animation = nil } } }
}
