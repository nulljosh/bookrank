#if os(iOS)
import CarPlay

/// CarPlay audio: your books as a list (the one you are partway through first), tap one to keep listening, and
/// the system's Now Playing screen for the rest. Inert until Apple grants the CarPlay audio entitlement; then add
/// `com.apple.developer.carplay-audio` to Kernel.entitlements and nothing else changes.
final class CarPlayScene: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interface: CPInterfaceController?

    func templateApplicationScene(_ scene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        interface = interfaceController
        Task { @MainActor in interfaceController.setRootTemplate(Self.library(), animated: false, completion: nil) }
    }
    func templateApplicationScene(_ scene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        interface = nil
    }

    @MainActor private static func library() -> CPListTemplate {
        let shelf = DataStore.shelf(), started = DataStore.lastStarted()
        let books = (started.map { [$0] } ?? []) + shelf.filter { $0.slug != started?.slug }
        let items = books.prefix(100).map { e in
            let item = CPListItem(text: e.title, detailText: e.slug == started?.slug ? String(localized: "Continue") : nil)
            item.handler = { _, done in
                NoteTap.shared.play = true; NoteTap.shared.slug = e.slug   // the same path as Siri's Continue my book
                done()
            }
            return item
        }
        let t = CPListTemplate(title: "Kernel", sections: [CPListSection(items: Array(items))])
        t.emptyViewTitleVariants = [String(localized: "No books yet")]
        return t
    }
}
#endif
