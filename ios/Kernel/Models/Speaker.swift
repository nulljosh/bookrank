import AVFoundation
import SwiftUI
import Observation

/// Chapter player over AVSpeechSynthesizer. Mirrors listen.js: "Explain it" fetches a
/// one-narrator script per chapter from /api/narrate, "Read" speaks the markdown block by block.
/// The next chapter's script is fetched while the current one plays, the spoken line and
/// word are published for the transcript to highlight, and the resume point + scripts are
/// saved on the summary row so the web and the apps pick up at the same line.
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
    /// One narrator explains the chapter; on by default and remembered. The signed-out sample has no script to build, so it reads the notes.
    var explain: Bool = UserDefaults.standard.object(forKey: "bookrank.explain") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(explain, forKey: "bookrank.explain")
            // The narrator's script and the plain notes have different line counts, so keep the same place by fraction, not by index.
            let spot = lines.isEmpty ? 0 : Double(line) / Double(lines.count)
            if playing { Task { await play(from: 0, fraction: spot) } } else { Task { await showChapter() } }
        }
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
    /// Which voice is speaking right now, so the player can say so instead of quietly switching.
    private(set) var voice = ""
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

    override private init() {
        super.init(); synth.delegate = self
        // Weekly goal: five seconds counted for every five actually spoken.
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            guard let self, self.playing, !self.paused, !self.loading else { return }
            Goal.shared.add(5)
        }
    }

    /// Bind to a summary. Restores the saved position when the content is unchanged.
    func load(slug: String, chapters: [Chapter], entry: SummaryEntry?, save: @escaping (ListenState) async -> Void) {
        if self.slug == slug { return }
        stop()
        self.slug = slug; self.chapters = chapters; self.save = save
        if let r = UserDefaults.standard.object(forKey: "bookrank.rate.\(slug)") as? Float { rate = r }
        updatedAt = entry?.updatedAt ?? ""
        let st = entry?.listen.flatMap { $0.for == updatedAt ? $0 : nil }
        // Scripts cached before the one-narrator switch are two-host dialogue; drop them so they get rebuilt.
        scripts = (st?.chapters ?? [:]).filter { !$0.value.contains { $0.host == "B" } }; prefetch = [:]
        ch = min(st?.pos.ch ?? 0, max(0, chapters.count - 1)); line = st?.pos.line ?? 0
        status = st.map { _ in "Resume at \(chapters[ch].title)" } ?? ""
        marks = entry?.listen?.marks ?? []   // kept even when listen.for is stale
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
    /// Sleep timer: 0 off, -1 at the end of this chapter, otherwise minutes from when it was set.
    var sleep = 0 { didSet { armSleep() } }
    private var sleepTask: Task<Void, Never>?
    private func armSleep() {
        sleepTask?.cancel(); sleepTask = nil
        guard sleep > 0 else { return }
        let m = sleep
        sleepTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(m * 60))
            guard !Task.isCancelled else { return }
            if playing && !paused { toggle() }   // pause, so Play picks up the same line
            sleep = 0
        }
    }

    /// The last line of a chapter finished: on to the next, unless the sleep timer says stop here.
    private func chapterEnded() {
        let more = ch + 1 < chapters.count
        if more { ch += 1; line = 0 }
        if sleep == -1 { sleep = 0; stop(); status = "Stopped at the end of the chapter."; Task { await showChapter() }; return }
        if more { Task { await play(from: 0) } }
        else { line = 0; playing = false; word = nil; status = "Finished."; persist() }
    }

    /// Books whose voice lines are all on the device, and how far the current download is (0...1).
    private(set) var offline: Set<String> = Set((try? FileManager.default.contentsOfDirectory(atPath: URL.applicationSupportDirectory.appending(path: "voice").path)) ?? [])
        .filter { FileManager.default.fileExists(atPath: Narrator.offlineDir($0).appending(path: "done").path) }
    private(set) var downloading: Double?

    /// Fetch every line of the loaded book in the natural voice and keep it, so it plays with no connection.
    /// ponytail: keeps the lines of the current mode (Explain it or the notes); the other mode still needs the network.
    @MainActor
    func download() async {
        guard let slug, downloading == nil else { return }
        let dir = Narrator.offlineDir(slug)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        downloading = 0
        defer { downloading = nil }
        for i in chapters.indices {
            guard self.slug == slug, let s = await script(for: i).value else { status = "Download stopped. Try again with a connection."; return }
            for l in s {
                if await Narrator.speak(l.line, host: l.host, ch: i, slug: slug) == nil {
                    status = "Download stopped (\(Narrator.lastFailure ?? "unknown")). Try again later."; return
                }
            }
            downloading = Double(i + 1) / Double(chapters.count)
        }
        FileManager.default.createFile(atPath: dir.appending(path: "done").path, contents: nil)
        offline.insert(slug)
        persist()   // the scripts fetched on the way are what the lines were made from
    }
    func removeDownload() {
        guard let slug else { return }
        try? FileManager.default.removeItem(at: Narrator.offlineDir(slug))
        offline.remove(slug)
    }

    /// Highlights for the book that is loaded.
    private(set) var marks: [ListenState.Mark] = []
    func isMarked(_ l: ListenState.Line, in chapter: Int) -> Bool { marks.contains(.init(ch: chapter, text: l.line)) }
    func toggleMark(_ l: ListenState.Line) {
        let m = ListenState.Mark(ch: ch, text: l.line)
        if let k = marks.firstIndex(of: m) { marks.remove(at: k) } else { marks.append(m) }
        persist()
    }

    /// Back or forward one line in the chapter that is playing.
    func nudge(_ delta: Int) {
        guard !lines.isEmpty else { return }
        go(to: ch, line: max(0, min(lines.count - 1, line + delta)))
    }
    /// Screenshots only (UITEST_PLAYER): the bar as if paused on a chapter, with nothing spoken.
    func showPausedForScreenshot(chapters: [Chapter]) { self.chapters = chapters; ch = 0; paused = true; status = "" }
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

    /// Forget the loaded book, so the next load reads its content again.
    func unload() { stop(); slug = nil }

    private func persist() {
        Task { await Goal.shared.remind() }
        guard let save else { return }
        let st = ListenState(for: updatedAt, chapters: scripts, pos: .init(ch: ch, line: line), marks: marks)
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
        let t = Task<[ListenState.Line]?, Never> { [talks = talks, chapters, slug] in
            guard i < chapters.count else { return nil }
            if !talks { return Self.blocks(chapters[i].text) }
            if let s = scripts["\(i)"] { return s }
            if let s = await Narrator.narrate(text: chapters[i].text, title: chapters[i].title, ch: i, total: chapters.count) {
                // A prefetch that lands after a book switch belongs to the old book. Saving it here
                // is how Adult Autism's chapter 2 ended up in The Optimist.
                if self.slug == slug { scripts["\(i)"] = s }
                return s
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
    private func play(from: Int, fraction: Double? = nil) async {
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
        line = min(fraction.map { Int($0 * Double(script.count)) } ?? from, script.count - 1)
        if natural {
            voice = "Natural voice"
            if await playNatural(script, from: line, tok: tok) { return }
            guard tok == token else { return }   // a line failed: keep going on the device voice from there
            status = "Natural voice unavailable (\(Narrator.lastFailure ?? "unknown")). Using the device voice."
        }
        voice = "Device voice"
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
        var next = Task { await Narrator.speak(script[start].line, host: script[start].host, ch: ch, slug: slug) }
        for i in start..<script.count {
            guard tok == token else { return true }
            let clip = await next.value
            guard tok == token else { return true }
            guard let clip, let p = try? AVAudioPlayer(data: clip.audio) else { line = i; return false }
            if i + 1 < script.count { let n = script[i + 1]; next = Task { await Narrator.speak(n.line, host: n.host, ch: ch, slug: slug) } }
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
        chapterEnded()
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
        chapterEnded()
    }
}
