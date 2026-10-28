import AVFoundation
import CryptoKit
import SwiftUI
import Observation

enum Narrator {
    static func narrate(text: String, title: String, ch: Int, total: Int) async -> [ListenState.Line]? {
        guard let token = await API.token() else { return nil }
        var req = URLRequest(url: URL(string: "https://bookrank.jaybulb.com/api/narrate")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["text": text, "title": title, "ch": ch, "total": total])
        struct Out: Decodable { let script: [ListenState.Line]? }
        guard let (data, _) = try? await URLSession.shared.data(for: req) else { return nil }
        return (try? JSONDecoder().decode(Out.self, from: data))?.script
    }
}

struct WordTime: Decodable { let i: Int; let n: Int; let t: Double }

/// What the natural voices have used, from /api/usage. About 2,500 characters is a chapter.
struct VoiceUsage: Decodable {
    struct You: Decodable { let day: Int; let month: Int }
    struct App: Decodable { let month: Int }
    struct Caps: Decodable { let day: Int; let month: Int }
    let you: You, app: App, caps: Caps, chapter: Int
    /// The month is shared by the whole app, the day is yours; the smaller room is the one that bites first.
    var chaptersLeft: Int { max(0, min(caps.month - app.month, caps.day - you.day)) / max(chapter, 1) }
    var monthFraction: Double { min(1, Double(app.month) / Double(max(caps.month, 1))) }
}

extension Narrator {
    static func usage() async -> VoiceUsage? {
        guard let token = await API.token() else { return nil }
        var req = URLRequest(url: URL(string: "https://bookrank.jaybulb.com/api/usage")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req), (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try? JSONDecoder().decode(VoiceUsage.self, from: data)
    }
}

extension Narrator {
    /// One line in a natural voice: mp3 plus the second each word starts. Nil on any failure, so the caller can fall back.
    /// Why the last natural line failed, in the server's own words when it gave any, so the player can say so.
    nonisolated(unsafe) static var lastFailure: String?

    /// A downloaded book's voice lines: one file per line, named by a hash of host and text.
    static func offlineDir(_ slug: String) -> URL { URL.applicationSupportDirectory.appending(path: "voice/\(slug)") }
    private static func lineFile(_ text: String, _ host: String, _ slug: String) -> URL {
        let h = SHA256.hash(data: Data("\(host)|\(text)".utf8)).map { String(format: "%02x", $0) }.joined()
        return offlineDir(slug).appending(path: "\(h).json")
    }
    private struct Out: Decodable { let audio: String; let words: [WordTime] }
    private static func clip(_ data: Data) -> (audio: Data, words: [WordTime])? {
        guard let out = try? JSONDecoder().decode(Out.self, from: data), let audio = Data(base64Encoded: out.audio) else { return nil }
        return (audio, out.words)
    }

    /// With `slug`, a line already on the device plays from there, and a fetched one is kept when that book is downloading or downloaded.
    static func speak(_ text: String, host: String, ch: Int, slug: String? = nil) async -> (audio: Data, words: [WordTime])? {
        let file = slug.map { lineFile(text, host, $0) }
        if let file, let d = try? Data(contentsOf: file), let c = clip(d) { return c }
        // One retry: a dropped connection or a 5xx from the voice service is usually gone a second later.
        for attempt in 0..<2 {
            if attempt > 0 { try? await Task.sleep(for: .milliseconds(700)) }
            guard let token = await API.token() else { lastFailure = "not signed in"; return nil }
            var req = URLRequest(url: URL(string: "https://bookrank.jaybulb.com/api/speak")!)
            req.httpMethod = "POST"
            req.timeoutInterval = 25
            req.setValue("application/json", forHTTPHeaderField: "content-type")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
            // The App Store price is what pays for the voices: Apple's signed proof of this copy.
            if let proof = await API.receipt() { req.setValue(proof, forHTTPHeaderField: "x-kernel-receipt") }
            req.httpBody = try? JSONSerialization.data(withJSONObject: ["text": text, "host": host, "ch": ch])
            struct Err: Decodable { let error: String? }
            guard let (data, resp) = try? await URLSession.shared.data(for: req), let code = (resp as? HTTPURLResponse)?.statusCode else {
                lastFailure = "no connection"; continue
            }
            if code == 200, let c = clip(data) {
                lastFailure = nil
                if let file, let slug, FileManager.default.fileExists(atPath: offlineDir(slug).path) { try? data.write(to: file) }
                return c
            }
            lastFailure = (try? JSONDecoder().decode(Err.self, from: data))?.error ?? "server answered \(code)"
            if code < 500 { return nil }   // 4xx will not change on a retry
        }
        return nil
    }
}

/// Listen button plus one menu for the rest. Drop it in a toolbar.
struct ListenControls: View {
    var speaker = Speaker.shared

    var body: some View {
        Button(speaker.playing && !speaker.paused ? "Pause" : "Listen",
               systemImage: speaker.loading ? "stop.fill" : (speaker.playing && !speaker.paused ? "pause.fill" : "play.fill")) { speaker.toggle() }
            .contentTransition(.symbolEffect(.replace))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: speaker.playing)
        Menu("More", systemImage: "ellipsis.circle") {
            Button("Previous chapter", systemImage: "backward.end") { speaker.skip(-1) }.keyboardShortcut("[", modifiers: .command)
            Button("Next chapter", systemImage: "forward.end") { speaker.skip(1) }.keyboardShortcut("]", modifiers: .command)
            Divider()
            Picker("Speed", selection: Binding(get: { speaker.rate }, set: { speaker.rate = $0 })) {
                ForEach(Speaker.speeds, id: \.self) { Text("\(($0 * 100).rounded() / 100, specifier: "%g")×").tag($0) }
            }
            Toggle("Natural voices", isOn: Binding(get: { speaker.natural }, set: { speaker.natural = $0 }))
            Toggle("Explain it", isOn: Binding(get: { speaker.explain }, set: { speaker.explain = $0; speaker.invalidateScripts() }))
        }
    }
}
