import AuthenticationServices
import SwiftUI
import Supabase

/// Sign in, sign up, and account deletion.
///
/// Auth is optional on purpose: the rankings, library and picks are all bundled and
/// readable signed-out. Signing in only adds your own summaries. An app that shows a
/// stranger nothing but a login wall is the Guideline 4.2 risk this avoids.
struct AccountView: View {
    @Environment(\.colorScheme) private var colorScheme
    let auth: AuthStore
    let store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isSigningUp = false
    @State private var message: String?
    @State private var busy = false
    @State private var confirmDelete = ""
    @State private var showDelete = false
    @State private var username = ""
    @State private var goodreads = ""
    @State private var exportURLs: [URL] = []
    @State private var newEmail = ""
    @State private var newPassword = ""

    private var generated: Bool { auth.user?.userMetadata["avatar_source"]?.stringValue == "generated" }
    private var linkedPhoto: String? {
        auth.user?.userMetadata["goodreads_avatar"]?.stringValue
            ?? auth.user?.identities?.first { $0.provider == "github" }?.identityData?["avatar_url"]?.stringValue
    }
    private var goodreadsProfile: [String: AnyJSON]? { auth.user?.userMetadata["goodreads_profile"]?.objectValue }

    /// Photo, genres, about, interests and best quote from the public profile, saved with the link.
    private func goodreadsMeta(_ id: String) async -> [String: AnyJSON] {
        guard let url = URL(string: "https://bookrank.heyitsmejosh.com/api/goodreads?user=\(id)&profile=1"),
              let (data, resp) = try? await URLSession.shared.data(from: url), (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONDecoder().decode(AnyJSON.self, from: data), let o = json.objectValue, o["name"]?.stringValue != nil else { return [:] }
        var profile: [String: AnyJSON] = [:]
        for k in ["about", "interests", "genres", "quote"] { profile[k] = o[k] ?? .null }
        return ["goodreads_avatar": o["avatar"] ?? .null, "goodreads_profile": .object(profile)]
    }

    private func saveGoodreads() {
        let id = goodreads.firstMatch(of: /(\d{3,})/).map { String($0.1) }
        run {
            if !goodreads.trimmingCharacters(in: .whitespaces).isEmpty && id == nil { return "That does not look like a Goodreads profile link." }
            var meta: [String: AnyJSON] = ["goodreads": id.map { .string($0) } ?? .null]
            if let id { meta.merge(await goodreadsMeta(id)) { _, new in new } } else { meta["goodreads_avatar"] = .null; meta["goodreads_profile"] = .null }
            try await auth.setMetadata(meta)
            await store.loadGoodreads(id)
            return id == nil ? "Unlinked." : "Linked. \(store.goodreadsQueue.count) books read, no summary yet."
        }
    }

    private func saveUsername() {
        let u = username.lowercased().filter { $0.isLetter || $0.isNumber || "._-".contains($0) }.prefix(32)
        guard !u.isEmpty else { username = auth.handle; return }
        run { try await auth.setMetadata(["username": .string(String(u))]); username = auth.handle; return "Username saved." }
    }

    var body: some View {
        NavigationStack {
            Group {
                if auth.isSignedIn {
                    Form {
                        signedIn
                        if let message {
                            Section { Text(message).font(.footnote).foregroundStyle(.secondary) }
                        }
                    }
                    .navigationTitle("Account")
                } else {
                    authScreen
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .disabled(busy)
        }
    }

    // MARK: - Signed out

    /// Matches the web sign-in: icon, bold title, Apple first, then email and password, one orange pill.
    private static let orange = Color(red: 239 / 255, green: 160 / 255, blue: 72 / 255)

    private var authScreen: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Self.orange)
                    .frame(width: 72, height: 72)
                    .background(Color(red: 0.07, green: 0.09, blue: 0.18), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .accessibilityHidden(true)
                    .padding(.top, 12)
                Text(isSigningUp ? "Create your account" : "Sign in to Bookrank")
                    .font(.title.weight(.semibold)).tracking(-0.8)
                    .multilineTextAlignment(.center)
                Text(isSigningUp ? "Chapter summaries of the books you read, in one private place." : "Your chapter summaries. Private to your account.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    .padding(.bottom, 8)

                if !isSigningUp && auth.hasSavedBiometricCredentials() {
                    Button {
                        run { try await auth.biometricLogin(); return nil }
                    } label: {
                        Label("Sign in with Face ID", systemImage: "faceid").frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.bordered).clipShape(Capsule())
                }

                SignInWithAppleButton(.continue) { auth.prepareApple($0) } onCompletion: { result in
                    run {
                        guard try await auth.signInWithApple(result) else { return nil }
                        await store.loadSummaries()
                        return nil
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 46)
                .clipShape(Capsule())

                HStack(spacing: 10) {
                    Rectangle().fill(.quaternary).frame(height: 1)
                    Text("or").font(.footnote).foregroundStyle(.secondary)
                    Rectangle().fill(.quaternary).frame(height: 1)
                }
                .padding(.vertical, 4)

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
                    .textFieldStyle(.plain).padding(12)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                SecureField(isSigningUp ? "Password, 8 characters or more" : "Password", text: $password)
                    .textContentType(isSigningUp ? .newPassword : .password)
                    .textFieldStyle(.plain).padding(12)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    run {
                        if isSigningUp {
                            let live = try await auth.signUp(email: email, password: password)
                            if !live { return "Check your email to confirm the account, then sign in." }
                        } else {
                            try await auth.signIn(email: email, password: password)
                        }
                        await store.loadSummaries()
                        return nil
                    }
                } label: {
                    Text(isSigningUp ? "Create account" : "Sign in")
                        .font(.body.weight(.medium)).foregroundStyle(Color(red: 0.10, green: 0.07, blue: 0.03))
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(Self.orange, in: Capsule())
                }
                .buttonStyle(.plain)
                .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1)
                .disabled(email.isEmpty || password.isEmpty)

                if let message {
                    Text(message).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }

                HStack {
                    if !isSigningUp {
                        Button("Forgot password?") {
                            run {
                                try await auth.resetPassword(email: email)
                                return "Reset link sent to \(email)."
                            }
                        }
                        .disabled(email.isEmpty)
                    }
                    Spacer()
                    Button(isSigningUp ? "Have an account? Sign in" : "New here? Create an account") {
                        isSigningUp.toggle()
                        message = nil
                    }
                }
                .font(.footnote).foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 380)
            .padding(.horizontal, 24).padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Signed in

    @ViewBuilder
    private var signedIn: some View {
        // Same profile the web shows at profile.html?u=<username>: username + avatar live in
        // auth user_metadata, so both read and write the same fields.
        Section {
            HStack(spacing: 14) {
                Button { run { try await auth.setMetadata(["avatar": .string(AvatarArt.svg()), "avatar_source": .string("generated")]); return "New avatar saved." } } label: {
                    AvatarView(svg: generated ? auth.user?.userMetadata["avatar"]?.stringValue : nil,
                               initial: String(auth.user?.email?.first ?? "?"), photo: generated ? nil : linkedPhoto)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Generate a new avatar")
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Username", text: $username, onCommit: saveUsername)
                        .font(.headline)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .onSubmit(saveUsername)
                        #endif
                    Text("bookrank.heyitsmejosh.com/profile?u=\(auth.handle)").font(.caption2).foregroundStyle(.secondary)
                    Text("Tap the avatar for a new one.").font(.caption2).foregroundStyle(.tertiary)
                }
            }
            .onAppear { username = auth.handle }
            LabeledContent("Email", value: auth.user?.email ?? "—")
            LabeledContent("Summaries", value: "\(store.summaryIndex.count)")
            if let q = goodreadsProfile?["quote"]?.objectValue, let text = q["text"]?.stringValue {
                Text("\u{201C}\(text)\u{201D}" + (q["author"]?.stringValue.map { " \($0)" } ?? ""))
                    .font(.footnote.italic()).foregroundStyle(.secondary)
            }
            if let about = goodreadsProfile?["about"]?.stringValue { LabeledContent("About", value: about) }
            if let interests = goodreadsProfile?["interests"]?.stringValue { LabeledContent("Interests", value: interests) }
            if let genres = goodreadsProfile?["genres"]?.arrayValue?.compactMap(\.stringValue), !genres.isEmpty {
                LabeledContent("Favorite genres", value: genres.joined(separator: ", "))
            }
        }

        Section {
            TextField("Goodreads profile link", text: $goodreads, onCommit: saveGoodreads)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                #endif
        } header: {
            Text("Goodreads")
        } footer: {
            Text("Paste your profile link. Books you have read but not summarized show up under your list.")
        }
        .onAppear { goodreads = auth.user?.userMetadata["goodreads"]?.stringValue.map { "goodreads.com/user/show/\($0)" } ?? "" }
        .task {
            guard let id = auth.user?.userMetadata["goodreads"]?.stringValue, goodreadsProfile == nil else { return }
            let meta = await goodreadsMeta(id)
            if !meta.isEmpty { try? await auth.setMetadata(meta) }
        }

        Section {
            if !exportURLs.isEmpty {
                ShareLink(items: exportURLs) { Label("Export everything (\(exportURLs.count) files)", systemImage: "square.and.arrow.up") }
            }
        } header: {
            Text("Your data")
        } footer: {
            Text("Every summary as a markdown file. Yours to keep.")
        }
        .task(id: store.summaryIndex.count) { exportURLs = store.writeExport() }

        Section("Credentials") {
            TextField("New email", text: $newEmail).textContentType(.emailAddress).autocorrectionDisabled()
            SecureField("New password (8+ characters)", text: $newPassword).textContentType(.newPassword)
            Button("Update") {
                run {
                    try await auth.updateCredentials(email: newEmail.isEmpty ? nil : newEmail, password: newPassword.isEmpty ? nil : newPassword)
                    let note = [newEmail.isEmpty ? nil : "Confirmation sent to \(newEmail).", newPassword.isEmpty ? nil : "Password updated."].compactMap { $0 }.joined(separator: " ")
                    newEmail = ""; newPassword = ""
                    return note
                }
            }
            .disabled(newEmail.isEmpty && (newPassword.isEmpty || newPassword.count < 8))
            Button("Email me a reset link") { run { try await auth.resetPassword(email: auth.user?.email ?? ""); return "Reset link sent." } }
        }

        Section {
            Button("Sign out") {
                run {
                    try await auth.signOut()
                    store.clearSummaries()
                    return nil
                }
            }
        }

        Section {
            if showDelete {
                TextField("Type DELETE to confirm", text: $confirmDelete)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.characters)
                    #endif
                Button("Delete my account", role: .destructive) {
                    run {
                        try await auth.deleteAccount()
                        store.clearSummaries()
                        return nil
                    }
                }
                .disabled(confirmDelete != "DELETE")
            } else {
                Button("Delete account", role: .destructive) { showDelete = true }
            }
        } footer: {
            Text("Deletes your account and every summary in it, immediately and permanently. There is no undo. Export first if you want a copy.")
        }
    }

    // MARK: - Plumbing

    /// Every button is the same shape: disable the form, run one throwing call, show
    /// either the message it returns or the error it threw. Worth the six lines to keep
    /// that out of each call site.
    private func run(_ work: @escaping () async throws -> String?) {
        busy = true
        message = nil
        Task {
            do {
                message = try await work()
            } catch {
                message = error.localizedDescription
            }
            busy = false
        }
    }
}

/// Pixel-art identicon, mirrored 8x8, same shape as profile.html's avatarSVG. House palette: no purple, no teal.
enum AvatarArt {
    static func svg() -> String {
        let palettes = [["#e63946","#f1a7ad","#ffffff"], ["#1d3557","#457b9d","#a8dadc"], ["#d62828","#f77f00","#fcbf49"], ["#2d6a4f","#52b788","#b7e4c7"], ["#222222","#777777","#dddddd"]]
        let palette = palettes.randomElement()!
        let bg = ["#111","#1a1a1a","#0f0f1a","#0a1a0a","#f4f1ea"].randomElement()!
        let px = 8, size = 8, total = size * px
        let grid = (0..<size).map { _ in (0..<size / 2).map { _ in Double.random(in: 0..<1) > 0.45 ? Int.random(in: 0..<3) : -1 } }
        var rects = ""
        for row in 0..<size { for col in 0..<size {
            let ci = grid[row][col < size / 2 ? col : size - 1 - col]
            if ci >= 0 { rects += "<rect x=\"\(col * px)\" y=\"\(row * px)\" width=\"\(px)\" height=\"\(px)\" fill=\"\(palette[ci])\"/>" }
        } }
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 \(total) \(total)\" shape-rendering=\"crispEdges\"><rect width=\"\(total)\" height=\"\(total)\" fill=\"\(bg)\"/>\(rects)</svg>"
    }
}

/// Draws the avatar SVG natively (rects only, no SVG renderer needed); initial when there is none.
struct AvatarView: View {
    let svg: String?
    let initial: String
    var photo: String? = nil   // linked Goodreads photo, then GitHub's; shown unless generated art was chosen

