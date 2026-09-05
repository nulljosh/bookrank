import AVFoundation
import SwiftUI
import Observation

/// Chapter player over AVSpeechSynthesizer. Mirrors library.html's player: "Explain it"
/// fetches a two-host script per chapter from /api/narrate, "Read" speaks the markdown.
/// Pause/resume is native; the resume point and scripts are saved on the summary row so
/// the web and the apps pick up at the same line.
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
    private(set) var playing = false
    private(set) var paused = false
    private(set) var loading = false
    var explain = true { didSet { if playing { Task { await play(from: 0) } } } }
    var rate: Float = UserDefaults.standard.object(forKey: "bookrank.rate") as? Float ?? 1 {
        didSet { UserDefaults.standard.set(rate, forKey: "bookrank.rate"); if playing { Task { await play(from: line) } } }
    }
    var status = ""
    private var scripts: [String: [ListenState.Line]] = [:]
    private var updatedAt = ""
    private var save: ((ListenState) async -> Void)?
    private var lineOf: [ObjectIdentifier: Int] = [:]
    private var lastUtterance: AVSpeechUtterance?

    override private init() { super.init(); synth.delegate = self }

    /// Bind to a summary. Restores the saved position when the content is unchanged.
    func load(slug: String, chapters: [Chapter], entry: SummaryEntry?, save: @escaping (ListenState) async -> Void) {
        if self.slug == slug { return }
        stop()
        self.slug = slug; self.chapters = chapters; self.save = save
        updatedAt = entry?.updatedAt ?? ""
        let st = entry?.listen.flatMap { $0.for == updatedAt ? $0 : nil }
        scripts = st?.chapters ?? [:]
        ch = min(st?.pos.ch ?? 0, max(0, chapters.count - 1)); line = st?.pos.line ?? 0
        status = st.map { _ in "Resume at \(chapters[ch].title)" } ?? ""
    }

    func toggle() {
        if playing && !paused { synth.pauseSpeaking(at: .word); paused = true; persist(); return }
        if paused { synth.continueSpeaking(); paused = false; return }
        Task { await play(from: line) }
    }
    func skip(_ delta: Int) {
        guard !chapters.isEmpty else { return }
        ch = max(0, min(chapters.count - 1, ch + delta)); line = 0
        Task { await play(from: 0) }
    }
    func go(to chapter: Int) { ch = chapter; line = 0; Task { await play(from: 0) } }

    func stop() {
        let was = playing
        synth.stopSpeaking(at: .immediate)
        playing = false; paused = false; lineOf = [:]
        if was { persist() }
    }

    private func persist() {
        guard let save else { return }
        let st = ListenState(for: updatedAt, chapters: scripts, pos: .init(ch: ch, line: line))
        Task { await save(st) }
    }

    private func script(for i: Int) async -> [ListenState.Line] {
        let plain = chapters[i].text.replacingOccurrences(of: "[#*_`>\\[\\]()]", with: " ", options: .regularExpression)
        guard explain else { return [.init(host: "A", line: plain)] }
        if let s = scripts["\(i)"] { return s }
        loading = true; defer { loading = false }
        if let s = await Narrator.narrate(text: chapters[i].text, title: chapters[i].title) { scripts["\(i)"] = s; return s }
        status = "Could not build the conversation; reading the notes."
        return [.init(host: "A", line: plain)]
    }

    @MainActor
    private func play(from: Int) async {
        synth.stopSpeaking(at: .immediate); lineOf = [:]; paused = false
        guard ch < chapters.count else { return }
        let lines = await script(for: ch)
        guard !lines.isEmpty else { return }
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        let a = AVSpeechSynthesisVoice(language: Locale.current.identifier) ?? AVSpeechSynthesisVoice(language: "en-US")
        let b = AVSpeechSynthesisVoice.speechVoices().first { $0.language == a?.language && $0.identifier != a?.identifier } ?? a
        line = min(from, lines.count - 1)
        playing = true
        for (k, l) in lines[line...].enumerated() {
            let u = AVSpeechUtterance(string: l.line)
            u.voice = l.host == "B" ? b : a
            u.rate = AVSpeechUtteranceDefaultSpeechRate * rate
            lineOf[ObjectIdentifier(u)] = line + k
            if line + k == lines.count - 1 { lastUtterance = u }
            synth.speak(u)
        }
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart u: AVSpeechUtterance) {
        if let i = lineOf[ObjectIdentifier(u)] { line = i; status = "\(chapters[ch].title) · \(i + 1)" }
    }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) {
        guard u === lastUtterance, playing else { return }
        if ch + 1 < chapters.count { ch += 1; line = 0; Task { await play(from: 0) } }
        else { line = 0; playing = false; status = "Finished."; persist() }
    }
}

enum Narrator {
    static func narrate(text: String, title: String) async -> [ListenState.Line]? {
        guard let token = try? await supabase.auth.session.accessToken else { return nil }
        var req = URLRequest(url: URL(string: "https://bookrank.heyitsmejosh.com/api/narrate")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["text": text, "title": title])
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
               systemImage: speaker.loading ? "ellipsis" : (speaker.playing && !speaker.paused ? "pause.fill" : "play.fill")) { speaker.toggle() }
            .disabled(speaker.loading)
        Button("Next chapter", systemImage: "forward.end") { speaker.skip(1) }
        Menu("Chapters", systemImage: "list.bullet") {
            ForEach(speaker.chapters.indices, id: \.self) { i in
                Button(speaker.chapters[i].title) { speaker.go(to: i) }
            }
            Divider()
            Picker("Speed", selection: Binding(get: { speaker.rate }, set: { speaker.rate = $0 })) {
                ForEach([Float(1), 1.25, 1.5, 2], id: \.self) { Text("\(($0 * 100).rounded() / 100, specifier: "%g")×").tag($0) }
            }
            Toggle("Explain it (two hosts)", isOn: Binding(get: { speaker.explain }, set: { speaker.explain = $0 }))
        }
    }
}
