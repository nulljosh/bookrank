import Foundation
#if os(iOS)
import UIKit

/// Shake the phone while the sleep timer runs to give it ten more minutes.
extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake { Speaker.shared.addSleepTime() }
        super.motionEnded(motion, with: event)
    }
}
#endif

/// The parts of the player that need no state of their own: the notes split into lines, and the next chapter fetched ahead.
extension Speaker {
    /// Under the sleep menu while a timer runs: when it pauses, and on iPhone how to push it back.
    var sleepNote: String? {
        guard let end = sleepEnds else { return nil }
        let at = "Pauses at \(end.formatted(date: .omitted, time: .shortened))."
        #if os(iOS)
        return at + " Shake for ten more minutes."
        #else
        return at
        #endif
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

    /// On Wi-Fi, the next chapter's natural voice is fetched while this one plays and kept on the device,
    /// so a tunnel or a plane does not stop the book at the chapter break. Never on cellular or Low Data Mode.
    /// ponytail: one chapter ahead, kept with the book's other lines; the Storage screen is where they go away.
    func prefetchAudio(_ i: Int) {
        guard natural, let slug, slug != "sample", Net.shared.wifi else { return }
        let host = narrator, task = script(for: i)
        Task.detached(priority: .background) {
            guard let lines = await task.value else { return }
            try? FileManager.default.createDirectory(at: Narrator.offlineDir(slug), withIntermediateDirectories: true)
            for l in lines { guard Speaker.shared.slug == slug, Net.shared.wifi else { return }; _ = await Narrator.speak(l.line, host: host, ch: i, slug: slug) }
        }
    }
}

import SwiftUI

extension View {
    /// Reading with no audio saves your place: the top line at least a third on screen, via Speaker.seen.
    /// iOS 18 and macOS 15 report which lines are visible; earlier systems save only while playing.
    @ViewBuilder func readingPlace(_ speaker: Speaker) -> some View {
        if #available(iOS 18, macOS 15, *) {
            onScrollTargetVisibilityChange(idType: Int.self, threshold: 0.33) { ids in speaker.seen(ids) }
        } else { self }
    }
}
