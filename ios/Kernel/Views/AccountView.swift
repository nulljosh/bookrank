import AuthenticationServices
import SwiftUI

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
    @State private var nudge = Nudge.enabled
    @State private var showGoodreads = false
    @State private var usage: VoiceUsage?
    @AppStorage("spine-theme") private var theme: String = "system"
    @State private var newEmail = ""
    @State private var newPassword = ""

    private var generated: Bool { auth.user?.userMetadata["avatar_source"]?.stringValue == "generated" }
    private var linkedPhoto: String? {
        auth.user?.userMetadata["goodreads_avatar"]?.stringValue
    }
    private var goodreadsProfile: [String: AnyJSON]? { auth.user?.userMetadata["goodreads_profile"]?.objectValue }

    /// Photo, genres, about, interests and best quote from the public profile, saved with the link.
    private func goodreadsMeta(_ id: String) async -> [String: AnyJSON] {
        guard let url = URL(string: "https://bookrank.jaybulb.com/api/goodreads?user=\(id)&profile=1"),
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
        #if os(macOS)
        // A Mac sheet grows to its content; this one is taller than most windows, so the form
        // scrolls inside a fixed frame with Done in its own bar along the bottom. Escape closes it.
        VStack(spacing: 0) {
            content.frame(height: 552)   // the stack is greedy; pin it so the Done row stays inside the 600
            Divider()
            HStack { Spacer(); Button("Done") { dismiss() }.keyboardShortcut(.cancelAction) }
                .padding(.horizontal, 20).frame(height: 47)
        }
        .frame(width: 520, height: 600)
        .preferredColorScheme(theme == "dark" ? .dark : theme == "light" ? .light : nil)
        #else
        content.preferredColorScheme(theme == "dark" ? .dark : theme == "light" ? .light : nil)
        #endif
    }

    private var content: some View {
        NavigationStack {
            Group {
                if auth.isSignedIn {
                    Form {
                        signedIn
                        if let message {
                            Section { Text(message).font(.kernel(.footnote)).foregroundStyle(.secondary) }
                        }
                    }
                    #if os(macOS)
                    // The default Mac form style is a fixed grid: no scrolling, headers and footers
                    // as single truncated lines. Grouped scrolls and wraps, the way iOS already does.
                    .formStyle(.grouped)
                    #endif
                    .navigationTitle("Account")
                    .sheet(isPresented: $showGoodreads) {
                        GoodreadsSignIn {
                            // Signed in: link the profile too (photo, quote) if it was not linked yet, then refresh the shelves.
                            if goodreads.isEmpty, let u = Goodreads.shared.data?.user { goodreads = "goodreads.com/user/show/\(u)"; saveGoodreads() }
                            else { Task { await store.loadGoodreads(auth.user?.userMetadata["goodreads"]?.stringValue) } }
                        }
                    }
                } else {
                    authScreen
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                }
            }
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            #endif
            .disabled(busy)
        }
    }

    /// Light, dark or follow the device. Lives here, not in the toolbar; the key is the same one the shelf reads.
    private var appearancePicker: some View {
        Picker("Appearance", selection: $theme) {
            Text("Match device").tag("system")
            Text("Light").tag("light")
            Text("Dark").tag("dark")
        }
    }

    // MARK: - Signed out

    /// Matches the web sign-in: icon, bold title, Apple first, then email and password, one orange pill.

    private var authScreen: some View {
        ScrollView {
            VStack(spacing: 14) {
                // The app icon, as on the web sign-in: the white mark on the gold tile.
                KernelMark(side: 56, color: .white)
                    .frame(width: 72, height: 72)
                    .background(LinearGradient(colors: [Color(red: 0.96, green: 0.72, blue: 0.24), Color(red: 0.79, green: 0.48, blue: 0)], startPoint: .top, endPoint: .bottom), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityHidden(true)
                    .padding(.top, 12)
                Text(isSigningUp ? "Create your account" : "Sign in to Kernel")
                    .font(.kernel(.title, weight: .semibold)).tracking(-0.8)
                    .multilineTextAlignment(.center)
                Text(isSigningUp ? "Chapter summaries of the books you read, in one private place." : "Your chapter summaries. Private to your account.")
                    .font(.kernel(.subheadline)).foregroundStyle(.secondary).multilineTextAlignment(.center)
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
                    Text("or").font(.kernel(.footnote)).foregroundStyle(.secondary)
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
                        .font(.kernel(.body, weight: .medium)).foregroundStyle(onAmber)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(amber, in: Capsule())
                }
                .buttonStyle(.plain)
                .opacity(email.isEmpty || password.isEmpty ? 0.5 : 1)
                .disabled(email.isEmpty || password.isEmpty)

                if let message {
                    Text(message).font(.kernel(.footnote)).foregroundStyle(.secondary).multilineTextAlignment(.center)
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
                .font(.kernel(.footnote)).foregroundStyle(.secondary)
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
                Button { run { try await auth.setMetadata(["avatar": .string(AvatarArt.svg()), "avatar_source": .string("generated")]); return nil } } label: {
                    AvatarView(svg: generated ? auth.user?.userMetadata["avatar"]?.stringValue : (linkedPhoto == nil ? AvatarArt.svg(seed: auth.user?.email ?? "") : nil),
                               initial: String(auth.user?.email?.first ?? "?"), photo: generated ? nil : linkedPhoto)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Generate a new avatar")
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Username", text: $username, onCommit: saveUsername)
                        .font(.kernel(.headline))
                        .labelsHidden().textFieldStyle(.plain)   // the Mac grouped form would split it into label and field
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .onSubmit(saveUsername)
                        #endif
                    Text("bookrank.jaybulb.com/profile?u=\(auth.handle)").font(.kernel(.caption2)).foregroundStyle(.secondary)
                    Text("Tap the avatar for a new one.").font(.kernel(.caption2)).foregroundStyle(.tertiary)
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
            let gr = Goodreads.shared
            if let d = gr.data {
                LabeledContent("Signed in", value: "\(d.shelves["read"]?.count ?? 0) read · \(d.shelves["currently-reading"]?.count ?? 0) reading")
                Button(gr.syncing ? "Syncing…" : "Sync now", systemImage: "arrow.triangle.2.circlepath") {
                    Task { await gr.sync(); await store.loadGoodreads(auth.user?.userMetadata["goodreads"]?.stringValue) }
                }
                .disabled(gr.syncing)
                Button("Sign out of Goodreads", role: .destructive) {
                    Task { await gr.signOut(); await store.loadGoodreads(auth.user?.userMetadata["goodreads"]?.stringValue) }
                }
            } else {
                Button("Sign in to Goodreads", systemImage: "person.badge.key") { showGoodreads = true }
            }
            if let e = gr.error { Text(e).font(.kernel(.footnote)).foregroundStyle(.secondary) }
            TextField("Goodreads profile link", text: $goodreads, onCommit: saveGoodreads)
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                #endif
        } header: {
            Text("Goodreads")
        } footer: {
            Text("Opens Goodreads' own sign-in. Shelves, ratings, reviews and progress are read on this device; your Goodreads login never reaches Kernel.")
        }
        .onAppear { goodreads = auth.user?.userMetadata["goodreads"]?.stringValue.map { "goodreads.com/user/show/\($0)" } ?? "" }
        .task {
            guard let id = auth.user?.userMetadata["goodreads"]?.stringValue, goodreadsProfile == nil else { return }
            let meta = await goodreadsMeta(id)
            if !meta.isEmpty { try? await auth.setMetadata(meta) }
        }

        Section {
            if let usage {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: usage.monthFraction)
                    Text(usage.chaptersLeft == 0 ? "Natural voices are used up for now. The device voice takes over."
                         : "About \(usage.chaptersLeft) chapters of natural voice left").font(.kernel(.subheadline))
                }
            } else {
                Text("Checking natural voice usage").foregroundStyle(.secondary)
            }
        } header: {
            Text("Natural voices")
        } footer: {
            Text("A chapter is about 2,500 characters. The month resets on the 1st. Chapters you already played are free to replay.")
        }
        .task { usage = await Narrator.usage() }

        Section { appearancePicker }

        Section {
            Toggle("Daily review nudge", isOn: Binding(get: { nudge }, set: { on in
                Task { nudge = await Nudge.enable(on, entries: store.summaryIndex) }
            }))
            Picker("Weekly goal", selection: Binding(get: { Goal.shared.target }, set: { m in Task { await Goal.shared.set(m) } })) {
                Text("Off").tag(0)
                ForEach([15, 30, 60, 120], id: \.self) { Text("\($0) min").tag($0) }
            }
        } footer: {
            Text("At 9:00 each morning, one of your highlights or a line from a book you summarized; tap it to open the book. With a weekly goal, one reminder at the end of the week if you are behind. Nothing leaves this device.")
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
            SecureField("New password", text: $newPassword, prompt: Text("8+ characters")).textContentType(.newPassword)
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

/// 8-bit book avatar: one of three 16x16 sprites in house colours. Same templates and output as
/// avatarSVG in profile.html. With `seed` (the email) it is the same book every time: the default.
enum AvatarArt {
    static let books: [[String]] = [
            ["................", "...DCCCCCCCCCC..", "...DCCCCCCCCCCP.", "...DCCCCCCCCCCP.", "...DCCTTTTTTCCP.", "...DCCTTTTTTCCP.", "...DCCCCCCCCCCP.", "...DCCCCTTCCCCP.", "...DCCCCCCCCCCP.", "...DCCCCCCCCCCP.", "...DCCCCCCCCCCP.", "...DCCCCCCCCCCP.", "...DCCCCCCCCCCP.", "...DDDDDDDDDDDP.", "....PPPPPPPPPPP.", "................"],
            ["................", "................", "................", "...DCCCCCCCCCD..", "...DCTTTTTTTCD..", "...DCCCCCCCCCD..", ".....FEEEEEEEEEF", ".....FETTTTTTTEF", ".....FEEEEEEEEEF", ".HGGGGGGGGGGGH..", ".HGTTTTTTTTTGH..", ".HGGGGGGGGGGGH..", "..HGGGGGGGGGGGH.", "..HGTTTTTTTTTGH.", "..HGGGGGGGGGGGH.", "................"],
            ["................", "................", "................", "..PPPPP..PPPPP..", ".PPPPPPDDPPPPPP.", ".PLLLLPDDPLLLLP.", ".PPPPPPDDPPPPPP.", ".PLLLPPDDPPLLLP.", ".PPPPPPDDPPPPPP.", ".PLLLLPDDPLLLLP.", ".PPPPPPDDPPPPPP.", ".PLLLPPDDPPLLLP.", "CCCCCCCDDCCCCCCC", ".CCCCCCCCCCCCCC.", "................", "................"]
        ]
    static func svg(seed: String? = nil) -> String {
        var h: UInt32 = 2166136261
        if let seed { for c in seed.utf16 { h = (h ^ UInt32(c)) &* 16777619 } }
        func rand() -> Double {
            guard seed != nil else { return Double.random(in: 0..<1) }
            h = (h ^ (h >> 15)) &* 2246822507; return Double(h % 10007) / 10007
        }
        func pick<T>(_ a: [T]) -> T { a[Int(rand() * Double(a.count))] }
        let covers = [["#c0392b", "#7f1d1d"], ["#1d3557", "#0f1d33"], ["#2d6a4f", "#1b4332"], ["#a56200", "#6b3f00"], ["#222222", "#000000"], ["#b5502c", "#7a3519"]]
        let rows = pick(books), c = pick(covers), e = pick(covers), g = pick(covers)
        let fill: [Character: String] = ["C": c[0], "D": c[1], "E": e[0], "F": e[1], "G": g[0], "H": g[1], "P": "#f4ecd8", "T": "#f5e6b8", "L": "#b9ad94"]
        var rects = ""
        for (y, row) in rows.enumerated() { for (x, k) in row.enumerated() { if let f = fill[k] { rects += "<rect x=\"\(x * 4)\" y=\"\(y * 4)\" width=\"4\" height=\"4\" fill=\"\(f)\"/>" } } }
        let ground = pick(["#f4f1ea", "#fdf6e3", "#eef2f0", "#f6efe9", "#1c1c1e"])
        return "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 64 64\" shape-rendering=\"crispEdges\"><rect width=\"64\" height=\"64\" fill=\"\(ground)\"/>\(rects)</svg>"
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
                    for r in art.rects { ctx.fill(Path(CGRect(x: r.x * s, y: r.y * s, width: r.w * s, height: r.w * s)), with: .color(r.color)) }
                }
            } else if let photo, let url = URL(string: photo) {
                AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { Color.secondary.opacity(0.15) }
            } else {
                Color.secondary.opacity(0.15)
                Text(initial.uppercased()).font(.kernel(.title2)).foregroundStyle(.secondary)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(.quaternary))
    }

    private struct Art { var bg: Color; var rects: [(x: CGFloat, y: CGFloat, w: CGFloat, color: Color)] }
    private func parse(_ svg: String) -> Art? {
        let re = try! NSRegularExpression(pattern: #"<rect (?:x="(\d+)" y="(\d+)" )?width="(\d+)" height="(\d+)" fill="(#[0-9a-fA-F]+)""#)
        let ns = svg as NSString
        var art = Art(bg: .black, rects: [])
        for m in re.matches(in: svg, range: NSRange(location: 0, length: ns.length)) {
            let hex = ns.substring(with: m.range(at: 5))
            if m.range(at: 1).location == NSNotFound { art.bg = Color(hex: hex) }
            else { art.rects.append((CGFloat(Int(ns.substring(with: m.range(at: 1)))!), CGFloat(Int(ns.substring(with: m.range(at: 2)))!), CGFloat(Int(ns.substring(with: m.range(at: 3)))!), Color(hex: hex))) }
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
