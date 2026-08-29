import Foundation
import Supabase

// Credentials are hardcoded rather than read from Info.plist via $(SUPABASE_URL).
// This project rewrites Info.plist in scripts/prepare-plist.py *after* xcodegen runs,
// and xcodegen already silently drops keys here (see the notes in project.yml), so a
// build-setting substitution has two places to go wrong before anyone notices. The
// anon key is a public client credential — it is in library.html too — and every
// table it can reach is behind RLS.
let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://tjsxsqlxjmanwvmywwvw.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRqc3hzcWx4am1hbnd2bXl3d3Z3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA0OTc0MDEsImV4cCI6MjA4NjA3MzQwMX0.LphLfho3wdQC20MhtcnBpzQUNuBoTOobrugQbNGxc68",
    options: SupabaseClientOptions(
        auth: SupabaseClientOptions.AuthOptions(storage: SessionKeychainStorage())
    )
)

/// Email + password only, deliberately. Adding any third-party provider makes Sign in
/// with Apple mandatory under Guideline 4.8, and the Apple provider is not enabled on
/// the shared `spark` project — shipping a button that always errors is what got a
/// sibling app rejected under 2.1(a).
@Observable
@MainActor
final class AuthStore {
    var user: User?
    /// True until the stored session has been read back, so the UI can hold still
    /// instead of flashing the signed-out state on every cold launch.
    var isLoading = true

    /// Screenshot automation must not sit at a sign-in wall. It reports signed-in with
    /// no session, which is safe because every summary read goes through Supabase and
    /// simply returns nothing.
    private let mockSignedIn = CommandLine.arguments.contains("UITEST_SNAPSHOT")

    var isSignedIn: Bool { mockSignedIn || user != nil }

    init() {
        if mockSignedIn {
            isLoading = false
            return
        }
        Task { @MainActor in
            for await (event, session) in supabase.auth.authStateChanges {
                switch event {
                case .initialSession:
                    // The only event that fires on a cold launch with no stored session,
                    // so it is the only safe place to drop isLoading.
                    user = session?.user
                    isLoading = false
                case .signedIn:
                    user = session?.user
                case .signedOut:
                    user = nil
                default:
                    break
                }
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        // Use the session signIn hands back rather than re-reading `try? auth.session`.
        // The re-read swallows refresh failures and leaves the UI signed-out with no
        // error, which is the "Sign In will load briefly and then stops" defect that
        // got Lexly's Mac build rejected under 2.1(a).
        let session = try await supabase.auth.signIn(email: email, password: password)
        user = session.user
    }

    func signUp(email: String, password: String) async throws -> Bool {
        let result = try await supabase.auth.signUp(email: email, password: password)
        user = result.session?.user
        // False means the project wants an email confirmation first. The caller has to
        // say so, otherwise a successful sign-up looks like nothing happened.
        return result.session != nil
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        user = nil
    }

    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }

    /// Guideline 5.1.1(v): an app offering account creation must offer account deletion.
    ///
    /// Calls the shared `delete-account` Edge Function, which holds the service-role key
    /// and removes the auth user server-side — the anon-key client cannot delete its own
    /// user, and the summaries cascade from the foreign key.
    func deleteAccount() async throws {
        let session = try await supabase.auth.session
        var request = URLRequest(
            url: URL(string: "https://tjsxsqlxjmanwvmywwvw.supabase.co/functions/v1/delete-account")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "AuthStore", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Couldn't delete your account. Try again."
            ])
        }
        try await signOut()
    }
}
