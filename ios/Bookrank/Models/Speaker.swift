import AVFoundation
import SwiftUI
import Observation

// ponytail: on-device AVSpeechSynthesizer, no backend, no audio files. Mirrors the
// web's speechSynthesis reader. Add a voice picker if anyone asks for one.
@Observable
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()
    private(set) var current: String?   // id of whatever is being read

    override private init() { super.init(); synth.delegate = self }

    func toggle(id: String, text: String) {
        if current == id { stop(); return }
        stop()
        let clean = text.replacingOccurrences(of: "[#*_`>\\[\\]()]", with: " ", options: .regularExpression)
        guard !clean.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        let u = AVSpeechUtterance(string: clean)
        u.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
        current = id
        synth.speak(u)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        current = nil
    }

    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) { current = nil }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) { current = nil }
}

struct ReadAloudButton: View {
    let id: String
    let text: String
    var speaker = Speaker.shared

    var body: some View {
        let on = speaker.current == id
        Button(on ? "Stop" : "Read aloud", systemImage: on ? "stop.fill" : "speaker.wave.2") { speaker.toggle(id: id, text: text) }
            { speaker.toggle(id: id, text: text) }
    }
}
