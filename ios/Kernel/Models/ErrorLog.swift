import Foundation
#if os(iOS)
import UIKit
#endif

/// The last 200 things that went wrong, kept on this device only, so a bug report can carry them.
/// Account > Data exports it as a text file; nothing is sent anywhere on its own.
enum ErrorLog {
    static let file = URL.applicationSupportDirectory.appending(path: "errors.log")
    private static let queue = DispatchQueue(label: "kernel.errorlog")

    static func note(_ what: String) {
        let line = "\(Date.now.ISO8601Format()) \(what)"
        queue.async {
            let old = (try? String(contentsOf: file, encoding: .utf8)) ?? ""
            let kept = (old.split(separator: "\n").map(String.init) + [line]).suffix(200).joined(separator: "\n") + "\n"
            try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? kept.write(to: file, atomically: true, encoding: .utf8)
        }
    }

    static var isEmpty: Bool { ((try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) == 0 }

    /// A copy to share, headed with the app version and system so the report says where it happened.
    static func export() -> URL {
        let info = Bundle.main.infoDictionary ?? [:]
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        #if os(iOS)
        let device = UIDevice.current.model
        #else
        let device = "Mac"
        #endif
        let head = "Kernel \(info["CFBundleShortVersionString"] ?? "?") (\(info["CFBundleVersion"] ?? "?")), \(device), \(os)\n\n"
        let out = FileManager.default.temporaryDirectory.appending(path: "Kernel error log.txt")
        try? (head + ((try? String(contentsOf: file, encoding: .utf8)) ?? "")).write(to: out, atomically: true, encoding: .utf8)
        return out
    }
}
