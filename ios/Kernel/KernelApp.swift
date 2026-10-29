import SwiftUI
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
        if CommandLine.flag("UITEST_CONTINUE"), let e = DataStore.lastStarted() { NoteTap.shared.play = true; NoteTap.shared.slug = e.slug }
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
            .font(.kernel(.body))
        }
    }
}

/// Kernel Sans (fonts/, built by scripts/gen_font.py), registered from the bundle once so
/// neither Info.plist needs a font list.
private let kernelFontsRegistered: Void = {
    for name in ["Regular", "Medium", "Semibold", "Bold"] {
        if let url = Bundle.main.url(forResource: "KernelSans-\(name)", withExtension: "otf") {
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
