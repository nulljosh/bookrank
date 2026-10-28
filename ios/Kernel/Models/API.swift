import Foundation
import StoreKit

/// The same account and rows as the web: jaybulb-api on Cloudflare (Workers + D1), replacing
/// Supabase (2026-10-28). Email and password, Sign in with Apple, PostgREST-style rows under
/// /rest. The refresh token lives in the Keychain; the short-lived access token stays in memory.
@MainActor
enum API {
    static let base = URL(string: "https://api.jaybulb.com")!
    private static let refreshKey = "kernel.session.refresh"   // KeychainHelper key, not a defaults key
    private static var access: String?
    private static var expires = Date.distantPast

    struct Failure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }
    struct Session: Decodable {
        let access_token: String, refresh_token: String, expires_in: Double?
        let user: User
    }

    /// One request. `authed` attaches a fresh access token and fails when signed out.
    static func call(_ method: String, _ path: String, json body: Any? = nil, authed: Bool = true,
                     prefer: String? = nil) async throws -> Data {
        var r = URLRequest(url: URL(string: path, relativeTo: base)!)
        r.httpMethod = method
        r.setValue("kernel-ios/1.3", forHTTPHeaderField: "User-Agent")   // Cloudflare blocks the default agent
        if let body {
            r.httpBody = try JSONSerialization.data(withJSONObject: body)
            r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let prefer { r.setValue(prefer, forHTTPHeaderField: "Prefer") }
        if authed {
            guard let token = await token() else { throw Failure(message: "Sign in first.") }
            r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, res) = try await URLSession.shared.data(for: r)
        let code = (res as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            struct E: Decodable { let error: String?; let message: String?; let msg: String? }
            let e = try? JSONDecoder().decode(E.self, from: data)
            throw Failure(message: e?.error ?? e?.message ?? e?.msg ?? "The server said \(code).")
        }
        return data
    }

    // MARK: Session

    /// A usable access token, refreshing it from the Keychain when it is missing or about to expire.
    /// Refresh tokens are single use on the server, so concurrent callers share one refresh.
    static func token() async -> String? {
        if let access, expires.timeIntervalSinceNow > 60 { return access }
        if let refreshing { return await refreshing.value }
        let t = Task { () -> String? in
            defer { refreshing = nil }
            guard let data = KeychainHelper.load(key: refreshKey), let refresh = String(data: data, encoding: .utf8),
                  let out = try? await call("POST", "/auth/token?grant_type=refresh_token", json: ["refresh_token": refresh], authed: false),
                  let s = try? JSONDecoder().decode(Session.self, from: out) else { return nil }
            keep(s)
            return s.access_token
        }
        refreshing = t
        return await t.value
    }
    private static var refreshing: Task<String?, Never>?

    /// Stores a new session and returns its user.
    @discardableResult
    static func keep(_ s: Session) -> User {
        access = s.access_token
        expires = Date().addingTimeInterval(s.expires_in ?? 3600)
        KeychainHelper.save(key: refreshKey, data: Data(s.refresh_token.utf8))
        return s.user
    }

    static func forget() {
        access = nil
        expires = .distantPast
        KeychainHelper.delete(key: refreshKey)
    }

    static func session(_ path: String, _ body: [String: Any]) async throws -> User {
        keep(try JSONDecoder().decode(Session.self, from: try await call("POST", path, json: body, authed: false)))
    }

    // MARK: Proof of purchase

    /// StoreKit's signed AppTransaction: the server checks it against Apple's root, so the App Store
    /// price can pay for natural voices. Nil when StoreKit has nothing (simulator, a Debug build).
    static func receipt() async -> String? {
        guard let r = try? await AppTransaction.shared else { return nil }
        if case .verified = r { return r.jwsRepresentation }
        return nil
    }
}

/// The signed-in user, the same shape jaybulb-api returns from /auth/user.
struct User: Decodable, Equatable {
    let id: String
    let email: String?
    let userMetadata: [String: AnyJSON]
    enum CodingKeys: String, CodingKey { case id, email, userMetadata = "user_metadata" }
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        userMetadata = (try? c.decodeIfPresent([String: AnyJSON].self, forKey: .userMetadata)) ?? [:]
    }
}

/// Free-form JSON for user metadata (Goodreads profile, avatar, username).
enum AnyJSON: Codable, Equatable {
    case null, bool(Bool), number(Double), string(String), array([AnyJSON]), object([String: AnyJSON])

    var stringValue: String? { if case .string(let s) = self { return s }; return nil }
    var objectValue: [String: AnyJSON]? { if case .object(let o) = self { return o }; return nil }
    var arrayValue: [AnyJSON]? { if case .array(let a) = self { return a }; return nil }

    init(from d: Decoder) throws {
        let c = try d.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let n = try? c.decode(Double.self) { self = .number(n) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([AnyJSON].self) { self = .array(a) }
        else { self = .object(try c.decode([String: AnyJSON].self)) }
    }
    func encode(to e: Encoder) throws {
        var c = e.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let b): try c.encode(b)
        case .number(let n): try c.encode(n)
        case .string(let s): try c.encode(s)
        case .array(let a): try c.encode(a)
        case .object(let o): try c.encode(o)
        }
    }
    /// For JSONSerialization request bodies.
    var plain: Any {
        switch self {
        case .null: NSNull()
        case .bool(let b): b
        case .number(let n): n
        case .string(let s): s
        case .array(let a): a.map(\.plain)
        case .object(let o): o.mapValues(\.plain)
        }
    }
}
