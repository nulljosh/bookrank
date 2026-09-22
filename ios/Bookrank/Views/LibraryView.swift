import SwiftUI

struct LibraryView: View {
    @State private var store = DataStore()
    @State private var auth = AuthStore()
    @AppStorage("spine-theme") private var theme: String = "system"
    @State private var showAccount = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    header
                    summaries
                }
                .padding(24)
                .frame(maxWidth: 680, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        theme = (theme == "dark") ? "light" : "dark"
                    } label: {
                        Image(systemName: theme == "dark" ? "moon.fill" : "sun.max.fill")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        showAccount = true
                    } label: {
                        Image(systemName: auth.isSignedIn ? "person.crop.circle.fill" : "person.crop.circle")
                    }
                    .accessibilityLabel(auth.isSignedIn ? "Account" : "Sign in")
                }
            }
            .sheet(isPresented: $showAccount) { AccountView(auth: auth, store: store) }
        }
        .preferredColorScheme(theme == "dark" ? .dark : theme == "light" ? .light : nil)
        // Fires once the stored session has been read back, and again on sign-in or
        // sign-out, so the shelf follows the account without a manual refresh.
        .task(id: auth.user?.id) {
            if auth.isSignedIn { await store.loadSummaries() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bookrank")
                .font(.system(size: 40, weight: .black))
            Text("Your books, summarized chapter by chapter.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var summaries: some View {
        if !auth.isSignedIn {
            Button("Sign in to see your summaries") { showAccount = true }
                .buttonStyle(.bordered)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                sectionLabel("Summaries")
                if let error = store.summaryError {
                    Text(error).font(.caption).foregroundStyle(.secondary)
                } else if store.summaryIndex.isEmpty {
                    Text("No summaries on this account yet.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                let started = { (e: SummaryEntry) in e.listen?.for == e.updatedAt && ((e.listen?.pos.ch ?? 0) > 0 || (e.listen?.pos.line ?? 0) > 0) }
                let groups = [("Currently playing", store.summaryIndex.filter(started)), ("Library", store.summaryIndex.filter { !started($0) })]
                ForEach(groups.filter { !$0.1.isEmpty }, id: \.0) { label, rows in
                if groups[0].1.count > 0 { Text(label).font(.caption2).textCase(.uppercase).foregroundStyle(.tertiary).padding(.top, 8) }
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(rows) { entry in
                        NavigationLink { SummaryDetailView(slug: entry.slug, store: store) } label: {
                            HStack(alignment: .center, spacing: 14) {
                                Thumb(url: store.cover(for: entry))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.title).font(.subheadline.weight(.medium))
                                    if let pos = entry.listen?.pos, entry.listen?.for == entry.updatedAt, pos.ch > 0 || pos.line > 0 {
                                        Text("Resume · Ch \(pos.ch + 1)").font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        if entry.id != rows.last?.id { Divider() }
                    }
                }
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption2.weight(.medium))
            .tracking(1.2)
            .foregroundStyle(.primary)
    }
}

/// ponytail: 36×52 cover or a flat placeholder; matched by title from the bundled shelf.
private struct Thumb: View {
    let url: String?
    var body: some View {
        AsyncImage(url: url.flatMap(URL.init)) { img in img.resizable().scaledToFill() } placeholder: { Color.secondary.opacity(0.15) }
            .frame(width: 36, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}
