import SwiftUI

// Actions under a book's title, split out of SummaryDetailView.swift.

/// Which collection the book is in: pick one, make a new one, or none.
struct CollectionMenu: View {
    let store: DataStore, slug: String, current: String?
    @State private var naming = false
    @State private var newCollection = ""

    var body: some View {
        Menu {
            ForEach(store.collections, id: \.self) { n in
                Button { Task { await store.setCollection(n, for: slug) } } label: { if n == current { Label(n, systemImage: "checkmark") } else { Text(n) } }
            }
            Button("New collection…", systemImage: "plus") { newCollection = ""; naming = true }
            if current != nil { Button("Remove from \(current!)", systemImage: "minus.circle", role: .destructive) { Task { await store.setCollection(nil, for: slug) } } }
        } label: {
            HStack(spacing: 4) { Image(systemName: "folder"); current.map(Text.init(verbatim:)) ?? Text("Add to a collection") }
        }
        .font(.kernel(.footnote)).menuStyle(.button).buttonStyle(.borderless)
        .accessibilityLabel(current.map { "Collection, \($0)" } ?? "Add to a collection")
        .alert("New collection", isPresented: $naming) {
            TextField("Name", text: $newCollection)
            Button("Cancel", role: .cancel) {}
            Button("Add") { Task { await store.setCollection(newCollection, for: slug) } }
        }
    }
}

/// Finished: mark the book done, or not. The day is kept in the row's notes under "finished" (DataStore.setFinished).
struct FinishedButton: View {
    let store: DataStore, slug: String

    var body: some View {
        let done = store.summary(for: slug)?.notes?["finished"] != nil
        Button { Task { await store.setFinished(!done, for: slug) } } label: {
            HStack(spacing: 4) { Image(systemName: done ? "checkmark.circle.fill" : "checkmark.circle"); Text(done ? "Finished" : "Mark finished") }
        }
        .font(.kernel(.footnote)).buttonStyle(.borderless)
        .accessibilityLabel(done ? "Finished. Tap to mark not finished." : "Mark finished")
    }
}