    var body: some View {
        ZStack {
            if let svg, let art = parse(svg) {
                Canvas { ctx, size in
                    let s = size.width / 64
                    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(art.bg))
                    for r in art.rects { ctx.fill(Path(CGRect(x: r.x * s, y: r.y * s, width: 8 * s, height: 8 * s)), with: .color(r.color)) }
                }
            } else if let photo, let url = URL(string: photo) {
                AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { Color.secondary.opacity(0.15) }
            } else {
                Color.secondary.opacity(0.15)
                Text(initial.uppercased()).font(.title2).foregroundStyle(.secondary)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.quaternary))
    }

    private struct Art { var bg: Color; var rects: [(x: CGFloat, y: CGFloat, color: Color)] }
    private func parse(_ svg: String) -> Art? {
        let re = try! NSRegularExpression(pattern: #"<rect (?:x="(\d+)" y="(\d+)" )?width="(\d+)" height="(\d+)" fill="(#[0-9a-fA-F]+)""#)
        let ns = svg as NSString
        var art = Art(bg: .black, rects: [])
        for m in re.matches(in: svg, range: NSRange(location: 0, length: ns.length)) {
            let hex = ns.substring(with: m.range(at: 5))
            if m.range(at: 1).location == NSNotFound { art.bg = Color(hex: hex) }
            else { art.rects.append((CGFloat(Int(ns.substring(with: m.range(at: 1)))!), CGFloat(Int(ns.substring(with: m.range(at: 2)))!), Color(hex: hex))) }
        }
        return art.rects.isEmpty ? nil : art
    }
}

private extension Color {
    init(hex: String) {
        var h = hex.dropFirst()
        if h.count == 3 { h = Substring(h.map { "\($0)\($0)" }.joined()) }
        let v = UInt64(h, radix: 16) ?? 0
        self.init(red: Double((v >> 16) & 0xff) / 255, green: Double((v >> 8) & 0xff) / 255, blue: Double(v & 0xff) / 255)
    }
}
