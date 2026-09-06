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
    var explain = true { didSet { if playing { Task { await play(from: 0) } } else { Task { await showChapter() } } } }
    var rate: Float = UserDefaults.standard.object(forKey: "bookrank.rate") as? Float ?? 1 {
        didSet { UserDefaults.standard.set(rate, forKey: "bookrank.rate"); if playing { Task { await play(from: line) } } }
    }
    var status = ""
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
        if playing && !paused { synth.pauseSpeaking(at: .word); paused = true; persist(); return }
        if paused { synth.continueSpeaking(); paused = false; return }
        Task { await play(from: line) }
    }
    func skip(_ delta: Int) {
        guard !chapters.isEmpty else { return }
        ch = max(0, min(chapters.count - 1, ch + delta)); line = 0
        Task { await play(from: 0) }
    }
    func go(to chapter: Int, line l: Int = 0) { ch = chapter; line = l; Task { await play(from: l) } }

    func stop() {
        token += 1
        let was = playing || loading
        synth.stopSpeaking(at: .immediate)
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
        let t = Task<[ListenState.Line]?, Never> { [explain, chapters] in
            guard i < chapters.count else { return nil }
            if !explain { return Self.blocks(chapters[i].text) }
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
        lines = (explain ? scripts["\(ch)"] : nil) ?? Self.blocks(chapters[ch].text)
    }

    @MainActor
    private func play(from: Int) async {
        token += 1; let tok = token
        synth.stopSpeaking(at: .immediate); lineOf = [:]; paused = false; word = nil
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
        for (k, l) in script[line...].enumerated() {
            let u = AVSpeechUtterance(string: l.line)
            u.voice = l.host == "B" ? b : a
            u.rate = AVSpeechUtteranceDefaultSpeechRate * rate
            lineOf[ObjectIdentifier(u)] = (line + k, 0)
            if line + k == script.count - 1 { lastUtterance = u }
            synth.speak(u)
        }
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

/// Play/pause, prev/next, chapter menu, mode. Drop it in a toolbar.
struct ListenControls: View {
    var speaker = Speaker.shared

    var body: some View {
        Button("Previous chapter", systemImage: "backward.end") { speaker.skip(-1) }
        Button(speaker.playing && !speaker.paused ? "Pause" : "Listen",
               systemImage: speaker.loading ? "stop.fill" : (speaker.playing && !speaker.paused ? "pause.fill" : "play.fill")) { speaker.toggle() }
        Button("Next chapter", systemImage: "forward.end") { speaker.skip(1) }
        Menu("Chapters", systemImage: "list.bullet") {
            ForEach(speaker.chapters.indices, id: \.self) { i in
                Button(speaker.chapters[i].title) { speaker.go(to: i) }
            }
            Divider()
            Picker("Speed", selection: Binding(get: { speaker.rate }, set: { speaker.rate = $0 })) {
                ForEach([Float(1), 1.25, 1.5, 2], id: \.self) { Text("\(($0 * 100).rounded() / 100, specifier: "%g")×").tag($0) }
            }
            Toggle("Explain it (two hosts)", isOn: Binding(get: { speaker.explain }, set: { speaker.explain = $0; speaker.invalidateScripts() }))
        }
    }
}
