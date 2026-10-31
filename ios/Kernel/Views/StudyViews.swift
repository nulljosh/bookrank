import SwiftUI

/// Key ideas at the top of a book, from its own takeaways (Study.keyIdeas). Hidden when a book has none.
struct KeyIdeas: View {
    let markdown: String
    @State private var onePage = false
    var body: some View {
        let ideas = Study.keyIdeas(markdown)
        if !ideas.isEmpty {
            Section("Key ideas") {
                ForEach(Array(ideas.enumerated()), id: \.offset) { i, t in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(i + 1)").font(.kernel(.footnote, weight: .semibold)).foregroundStyle(.tint).monospacedDigit()
                        Text(t).font(.kernel(.subheadline))
                    }
                    .selectionDisabled()
                }
                Button("One-page summary", systemImage: "doc.plaintext") { onePage = true }
            }
            .sheet(isPresented: $onePage) { OnePage(markdown: markdown) }
        }
    }
}

/// The whole book on one page: each chapter's title and its In short lines (Study.recap).
struct OnePage: View {
    let markdown: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(parseChapters(markdown).enumerated()), id: \.offset) { _, c in
                    let lines = Study.recap(c.text)
                    if !lines.isEmpty {
                        Section(c.title) { ForEach(lines, id: \.self) { Text($0).font(.kernel(.body)) } }
                    }
                }
            }
            .navigationTitle("One-page summary")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 600)
        #endif
    }
}

/// Under a chapter: "In short" (two lines), a three-question quiz on its bold terms, then your note.
struct ChapterEnd: View {
    let store: DataStore, slug: String, ch: Int
    @State private var quizzing = false
    @State private var picked: [Int: String] = [:]

    var body: some View {
        let chs = parseChapters(store.summaryMarkdown(for: slug))
        let text = chs.indices.contains(ch) ? chs[ch].text : ""
        let lines = Study.recap(text), qs = Study.quiz(text, book: store.summaryMarkdown(for: slug))
        VStack(alignment: .leading, spacing: 12) {
            if !lines.isEmpty || !qs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("In short").font(.kernel(.caption, weight: .medium)).textCase(.uppercase).foregroundStyle(.secondary)
                    ForEach(lines, id: \.self) { Text($0).font(.kernel(.body)) }
                    if !qs.isEmpty && !quizzing { Button("Quiz me") { quizzing = true }.buttonStyle(.bordered).padding(.top, 4) }
                    if quizzing {
                        ForEach(Array(qs.enumerated()), id: \.offset) { i, q in question(i, q) }
                        if picked.count == qs.count {
                            Text("\(qs.indices.filter { picked[$0] == qs[$0].answer }.count) of \(qs.count) right").font(.kernel(.subheadline, weight: .semibold))
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            ChapterNote(store: store, slug: slug, ch: ch)
        }
        .onChange(of: ch) { quizzing = false; picked = [:] }
    }

    private func question(_ i: Int, _ q: Study.Question) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(q.question).font(.kernelItalic(.subheadline))
            ForEach(q.choices, id: \.self) { c in
                let chosen = picked[i]
                Button { picked[i] = c } label: {
                    Label(c, systemImage: chosen == nil ? "circle" : c == q.answer ? "checkmark.circle.fill" : c == chosen ? "xmark.circle.fill" : "circle")
                }
                .buttonStyle(.plain).disabled(chosen != nil)
                .foregroundStyle(chosen != nil && c == q.answer ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
            }
        }
        .padding(.top, 6)
    }
}
