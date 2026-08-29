import SwiftUI

/// Sign in, sign up, and account deletion.
///
/// Auth is optional on purpose: the rankings, library and picks are all bundled and
/// readable signed-out. Signing in only adds your own summaries. An app that shows a
/// stranger nothing but a login wall is the Guideline 4.2 risk this avoids.
struct AccountView: View {
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

    var body: some View {
        NavigationStack {
            Form {
                if auth.isSignedIn {
                    signedIn
                } else {
                    signedOut
                }
                if let message {
                    Section { Text(message).font(.footnote).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle(auth.isSignedIn ? "Account" : (isSigningUp ? "Create account" : "Sign in"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .disabled(busy)
        }
    }

    // MARK: - Signed out

    @ViewBuilder
    private var signedOut: some View {
        Section {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                #if os(iOS)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
            SecureField("Password", text: $password)
                .textContentType(isSigningUp ? .newPassword : .password)
        } footer: {
            Text("Your summaries live in your account. Everything else in the app works signed out.")
        }

        Section {
            Button(isSigningUp ? "Create account" : "Sign in") {
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
            }
            .disabled(email.isEmpty || password.isEmpty)

            Button(isSigningUp ? "I already have an account" : "Create an account") {
                isSigningUp.toggle()
                message = nil
            }

            if !isSigningUp {
                Button("Send password reset") {
                    run {
                        try await auth.resetPassword(email: email)
                        return "Reset link sent to \(email)."
                    }
                }
                .disabled(email.isEmpty)
            }
        }
    }

    // MARK: - Signed in

    @ViewBuilder
    private var signedIn: some View {
        Section {
            LabeledContent("Email", value: auth.user?.email ?? "—")
            LabeledContent("Summaries", value: "\(store.summaryIndex.count)")
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
            Text("Deletes your account and every summary in it, immediately and permanently. There is no undo and no export.")
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
