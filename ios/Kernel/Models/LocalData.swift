import Foundation

/// What Kernel keeps on this device, wiped when the account is deleted: offline books and voices, the search
/// index, covers, saves waiting to go up, the error log, Goodreads shelves and Kernel's own settings.
@MainActor enum LocalData {
    static func wipe() async {
        let fm = FileManager.default, support = URL.applicationSupportDirectory
        for name in ["voice", "meaning", "summaries.json", "outbox.json", "errors.log"] { try? fm.removeItem(at: support.appending(path: name)) }
        try? fm.removeItem(at: CoverCache.folder); CoverCache.images.removeAllObjects()
        await Goodreads.shared.signOut()
        let d = UserDefaults.standard
        for k in d.dictionaryRepresentation().keys where k.hasPrefix("kernel.") || k.hasPrefix("bookrank.") { d.removeObject(forKey: k) }
    }
}
