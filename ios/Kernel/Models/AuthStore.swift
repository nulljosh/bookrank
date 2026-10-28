import AuthenticationServices
import CryptoKit
import Foundation
import LocalAuthentication

/// Sign-in against jaybulb-api, the same account as the web (Supabase until 1.3; those
/// sessions are dead, so the first launch after the update asks once). Email and password,
/// and Sign in with Apple, which Guideline 4.8 requires alongside any other provider.
@Observable
@MainActor
final class AuthStore {
    var user: User?
    /// True until the stored session has been read back, so the UI can hold still
    /// instead of flashing the signed-out state on every cold launch.
    var isLoading = true

    /// Screenshot automation must not sit at a sign-in wall. It reports signed-in with
    /// no session, which is safe because every summary read needs a token and simply returns nothing.
    private let mockSignedIn = CommandLine.flag("UITEST_SNAPSHOT")

    var isSignedIn: Bool { mockSignedIn || user != nil }

    init() {
        if mockSignedIn {
            isLoading = false
            return
        }
        Task { @MainActor in
            if await API.token() != nil, let data = try? await API.call("GET", "/auth/user") {
                user = try? JSONDecoder().decode(User.self, from: data)
            }
            isLoading = false
        }
    }

    func signIn(email: String, password: String) async throws {
        user = try await API.session("/auth/token?grant_type=password", ["email": email, "password": password])
        saveBiometricCredentials(email: email, password: password)
    }

    // MARK: Sign in with Apple
    // Apple returns an identity token bound to a nonce we hash into the request; jaybulb-api checks
    // the token against Apple's public keys and this bundle id in its audience list.
    private var appleNonce = ""

    func prepareApple(_ request: ASAuthorizationAppleIDRequest) {
        appleNonce = UUID().uuidString + UUID().uuidString
        request.requestedScopes = [.email, .fullName]
        request.nonce = SHA256.hash(data: Data(appleNonce.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    /// Returns false when the person backed out of the Apple sheet, which is not an error.
    func signInWithApple(_ result: Result<ASAuthorization, Error>) async throws -> Bool {
        switch result {
        case .failure(let e as ASAuthorizationError) where e.code == .canceled:
            return false
        case .failure(let e):
            throw e
        case .success(let a):
            guard let cred = a.credential as? ASAuthorizationAppleIDCredential,
                  let data = cred.identityToken, let token = String(data: data, encoding: .utf8) else {
                throw API.Failure(message: "Apple did not return a sign-in token.")
            }
            let name = [cred.fullName?.givenName, cred.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
            var body: [String: Any] = ["provider": "apple", "id_token": token, "nonce": appleNonce]
            if !name.isEmpty { body["full_name"] = name }
            user = try await API.session("/auth/token?grant_type=id_token", body)
            return true
        }
    }

    // MARK: Face ID convenience sign-in
    // Optional shortcut for a returning user, not a new provider.
    private static let savedEmailKey = "bookrank.biometric.email"

    func hasSavedBiometricCredentials() -> Bool {
        guard let email = UserDefaults.standard.string(forKey: Self.savedEmailKey) else { return false }
        return KeychainHelper.load(key: email) != nil
    }

    func biometricLogin() async throws {
        let context = LAContext()
        try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Sign in to Kernel")
        guard let email = UserDefaults.standard.string(forKey: Self.savedEmailKey),
              let data = KeychainHelper.load(key: email),
              let password = String(data: data, encoding: .utf8) else {
            throw API.Failure(message: "No saved sign-in found.")
        }
        try await signIn(email: email, password: password)
    }

    private func saveBiometricCredentials(email: String, password: String) {
        guard let data = password.data(using: .utf8) else { return }
        UserDefaults.standard.set(email, forKey: Self.savedEmailKey)
        KeychainHelper.save(key: email, data: data)
    }

    private func clearBiometricCredentials() {
        if let email = UserDefaults.standard.string(forKey: Self.savedEmailKey) {
            KeychainHelper.delete(key: email)
        }
        UserDefaults.standard.removeObject(forKey: Self.savedEmailKey)
    }

    /// Always false: a new email account confirms by mail before it can sign in, and the caller says so.
    func signUp(email: String, password: String) async throws -> Bool {
        _ = try await API.call("POST", "/auth/signup", json: ["email": email, "password": password,
                                                             "redirect_to": "https://bookrank.jaybulb.com/library.html"], authed: false)
        return false
    }

    func signOut() async throws {
        _ = try? await API.call("POST", "/auth/logout", json: [String: Any]())
        API.forget()
        user = nil
        clearBiometricCredentials()
    }

    /// Username shown on the profile: saved one, else the email's local part (same rule as profile.html).
    var handle: String {
        let raw = user?.userMetadata["username"]?.stringValue ?? user?.email?.components(separatedBy: "@").first ?? ""
        return raw.lowercased().filter { $0.isLetter || $0.isNumber || "._-".contains($0) }
    }
    func setMetadata(_ data: [String: AnyJSON]) async throws {
        user = try JSONDecoder().decode(User.self, from: try await API.call("PUT", "/auth/user", json: ["data": data.mapValues(\.plain)]))
    }
    /// A new email only takes over once its confirmation link is opened.
    func updateCredentials(email: String?, password: String?) async throws {
        var body: [String: Any] = ["redirect_to": "https://bookrank.jaybulb.com/profile.html"]
        if let email { body["email"] = email }
        if let password { body["password"] = password }
        user = try JSONDecoder().decode(User.self, from: try await API.call("PUT", "/auth/user", json: body))
    }

    func resetPassword(email: String) async throws {
        _ = try await API.call("POST", "/auth/recover", json: ["email": email, "redirect_to": "https://bookrank.jaybulb.com/profile.html"], authed: false)
    }

    /// Guideline 5.1.1(v): an app offering account creation must offer account deletion.
    /// jaybulb-api removes the user and their rows.
    func deleteAccount() async throws {
        _ = try await API.call("DELETE", "/auth/user")
        API.forget()
        user = nil
        clearBiometricCredentials()
    }
}
