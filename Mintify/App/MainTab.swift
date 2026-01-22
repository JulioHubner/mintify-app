import SwiftUI

/// Tab navigation for main window
enum MainTab: String, CaseIterable {
    case cleaner = "Cleaner"
    case largeFiles = "Large Files"
    case duplicates = "Duplicates"
    case memory = "Memory"
    case diskSpace = "Disk Space"
    case uninstaller = "Uninstaller"
    case settings = "Settings"
    
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
}
