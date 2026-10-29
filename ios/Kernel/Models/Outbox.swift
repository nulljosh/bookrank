import Foundation

/// Saves made with no connection (a note, a collection, a highlight, where you stopped), kept on disk and sent
/// when the connection is back. Later changes to the same book merge into one save, newest field wins.
@MainActor enum Outbox {
    private static let file = URL.applicationSupportDirectory.appending(path: "outbox.json")
    private static var pending: [String: [String: Any]] = {
        guard let d = try? Data(contentsOf: file), let o = try? JSONSerialization.jsonObject(with: d) as? [String: [String: Any]] else { return [:] }
        return o
    }()
    private static var flushing = false

    static var count: Int { pending.count }

    static func add(_ path: String, _ fields: [String: Any]) {
        pending[path, default: [:]].merge(fields) { _, new in new }
        write()
    }

    /// Sends what is waiting, oldest problem first; anything that still fails stays for next time.
    static func flush() async {
        guard !flushing, !pending.isEmpty else { return }
        flushing = true; defer { flushing = false }
        for (path, saved) in pending {
            var fields = saved
            // A listening place that waited offline loses to one another device reached later.
            if let l = fields["listen"], let d = try? JSONSerialization.data(withJSONObject: l), let q = try? JSONDecoder().decode(ListenState.self, from: d) {
                struct Row: Decodable { let listen: ListenState? }
                let server = (try? await API.call("GET", path + "&select=listen")).flatMap { try? JSONDecoder().decode([Row].self, from: $0).first?.listen }
                if let e = try? JSONEncoder().encode(ListenState.catchUp(q, server: server)), let j = try? JSONSerialization.jsonObject(with: e) { fields["listen"] = j }
            }
            guard (try? await API.call("PATCH", path, json: fields)) != nil else { continue }
            pending[path] = nil
        }
        write()
    }

    private static func write() {
        if pending.isEmpty { try? FileManager.default.removeItem(at: file); return }
        if let d = try? JSONSerialization.data(withJSONObject: pending) { try? d.write(to: file, options: .atomic) }
    }
}
