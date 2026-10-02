#if os(iOS)
import Foundation
import WatchConnectivity

final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()

    private override init() {
        super.init()
    }

    func activate() {
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func push(_ entries: [SummaryEntry]) {
        guard WCSession.default.activationState == .activated else { return }
        guard WCSession.default.isPaired, WCSession.default.isWatchAppInstalled else { return }
        let lines = Nudge.lines(from: entries)
        try? WCSession.default.updateApplicationContext(["lines": lines])
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
#endif
