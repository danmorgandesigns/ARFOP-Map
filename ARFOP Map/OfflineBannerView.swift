import SwiftUI

public struct OfflineBannerView: View {
    public enum Kind {
        case offline
        case constrained
    }

    let kind: Kind
    let message: String?

    public init(kind: Kind, message: String? = nil) {
        self.kind = kind
        self.message = message
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: kind == .offline ? "network.slash" : "network")
                .imageScale(.medium)
            Text(message ?? defaultMessage)
                .font(.footnote)
                .bold()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(kind == .offline ? Color.red.opacity(0.85) : Color.orange.opacity(0.85))
        .foregroundStyle(.white)
        .clipShape(Capsule())
        .shadow(radius: 2)
        .accessibilityAddTraits(.isStaticText)
    }

    private var defaultMessage: String {
        switch kind {
        case .offline: return "Offline. Showing cached maps and local content."
        case .constrained: return "Limited network. Using lighter map style."
        }
    }
}
