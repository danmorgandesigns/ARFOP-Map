import Foundation
import Network
import Combine

public final class NetworkStatus: ObservableObject {
    public enum State: Equatable {
        case online
        case constrained // cellular/expensive or limited
        case offline
    }

    public static let shared = NetworkStatus()

    @Published public private(set) var state: State = .online

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkStatus.Monitor")

    private init() {
        self.monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let newState: State
            if path.status == .satisfied {
                if path.isConstrained || path.isExpensive {
                    newState = .constrained
                } else {
                    newState = .online
                }
            } else {
                newState = .offline
            }
            DispatchQueue.main.async {
                if self.state != newState {
                    self.state = newState
                    #if DEBUG
                    print("[NetworkStatus] state ->", newState)
                    #endif
                }
            }
        }
        monitor.start(queue: queue)
    }
}
