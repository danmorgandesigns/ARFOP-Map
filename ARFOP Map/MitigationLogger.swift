import Foundation

public enum MitigationEvent: String {
    case switchedToLightStyle = "Switched to lighter map style"
    case overlaysLoaded = "Overlays loaded"
    case offlineBannerShown = "Offline banner shown"
    case constrainedBannerShown = "Constrained banner shown"
}

public struct MitigationLogger {
    public static func log(_ event: MitigationEvent) {
        #if DEBUG
        print("[Mitigation] \(event.rawValue)")
        #endif
    }
}
