import UIKit
import SwiftUI
import OSLog

@MainActor
@Observable class Model {
    var appIcon: Icon
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Model")
    
    init() {
        let iconName = UIApplication.shared.alternateIconName
        
        if let iconName, let icon = Icon(rawValue: iconName) {
            appIcon = icon
        } else {
            appIcon = .primary
        }
    }
    
    func setAlternateAppIcon(icon: Icon) {
        let iconName: String? = (icon != .primary) ? icon.rawValue : nil
        
        guard UIApplication.shared.alternateIconName != iconName else { return }
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error {
                self.logger.error("Failed to update app icon: \(error)")
            }
        }
        
        appIcon = icon
    }
}
