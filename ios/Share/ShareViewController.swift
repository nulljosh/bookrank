import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// Share to Kernel from Safari or any app: the page's address, or the selected text, saved for Kernel to turn
/// into a summary the next time it opens.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        Task { @MainActor in
            let (title, text, url) = await read()
            let host = UIHostingController(rootView: ShareView(title: title, text: text, url: url) { [weak self] item in
                if let item { Inbox.add(item) }
                self?.extensionContext?.completeRequest(returningItems: nil)
            })
            addChild(host); host.view.frame = view.bounds; host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(host.view); host.didMove(toParent: self)
        }
    }

    private func read() async -> (String, String, URL?) {
        var title = "", text = "", url: URL?
        for item in extensionContext?.inputItems as? [NSExtensionItem] ?? [] {
            if title.isEmpty, let t = item.attributedContentText?.string { title = t }
            for p in item.attachments ?? [] {
                if p.hasItemConformingToTypeIdentifier(UTType.url.identifier), let u = try? await p.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL { url = u }
                else if p.hasItemConformingToTypeIdentifier(UTType.plainText.identifier), let s = try? await p.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String { text += s }
            }
        }
        if title.isEmpty { title = url?.host() ?? String(text.prefix(40)) }
        return (title, text, url)
    }
}

