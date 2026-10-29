import SwiftUI
import PhotosUI
import ImageIO
import UniformTypeIdentifiers
#if os(iOS)
import VisionKit
#endif

/// Add a chapter from photos of the pages: each photo goes to /api/summarize-photo (same as the
/// web's "From photos"), the text lands in an editor, Save appends it to a book or starts a new one.
/// Photos are never kept, only the text.
/// ponytail: picks from the photo library; an in-app camera can come when someone asks.
struct AddPagesView: View {
    var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var book = ""            // slug of an existing book, "" for a new one
    @State private var newTitle = ""
    /// `title`: a Goodreads book's title, when Summarize this book opened the sheet.
    init(store: DataStore, title: String = "") { self.store = store; _newTitle = State(initialValue: title) }
    @State private var chapter = ""
    @State private var text = ""
    @State private var picks: [PhotosPickerItem] = []
    @State private var reading: String?
    @State private var error: String?
    @State private var saving = false
    @State private var kindle = false
    @State private var scanning = false
    @State private var ebook = false
    @State private var importing: String?
    @State private var kindleDone: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Book", selection: $book) {
                        Text("New book").tag("")
                        ForEach(store.summaryIndex) { Text($0.title).tag($0.slug) }
                    }
                    if book.isEmpty { TextField("Book title", text: $newTitle) }
                    TextField("Chapter title", text: $chapter)
                }
                Section {
                    PhotosPicker(selection: $picks, matching: .images) {
                        Label(reading ?? "Choose page photos", systemImage: "photo.on.rectangle")
                    }
                    .disabled(reading != nil)
                    #if os(iOS)
                    if VNDocumentCameraViewController.isSupported {
                        Button { scanning = true } label: { Label("Scan pages", systemImage: "doc.viewfinder") }.disabled(reading != nil)
                            .fullScreenCover(isPresented: $scanning) { Scanner { pages in Task { await readScans(pages) } }.ignoresSafeArea() }
                    }
                    #endif
                    TextEditor(text: $text).frame(minHeight: 200).font(.kernel(.body))
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty { Text("The pages' text shows up here.").foregroundStyle(.tertiary).padding(.top, 8).padding(.leading, 5).allowsHitTesting(false) }
                        }
                } footer: {
                    Text(error ?? "Each page is read and summarized, then the photo is dropped. Edit the text before you save.")
                        .foregroundStyle(error == nil ? Color.secondary : Color.red)
                }
                Section {
                    Button { ebook = true } label: { Label(importing ?? "Import an EPUB or PDF you own", systemImage: "book.closed") }.disabled(importing != nil)
                        .fileImporter(isPresented: $ebook, allowedContentTypes: [.epub, .pdf]) { r in   // its own view: two importers on one view clash
                            guard case .success(let url) = r else { return }
                            let ok = url.startAccessingSecurityScopedResource(); defer { if ok { url.stopAccessingSecurityScopedResource() } }
                            do {
                                let book = try Ebook.markdown(url)
                                Task {
                                    importing = "Adding \(book.title)…"
                                    do { try await store.addBook(title: book.title, markdown: book.markdown); kindleDone = "Added \(book.title)." }
                                    catch { kindleDone = (error as? API.Failure)?.message ?? "Could not save that book." }
                                    importing = nil
                                }
                            } catch { kindleDone = (error as? Ebook.Failure)?.message ?? "Could not read that file." }
                        }
                    Button { kindle = true } label: { Label(importing ?? "Import Kindle or Readwise highlights", systemImage: "book.pages") }.disabled(importing != nil)
                } footer: {
                    Text(kindleDone ?? "An EPUB without DRM or a PDF becomes a book, a chapter per section. For highlights, choose My Clippings.txt from your Kindle's documents folder, or a Readwise CSV export.")
                }
            }
            .fileImporter(isPresented: $kindle, allowedContentTypes: [.plainText, .text, .commaSeparatedText]) { r in
                guard case .success(let url) = r else { return }
                let ok = url.startAccessingSecurityScopedResource(); defer { if ok { url.stopAccessingSecurityScopedResource() } }
                guard let text = try? String(contentsOf: url, encoding: .utf8) else { kindleDone = "Could not read that file."; return }
                let rw = Kindle.parseReadwise(text), books = rw ?? Kindle.parse(text)
                Task { importing = "Adding \(books.count) books…"; kindleDone = await store.importKindle(books, heading: rw == nil ? "Kindle highlights" : "Readwise highlights"); importing = nil }
            }
            .formStyle(.grouped)
            .navigationTitle("Add pages")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(saving || reading != nil || chapter.isEmpty || text.isEmpty || (book.isEmpty && newTitle.isEmpty))
                }
            }
            .onChange(of: picks) { _, items in Task { await read(items) } }
        }
    }

    /// Pages from the document camera: already flat and cropped JPEGs, read the same way as photos.
    private func readScans(_ pages: [Data]) async {
        error = nil
        for (i, jpeg) in pages.enumerated() {
            reading = "Reading \(i + 1) of \(pages.count)…"
            do { let page = try await Self.summarize(jpeg); text += (text.isEmpty ? "" : "\n\n") + page }
            catch { self.error = (error as? API.Failure)?.message ?? "Could not read a page." }
        }
        reading = nil
    }

    private func read(_ items: [PhotosPickerItem]) async {
        guard !items.isEmpty else { return }
        error = nil
        for (i, item) in items.enumerated() {
            reading = "Reading \(i + 1) of \(items.count)…"
            guard let raw = try? await item.loadTransferable(type: Data.self), let jpeg = Self.jpeg(raw) else { error = "Could not open a photo."; continue }
            do {
                let page = try await Self.summarize(jpeg)
                text += (text.isEmpty ? "" : "\n\n") + page
            } catch { self.error = (error as? API.Failure)?.message ?? "Could not read a photo." }
        }
        reading = nil; picks = []
    }

    private func save() async {
        saving = true; defer { saving = false }
        do {
            try await store.addChapter(to: book.isEmpty ? nil : book, title: newTitle, chapter: chapter, text: text)
            dismiss()
        } catch { self.error = (error as? API.Failure)?.message ?? "Could not save." }
    }

    /// Photos can be 12 MB HEIC; the server takes up to 8 MB. 2000 px JPEG reads just as well.
    static func jpeg(_ data: Data) -> Data? {
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let img = CGImageSourceCreateThumbnailAtIndex(src, 0, [kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceThumbnailMaxPixelSize: 2000] as CFDictionary) else { return nil }
        let out = NSMutableData()
        guard let dst = CGImageDestinationCreateWithData(out, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dst, img, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
        return CGImageDestinationFinalize(dst) ? out as Data : nil
    }

    static func summarize(_ jpeg: Data) async throws -> String {
        guard let token = await API.token() else { throw API.Failure(message: "Sign in first.") }
        let boundary = UUID().uuidString
        var body = Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"image\"; filename=\"page.jpg\"\r\nContent-Type: image/jpeg\r\n\r\n".utf8)
        body += jpeg + Data("\r\n--\(boundary)--\r\n".utf8)
        var req = URLRequest(url: URL(string: "https://bookrank.jaybulb.com/api/summarize-photo")!)
        req.httpMethod = "POST"; req.timeoutInterval = 60
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "content-type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        struct Out: Decodable { let text: String?; let error: String? }
        let (data, _) = try await URLSession.shared.upload(for: req, from: body)
        let out = try? JSONDecoder().decode(Out.self, from: data)
        guard let t = out?.text, !t.isEmpty else { throw API.Failure(message: out?.error ?? "Could not read a photo.") }
        return t
    }
}

