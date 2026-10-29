import Network

/// Whether the connection is Wi-Fi or wired and not in Low Data Mode, for downloads that can wait for it.
final class Net: @unchecked Sendable {
    static let shared = Net()
    private(set) var wifi = false
    private let monitor = NWPathMonitor()
    private init() {
        monitor.pathUpdateHandler = { [weak self] p in
            self?.wifi = p.status == .satisfied && !p.isExpensive && !p.isConstrained
            if p.status == .satisfied { Task { @MainActor in await Outbox.flush() } }   // back online: send saves made offline
        }
        monitor.start(queue: DispatchQueue(label: "kernel.net"))
    }
}
