import AVFoundation
import SwiftUI
import Observation

/// Chapter player over AVSpeechSynthesizer. Mirrors listen.js: "Explain it" fetches a
/// two-host script per chapter from /api/narrate, "Read" speaks the markdown block by block.
/// The next chapter's script is fetched while the current one plays, the spoken line and
/// word are published for the transcript to highlight, and the resume point + scripts are
/// saved on the summary row so the web and the apps pick up at the same line.
/// ponytail: on-device voices only, no audio files.
@Observable
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    struct Chapter { let title: String; let text: String }
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()

    private(set) var slug: String?
    private(set) var chapters: [Chapter] = []
    private(set) var ch = 0
    private(set) var line = 0
    private(set) var lines: [ListenState.Line] = []   // the chapter on screen
    private(set) var word: Range<Int>?                 // within lines[line].line
    private(set) var playing = false
    private(set) var paused = false
    private(set) var loading = false
    /// Two hosts talk the chapter through; on by default and remembered. The signed-out sample has no script to build, so it reads the notes.
    var explain: Bool = UserDefaults.standard.object(forKey: "bookrank.explain") as? Bool ?? true {
        didSet { UserDefaults.standard.set(explain, forKey: "bookrank.explain"); if playing { Task { await play(from: 0) } } else { Task { await showChapter() } } }
    }
    private var talks: Bool { explain && slug != "sample" }
    /// Steps people actually use, from a slow read to a fast skim. 2x is the ceiling both the device voice and the player allow.
    /// AVSpeech's scale is not linear: the raw max (1.0) is about three times normal speech. This maps 1x to the default and 2x
    /// to a brisk 0.65, so a 2x on the device voice sounds like 2x.
    static func deviceRate(_ r: Float) -> Float {
        let d = AVSpeechUtteranceDefaultSpeechRate
        return r <= 1 ? d * r : min(AVSpeechUtteranceMaximumSpeechRate, d + (r - 1) * 0.15)
    }
    static let speeds: [Float] = [0.75, 0.9, 1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.75, 2]
    /// Remembered per book (a dense text slows down, a story speeds up), falling back to the last speed you picked anywhere.
    var rate: Float = UserDefaults.standard.object(forKey: "bookrank.rate") as? Float ?? 1 {
        didSet {
            UserDefaults.standard.set(rate, forKey: "bookrank.rate")
            if let slug { UserDefaults.standard.set(rate, forKey: "bookrank.rate.\(slug)") }
            if playing { Task { await play(from: line) } }
        }
    }
    var status = ""
    /// Natural voices (ElevenLabs through /api/speak). Off, or any failed line, falls back to the device voice.
    var natural: Bool = UserDefaults.standard.object(forKey: "bookrank.natural") as? Bool ?? true {
        didSet { UserDefaults.standard.set(natural, forKey: "bookrank.natural"); if playing { Task { await play(from: line) } } }
    }
    private var player: AVAudioPlayer?
    /// 0...1 across the book; chapters weigh the same because unfetched ones have no line count.
    var progress: Double {
        guard !chapters.isEmpty else { return 0 }
        let within = lines.isEmpty ? 0 : Double(min(line, lines.count)) / Double(lines.count)
        return min(1, (Double(ch) + within) / Double(chapters.count))
    }

    private var scripts: [String: [ListenState.Line]] = [:]
    private var prefetch: [Int: Task<[ListenState.Line]?, Never>] = [:]
    private var updatedAt = ""
    private var save: ((ListenState) async -> Void)?
    private var lineOf: [ObjectIdentifier: (line: Int, offset: Int)] = [:]
    private var lastUtterance: AVSpeechUtterance?
    private var token = 0

    override private init() { super.init(); synth.delegate = self }

    /// Bind to a summary. Restores the saved position when the content is unchanged.
    func load(slug: String, chapters: [Chapter], entry: SummaryEntry?, save: @escaping (ListenState) async -> Void) {
        if self.slug == slug { return }
        stop()
        self.slug = slug; self.chapters = chapters; self.save = save
        if let r = UserDefaults.standard.object(forKey: "bookrank.rate.\(slug)") as? Float { rate = r }
        updatedAt = entry?.updatedAt ?? ""
        let st = entry?.listen.flatMap { $0.for == updatedAt ? $0 : nil }
        scripts = st?.chapters ?? [:]; prefetch = [:]
        ch = min(st?.pos.ch ?? 0, max(0, chapters.count - 1)); line = st?.pos.line ?? 0
        status = st.map { _ in "Resume at \(chapters[ch].title)" } ?? ""
        Task { await showChapter() }
    }

    /// Play / pause. Pausing while a script is still loading cancels the load.
    func toggle() {
        if loading { stop(); return }
        if playing && !paused { if let p = player { p.pause() } else { synth.pauseSpeaking(at: .word) }; paused = true; persist(); return }
        if paused { if let p = player { p.play() } else { synth.continueSpeaking() }; paused = false; return }
        Task { await play(from: line) }
    }
    func skip(_ delta: Int) {
        guard !chapters.isEmpty else { return }
        ch = max(0, min(chapters.count - 1, ch + delta)); line = 0
        Task { await play(from: 0) }
    }
    /// Show a chapter without speaking it.
    func open(_ chapter: Int) { stop(); ch = chapter; line = 0; Task { await showChapter() } }
    func go(to chapter: Int, line l: Int = 0) { ch = chapter; line = l; Task { await play(from: l) } }

    func stop() {
        token += 1
        let was = playing || loading
        synth.stopSpeaking(at: .immediate); player?.stop(); player = nil
        playing = false; paused = false; loading = false; lineOf = [:]; word = nil
        if was { persist() }
    }

    private func persist() {
        guard let save else { return }
        let st = ListenState(for: updatedAt, chapters: scripts, pos: .init(ch: ch, line: line))
        Task { await save(st) }
    }

    // ponytail: same block rule as listen.js blocks(): paragraphs join, list items and
    // headings stand alone, rules drop. `line` is spoken, `md` is rendered.
    static func blocks(_ md: String) -> [ListenState.Line] {
        var out: [String] = []
        var open = false
        for raw in md.components(separatedBy: "\n") {
            let t = raw.trimmingCharacters(in: .whitespaces)
            if t.isEmpty || t.allSatisfy({ $0 == "-" }) { open = false; continue }
            let special = t.hasPrefix("- ") || t.hasPrefix("* ") || t.hasPrefix("#") || t.range(of: "^\\d+\\. ", options: .regularExpression) != nil
            if special || !open { out.append(t); open = !special } else { out[out.count - 1] += " " + t }
        }
        return out.map { .init(host: "A", line: plain($0), md: $0) }
    }
    static func plain(_ md: String) -> String {
        md.replacingOccurrences(of: "^([-*]|\\d+\\.) ", with: "", options: .regularExpression)
          .replacingOccurrences(of: "[#*_`>\\[\\]()]", with: " ", options: .regularExpression)
          .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
          .trimmingCharacters(in: .whitespaces)
    }

    private func script(for i: Int) -> Task<[ListenState.Line]?, Never> {
        if let t = prefetch[i] { return t }
        let t = Task<[ListenState.Line]?, Never> { [talks = talks, chapters] in
            guard i < chapters.count else { return nil }
            if !talks { return Self.blocks(chapters[i].text) }
            if let s = scripts["\(i)"] { return s }
            if let s = await Narrator.narrate(text: chapters[i].text, title: chapters[i].title, ch: i, total: chapters.count) {
                scripts["\(i)"] = s; return s
            }
            return nil
        }
        prefetch[i] = t
        return t
    }
    func invalidateScripts() { prefetch = [:] }

    /// Idle view: the current chapter's text, no audio.
    @MainActor
    private func showChapter() async {
        guard ch < chapters.count else { lines = []; return }
        lines = (talks ? scripts["\(ch)"] : nil) ?? Self.blocks(chapters[ch].text)
    }

    @MainActor
    private func play(from: Int) async {
        token += 1; let tok = token
        synth.stopSpeaking(at: .immediate); player?.stop(); player = nil; lineOf = [:]; paused = false; word = nil
        guard ch < chapters.count else { return }
        playing = true; loading = true
        var got = await script(for: ch).value
        guard tok == token else { return }
        loading = false
        if got == nil { status = "Could not build the conversation; reading the notes."; got = Self.blocks(chapters[ch].text) }
        guard let script = got, !script.isEmpty else { playing = false; return }
        lines = script
        if ch + 1 < chapters.count { _ = self.script(for: ch + 1) } // warm the next chapter
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        let a = AVSpeechSynthesisVoice(language: Locale.current.identifier) ?? AVSpeechSynthesisVoice(language: "en-US")
        let b = AVSpeechSynthesisVoice.speechVoices().first { $0.language == a?.language && $0.identifier != a?.identifier } ?? a
        line = min(from, script.count - 1)
        if natural {
            if await playNatural(script, from: line, tok: tok) { return }
            guard tok == token else { return }   // a line failed: keep going on the device voice from there
            status = "Natural voice unavailable (\(Narrator.lastFailure ?? "unknown")). Using the device voice."
        }
        for (k, l) in script[line...].enumerated() {
            let u = AVSpeechUtterance(string: l.line)
            u.voice = l.host == "B" ? b : a
            u.rate = Self.deviceRate(rate)
            lineOf[ObjectIdentifier(u)] = (line + k, 0)
            if line + k == script.count - 1 { lastUtterance = u }
            synth.speak(u)
        }
    }

    /// One line at a time: fetch the clip (the next one downloads while this one plays), play it, and
    /// light each word at the moment the server says it is spoken. True = handled to the end or stopped;
    /// false = a line could not be fetched or played, `line` is where the device voice should pick up.
    @MainActor
    private func playNatural(_ script: [ListenState.Line], from start: Int, tok: Int) async -> Bool {
        var next = Task { await Narrator.speak(script[start].line, host: script[start].host, ch: ch) }
        for i in start..<script.count {
            guard tok == token else { return true }
            let clip = await next.value
            guard tok == token else { return true }
            guard let clip, let p = try? AVAudioPlayer(data: clip.audio) else { line = i; return false }
            if i + 1 < script.count { let n = script[i + 1]; next = Task { await Narrator.speak(n.line, host: n.host, ch: ch) } }
            line = i; word = nil
            status = "\(chapters[ch].title) · \(i + 1)/\(lines.count)"
            player = p; p.enableRate = true; p.rate = rate; p.play()
            var w = 0
            while p.isPlaying || paused {
                guard tok == token else { p.stop(); return true }
                while w < clip.words.count, clip.words[w].t <= p.currentTime { let x = clip.words[w]; word = x.i ..< (x.i + x.n); w += 1 }
                try? await Task.sleep(for: .milliseconds(30))
            }
        }
        guard tok == token else { return true }
        player = nil
        if ch + 1 < chapters.count { ch += 1; line = 0; Task { await play(from: 0) } }
        else { line = 0; playing = false; word = nil; status = "Finished."; persist() }
        return true
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart u: AVSpeechUtterance) {
        if let i = lineOf[ObjectIdentifier(u)]?.line { line = i; word = nil; status = "\(chapters[ch].title) · \(i + 1)/\(lines.count)" }
    }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, willSpeakRangeOfSpeechString r: NSRange, utterance u: AVSpeechUtterance) {
        guard lineOf[ObjectIdentifier(u)] != nil else { return }
        word = r.location ..< (r.location + r.length)
    }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        guard u === lastUtterance, playing else { return }
        if ch + 1 < chapters.count { ch += 1; line = 0; Task { await play(from: 0) } }
        else { line = 0; playing = false; word = nil; status = "Finished."; persist() }
    }
}

