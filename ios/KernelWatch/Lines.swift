import Foundation
import WatchConnectivity

final class Lines: NSObject, ObservableObject, WCSessionDelegate {
    @Published var entries: [[String: String]] = []
    private var currentIndex = -1

    override init() {
        super.init()
        loadFromDefaults()
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func nextLine() -> (title: String, text: String)? {
        guard !entries.isEmpty else { return nil }
        let next = (currentIndex + 1) % entries.count
        currentIndex = next
        let entry = entries[next]
        return (title: entry["title"] ?? "", text: entry["text"] ?? "")
    }

    private func loadFromDefaults() {
        if let stored = UserDefaults.standard.array(forKey: "lines") as? [[String: String]] {
            entries = stored
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            if let lines = applicationContext["lines"] as? [[String: String]] {
                self.entries = lines
                UserDefaults.standard.set(lines, forKey: "lines")
                self.currentIndex = -1
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