extension DataStore {
    /// Append a chapter to a book (at the book's own chapter heading level) or start a new book with it.
    func addChapter(to slug: String?, title: String, chapter: String, text: String) async throws {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let slug, let e = summary(for: slug), let id = e.rowID {
            let lines = e.content.components(separatedBy: "\n")
            let mark = lines.filter { $0.hasPrefix("# ") }.count >= 2 ? "#" : "##"
            let content = e.content.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n\(mark) \(chapter)\n\n\(body)\n"
            // A content edit: updated_at moves on purpose, so the narrator scripts rebuild (highlights stay).
            _ = try await API.call("PATCH", "/rest/bookrank_summaries?id=eq.\(id)", json: ["content": content])
        } else {
            guard slug == nil else { throw API.Failure(message: "That book cannot take new chapters here. Add them on the web.") }
            let slug = title.lowercased().replacing(/[^a-z0-9]+/, with: "-").trimmingCharacters(in: CharacterSet(charactersIn: "-"))
            _ = try await API.call("POST", "/rest/bookrank_summaries", json: [
                "slug": slug.isEmpty ? "untitled" : slug, "title": title, "content": "## \(chapter)\n\n\(body)\n",
                "updated_at": Date().formatted(.iso8601)])
        }
        if let slug, Speaker.shared.slug == slug { Speaker.shared.unload() }   // so the book page picks up the new chapter
        await loadSummaries()
    }
}
