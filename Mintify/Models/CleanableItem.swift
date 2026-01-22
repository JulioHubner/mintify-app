import Foundation

enum CleanCategory: String, CaseIterable {
    case userCaches = "User Caches"
    case browserCaches = "Browser Caches"
    case logs = "Logs"
    case xcode = "Xcode"
    case developerTools = "Developer Tools"
    case trash = "Trash"
    
    var icon: String {
        switch self {
        case .userCaches: return "folder.badge.gearshape"
        case .browserCaches: return "globe"
        case .logs: return "doc.text"
        case .xcode: return "hammer"
        case .developerTools: return "wrench.and.screwdriver"
        case .trash: return "trash"
        }
    }
    
    var description: String {
        switch self {
        case .userCaches: return "Application caches"
        case .browserCaches: return "Safari, Chrome, Firefox caches"
        case .logs: return "Application logs"
        case .xcode: return "DerivedData & Device Support"
        case .developerTools: return "NPM, Yarn, Gradle, CocoaPods"
        case .trash: return "Items in Trash"
        }
    }
    
    var color: String {
        switch self {
        case .userCaches: return "blue"
        case .browserCaches: return "purple"
        case .logs: return "orange"
        case .xcode: return "cyan"
        case .developerTools: return "green"
        case .trash: return "red"
        }
    }
}

struct CleanableItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let category: CleanCategory
    var isSelected: Bool = false
    var accessError: String? = nil
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct CleanableCategory: Identifiable {
    let id = UUID()
    let category: CleanCategory
    var items: [CleanableItem]
    var isSelected: Bool = false
    
    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var selectedSize: Int64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
}
