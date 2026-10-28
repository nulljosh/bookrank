import Foundation
import Security
import Supabase

/// Stores the Supabase session in the **data-protection** keychain.
///
/// supabase-swift's default `KeychainLocalStorage` never sets
/// `kSecUseDataProtectionKeychain`, so on macOS the session lands in the legacy
/// file-based login keychain. Items there carry an ACL bound to the signing
/// identity, and a fresh download from the App Store does not match the ACL of
/// whatever wrote the item — so macOS puts up the "…wants to use your
/// confidential information stored in your keychain" modal and demands the
/// user's login password.
///
/// App Review hit exactly that on Lexly Mac 1.1.3 and rejected it under
/// Guideline 2.1(a): "we were unable to bypass the keychain request to access
/// the app." A reviewer has no login password to give, so the app is
/// unenterable.
///
/// The data-protection keychain is scoped by the app's own entitlements rather
/// than by an ACL, so it never prompts. It is the default on iOS already; this
/// makes macOS behave the same way.
struct SessionKeychainStorage: AuthLocalStorage {
    private let service = "supabase.gotrue.swift"

    private func query(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }

    func store(key: String, value: Data) throws {
        var attributes = query(forKey: key)
        attributes[kSecValueData as String] = value
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(attributes as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let update = [kSecValueData as String: value]
            try check(SecItemUpdate(query(forKey: key) as CFDictionary, update as CFDictionary))
        } else {
            try check(status)
        }
    }

    func retrieve(key: String) throws -> Data? {
        var attributes = query(forKey: key)
        attributes[kSecReturnData as String] = kCFBooleanTrue
        attributes[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(attributes as CFDictionary, &result)
        // A missing session is the normal signed-out state, not an error — the
        // caller must be able to fall through to the sign-in screen.
        if status == errSecItemNotFound { return nil }
        try check(status)
        return result as? Data
    }

    func remove(key: String) throws {
        let status = SecItemDelete(query(forKey: key) as CFDictionary)
        if status == errSecItemNotFound { return }
        try check(status)
    }

    private func check(_ status: OSStatus) throws {
        guard status != errSecSuccess else { return }
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
    }
}
