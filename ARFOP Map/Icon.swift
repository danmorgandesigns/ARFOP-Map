import SwiftUI
import UIKit

enum Icon: String, CaseIterable, Identifiable, Equatable {
    case primary = "AppIcon"
    case fof     = "AppFOF"
    case foa     = "AppFOA"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .primary: return "Friends of the Arboretum"
        case .fof: return "Friends of the Farmstead"
        case .foa: return "Friends of the Arts"
        }
    }
    
    // Get the preview image for the icon
    var previewImage: UIImage {
        // Try to load from asset catalog first
        if let image = UIImage(named: "\(self.rawValue)-Preview") {
            return image
        }
        // Fallback: try to get the actual app icon (this works for the current icon)
        if self.rawValue == UIApplication.shared.alternateIconName ||
           (self == .primary && UIApplication.shared.alternateIconName == nil) {
            if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
               let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
               let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
               let iconName = iconFiles.last,
               let image = UIImage(named: iconName) {
                return image
            }
        }
        // Final fallback: placeholder
        return UIImage(systemName: "app.fill") ?? UIImage()
    }
}