enum Narrator {
    static func narrate(text: String, title: String, ch: Int, total: Int) async -> [ListenState.Line]? {
        guard let token = try? await supabase.auth.session.accessToken else { return nil }
        var req = URLRequest(url: URL(string: "https://bookrank.heyitsmejosh.com/api/narrate")!)
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
        guard let token = try? await supabase.auth.session.accessToken else { return nil }
        var req = URLRequest(url: URL(string: "https://bookrank.heyitsmejosh.com/api/usage")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        guard let (data, resp) = try? await URLSession.shared.data(for: req), (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return try? JSONDecoder().decode(VoiceUsage.self, from: data)
    }
}

extension Narrator {
    /// One line in a natural voice: mp3 plus the second each word starts. Nil on any failure, so the caller can fall back.
    /// Why the last natural line failed, in the server's own words when it gave any, so the player can say so.
    nonisolated(unsafe) static var lastFailure: String?

    static func speak(_ text: String, host: String, ch: Int) async -> (audio: Data, words: [WordTime])? {
        // One retry: a dropped connection or a 5xx from the voice service is usually gone a second later.
        for attempt in 0..<2 {
            if attempt > 0 { try? await Task.sleep(for: .milliseconds(700)) }
            guard let token = try? await supabase.auth.session.accessToken else { lastFailure = "not signed in"; return nil }
            var req = URLRequest(url: URL(string: "https://bookrank.heyitsmejosh.com/api/speak")!)
            req.httpMethod = "POST"
            req.timeoutInterval = 25
            req.setValue("application/json", forHTTPHeaderField: "content-type")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
            #if os(macOS)
            req.setValue("mac", forHTTPHeaderField: "x-bookrank-app")  // the App Store price is what pays for the voices
            #else
            req.setValue("ios", forHTTPHeaderField: "x-bookrank-app")  // the App Store price is what pays for the voices
            #endif
            req.httpBody = try? JSONSerialization.data(withJSONObject: ["text": text, "host": host, "ch": ch])
            struct Out: Decodable { let audio: String; let words: [WordTime] }
            struct Err: Decodable { let error: String? }
            guard let (data, resp) = try? await URLSession.shared.data(for: req), let code = (resp as? HTTPURLResponse)?.statusCode else {
                lastFailure = "no connection"; continue
            }
            if code == 200, let out = try? JSONDecoder().decode(Out.self, from: data), let audio = Data(base64Encoded: out.audio) {
                lastFailure = nil
                return (audio, out.words)
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
            Button("Previous chapter", systemImage: "backward.end") { speaker.skip(-1) }
            Button("Next chapter", systemImage: "forward.end") { speaker.skip(1) }
            Divider()
            Picker("Speed", selection: Binding(get: { speaker.rate }, set: { speaker.rate = $0 })) {
                ForEach(Speaker.speeds, id: \.self) { Text("\(($0 * 100).rounded() / 100, specifier: "%g")×").tag($0) }
            }
            Toggle("Natural voices", isOn: Binding(get: { speaker.natural }, set: { speaker.natural = $0 }))
            Toggle("Explain it (two hosts)", isOn: Binding(get: { speaker.explain }, set: { speaker.explain = $0; speaker.invalidateScripts() }))
        }
    }
}
