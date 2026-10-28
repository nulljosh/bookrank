import SwiftUI

/// What the user picked on the last page. LibraryView acts on it after the cover closes.
enum OnboardingChoice { case sample, signIn, skip }

/// Three short first-run pages. iPhone swipes between them, the Mac shows one at a time;
/// both have Next. The last page offers the sample chapter or sign-in.
struct OnboardingView: View {
    let finish: (OnboardingChoice) -> Void
    @State private var page = 0

    private static let pages: [(title: String, body: String)] = [
        ("Remember every book.", "Chapter summaries of the books you own, read or listened to."),
        ("Every chapter in plain words.", "Read it, or press play and one narrator explains it."),
        ("Start with a sample.", "Look at one chapter first. No account needed."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") { finish(.skip) }
                    .keyboardShortcut(.cancelAction)
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 48)
                    .accessibilityHint("Closes the introduction")
            }
            .padding(.horizontal, 20)

            #if os(iOS)
            TabView(selection: $page) {
                ForEach(0..<Self.pages.count, id: \.self) { pageContent($0).tag($0) }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            pageContent(page)
            #endif

            dots.padding(.bottom, 24)
            bottomButtons
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
        }
        #if os(macOS)
        .frame(width: 480, height: 560)
        #endif
    }

    private func pageContent(_ i: Int) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            visual(i).frame(height: 160)
            Text(Self.pages[i].title)
                .font(.kernel(.largeTitle, weight: .bold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(Self.pages[i].body)
                .font(.kernel(.title3))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func visual(_ i: Int) -> some View {
        switch i {
        case 0: KernelMark(side: 160)
        case 1: Image(systemName: "text.book.closed").font(.system(size: 96, weight: .regular)).foregroundStyle(amber)
        default: Image(systemName: "books.vertical").font(.system(size: 96, weight: .regular)).foregroundStyle(amber)
        }
    }

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0..<Self.pages.count, id: \.self) { i in
                Circle().fill(i == page ? amber : Color.secondary.opacity(0.3)).frame(width: 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(page + 1) of \(Self.pages.count)")
    }

    @ViewBuilder
    private var bottomButtons: some View {
        if page < Self.pages.count - 1 {
            Button("Next") { withAnimation { page += 1 } }
                .buttonStyle(GoldCapsule())
                .keyboardShortcut(.defaultAction)
        } else {
            VStack(spacing: 8) {
                Button("Try a sample chapter") { finish(.sample) }
                    .buttonStyle(GoldCapsule())
                    .keyboardShortcut(.defaultAction)
                Button("Sign in") { finish(.signIn) }
                    .buttonStyle(OutlineCapsule())
            }
        }
    }
}

/// The gold capsule: Kernel's amber with the same dark text the Sign in button uses in LibraryView.
private struct GoldCapsule: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.kernel(.body, weight: .semibold))
            .foregroundStyle(onAmber)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(amber, in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// The plain capsule: an outline, no fill.
private struct OutlineCapsule: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.kernel(.body, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, minHeight: 48)
            .overlay(Capsule().strokeBorder(Color.secondary.opacity(0.5), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}
