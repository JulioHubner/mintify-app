import SwiftUI

/// Tab navigation for main window
enum MainTab: String, CaseIterable {
    case cleaner = "cleaner"
    case largeFiles = "largeFiles"
    case duplicates = "duplicates"
    case memory = "memory"
    case diskSpace = "diskSpace"
    case uninstaller = "uninstaller"
    case settings = "settings"
    
    var icon: String {
        switch self {
        case .cleaner: return "sparkles"
        case .largeFiles: return "doc.badge.clock"
        case .duplicates: return "doc.on.doc"
        case .memory: return "memorychip"
        case .diskSpace: return "chart.pie"
        case .uninstaller: return "trash.circle"
        case .settings: return "gearshape.fill"
        }
    }
    
    /// Localized display name for the tab
    var localizedName: String {
        return "tab.\(rawValue)".localized
    }
}
