#if os(iOS)
import SwiftUI

/// The sheet: the title to save it under, what will be kept, and Save or Cancel.
struct ShareView: View {
    @State var title: String
    let text: String
    let url: URL?
    let done: (Inbox.Item?) -> Void
    var body: some View {
        NavigationStack {
            Form {
                Section("Save as") { TextField("Title", text: $title) }
                Section {
                    if let url { Label(url.absoluteString, systemImage: "link").lineLimit(2) }
                    if !text.isEmpty { Text(text).lineLimit(6) }
                } footer: {
                    Text(text.isEmpty ? "Kernel reads the page and keeps its text as a book, the next time you open Kernel." : "Kept as a book in Kernel the next time you open it.")
                }
            }
            .navigationTitle("Save to Kernel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { done(nil) } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { done(Inbox.Item(title: title.isEmpty ? "Saved" : title, text: text, url: url?.absoluteString)) }
                        .disabled(text.isEmpty && url == nil)
                }
            }
        }
    }
}
#endif
