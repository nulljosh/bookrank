import Foundation
import SwiftUI

/// Study aids pulled from a summary's own text, on the device, no model: a book's key ideas, a chapter's two-line
/// recap, and a short quiz that blanks out the chapter's bold terms. The same rules as study.js on the web.
enum Study {
    struct Question: Equatable { let question: String, answer: String, choices: [String] }

    private static let take = /^#{1,6}\s*(?i:key takeaways?|takeaways?|key ideas|key points|lessons|in short|summary)\b/
    private static let label = /^(?i:key|note|tip|example|photo|warning|remember|important|takeaway|summary|chapter|part)\b/
    private static let bold = /\*\*([^*\n]{2,40})\*\*/

    static func clean(_ s: String) -> String {
        s.replacing(/^\s*(?:[-*•]|\d+\.)\s+/, with: "").replacing(/\*\*|__|`/, with: "").replacing("*", with: "")
            .replacing(/\[([^\]]+)\]\([^)]+\)/) { String($0.1) }.trimmingCharacters(in: .whitespaces)
    }
    /// Splits after . ! or ? when a capital, a digit or a quote starts the next sentence (as study.js).
    static func sentences(_ p: String) -> [String] {
        let c = Array(clean(p)); var out: [String] = [], start = 0, i = 0
        while i < c.count {
            if ".!?".contains(c[i]), i + 1 < c.count, c[i + 1].isWhitespace {
                var j = i + 1; while j < c.count, c[j].isWhitespace { j += 1 }
                if j < c.count, c[j].isUppercase || c[j].isNumber || "“\"".contains(c[j]) { out.append(String(c[start...i])); start = j; i = j; continue }
            }
            i += 1
        }
        if start < c.count { out.append(String(c[start...])) }
        return out.map { $0.trimmingCharacters(in: .whitespaces) }.filter { $0.count >= 25 }
    }

    /// The bullet lines under a chapter's "Key takeaways" (or similar) heading.
    static func takeaways(_ text: String) -> [String] {
        var out: [String] = [], on = false
        for line in text.components(separatedBy: "\n") {
            if line.firstMatch(of: /^#{1,6}\s/) != nil { on = line.firstMatch(of: take) != nil; continue }
            if on, let m = line.firstMatch(of: /^\s*(?:[-*•]|\d+\.)\s+(.*)/), clean(String(m.1)).count >= 20 { out.append(clean(String(m.1))) }
        }
        return out
    }

    private static func paragraphs(_ text: String) -> [String] {
        text.components(separatedBy: "\n\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") && $0.firstMatch(of: /(?m)^\s*(?:[-*•]|\d+\.)\s/) == nil && clean($0).count >= 40 }
    }

    /// Up to five ideas for the top of a book: each chapter's first takeaway, or its opening sentence.
    static func keyIdeas(_ markdown: String, n: Int = 5) -> [String] {
        var out: [String] = []
        for c in parseChapters(markdown) {
            if let t = takeaways(c.text).first ?? paragraphs(c.text).first.flatMap({ sentences($0).first }), !out.contains(t) { out.append(t) }
            if out.count >= n { break }
        }
        return out
    }

    /// Two lines to close a chapter: its first two takeaways, or the last paragraph's first two sentences.
    /// A question to think over under each chapter's note, the same one per chapter (as study.js).
    static func reflect(_ ch: Int) -> LocalizedStringKey {
        ["Where could you use this idea this week?", "What would you push back on in this chapter?", "What will you do differently after this chapter?"][ch % 3]
    }

    static func recap(_ text: String) -> [String] {
        let t = takeaways(text)
        return t.isEmpty ? Array(sentences(paragraphs(text).last ?? "").prefix(2)) : Array(t.prefix(2))
    }

    /// Up to three questions: a sentence with one bold term blanked, that term and two others from the book.
    static func quiz(_ text: String, book: String, n: Int = 3) -> [Question] {
        var terms: [String] = []
        for m in book.matches(of: bold) {
            let t = String(m.1).trimmingCharacters(in: .whitespaces).replacing(/:$/, with: "")
            if t.firstMatch(of: label) == nil, !terms.contains(t) { terms.append(t) }
        }
        let key = { (s: String) in (s.count * 31 + Int(s.unicodeScalars.first?.value ?? 0)) % 7 }
        var qs: [Question] = []
        for line in text.components(separatedBy: "\n") where !line.hasPrefix("#") {
            for m in line.matches(of: bold) {
                let answer = String(m.1).trimmingCharacters(in: .whitespaces).replacing(/:$/, with: ""), sentence = clean(line)
                let words = sentence.replacingOccurrences(of: answer, with: "").split(separator: " ").filter { $0.contains(where: \.isLetter) || $0.contains(where: \.isNumber) }
                // A sentence that stops on a colon (it introduces a list) makes a poor question.
                if sentence.hasSuffix(":") || answer.firstMatch(of: label) != nil || words.count < 8 || qs.contains(where: { $0.answer == answer }) { continue }
                let others = terms.filter { $0 != answer }
                guard others.count >= 2 else { continue }
                var pick = [others[(answer.count * 7) % others.count], others[(answer.count * 13 + 1) % others.count]]
                if pick[0] == pick[1], let alt = others.first(where: { $0 != pick[0] }) { pick[1] = alt }
                let choices = ([answer] + pick).enumerated().sorted { (key($0.element), $0.offset) < (key($1.element), $1.offset) }.map(\.element)
                qs.append(Question(question: sentence.replacingOccurrences(of: answer, with: "_____", options: [], range: sentence.range(of: answer)), answer: answer, choices: choices))
                break
            }
            if qs.count >= n { break }
        }
        return qs
    }
}
