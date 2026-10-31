import SwiftUI

/// Ask the chapter on screen one question; /api/ask answers from that chapter's notes only.
struct AskView: View {
    let chapter: Speaker.Chapter
    @Environment(\.dismiss) private var dismiss
    @State private var question = ""
    @State private var answer: String?
    @State private var asking = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What do you want to know?", text: $question, axis: .vertical)
                        .lineLimit(1...4)
                        .onSubmit { Task { await ask() } }
                } footer: {
                    Text("Answers come from this chapter's notes only.")
                }
                if asking || answer != nil {
                    Section("Answer") {
                        if asking { ProgressView() } else if let answer { Text(answer).textSelection(.enabled) }
                    }
                }
            }
            .formStyle(.grouped)
            .font(.kernel(.body))
            .navigationTitle(chapter.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ask") { Task { await ask() } }.disabled(asking || question.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func ask() async {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, !asking else { return }
        asking = true; defer { asking = false }
        struct Out: Decodable { let answer: String?; let error: String? }
        do {
            let data = try await API.call("POST", "https://kernel.jaybulb.com/api/ask",
                                          json: ["text": chapter.text, "title": chapter.title, "question": q])
            let out = try? JSONDecoder().decode(Out.self, from: data)
            answer = out?.answer ?? out?.error ?? "Could not answer that right now."
        } catch { answer = (error as? API.Failure)?.message ?? "Could not answer that right now." }
    }
}
