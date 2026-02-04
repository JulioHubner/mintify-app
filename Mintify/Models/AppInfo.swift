import Foundation
import AppKit

/// Represents an installed application
struct AppInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String?
    let path: String
    let icon: NSImage?
    let bundleSize: Int64
    
    var leftovers: [LeftoverItem] = []
    var isSelected: Bool = false
    
    var totalSize: Int64 {
        bundleSize + leftovers.reduce(0) { $0 + $1.size }
    }
    
    var formattedBundleSize: String {
        ByteCountFormatter.string(fromByteCount: bundleSize, countStyle: .file)
    }
    
    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var formattedLeftoversSize: String {
        let size = leftovers.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var url: URL {
        URL(fileURLWithPath: path)
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents a leftover file/folder from an app
struct LeftoverItem: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let name: String
    let size: Int64
    let type: LeftoverType
    var isSelected: Bool = true
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var url: URL {
        URL(fileURLWithPath: path)
    }
}

/// Types of leftover files
enum LeftoverType: String, CaseIterable {
    case applicationSupport = "applicationSupport"
    case preferences = "preferences"
    case caches = "caches"
    case containers = "containers"
    case logs = "logs"
    case savedState = "savedState"
    case other = "other"
    
    /// Localized display name
    var localizedName: String {
        return "leftover.\(rawValue)".localized
    }
    
    var icon: String {
        switch self {
        case .applicationSupport: return "folder.fill"
        case .preferences: return "gearshape.fill"
        case .caches: return "archivebox.fill"
        case .containers: return "shippingbox.fill"
        case .logs: return "doc.text.fill"
        case .savedState: return "clock.fill"
        case .other: return "questionmark.folder.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .applicationSupport: return Color(hex: "7B68EE")
        case .preferences: return Color(hex: "20B2AA")
        case .caches: return Color(hex: "FF6B6B")
        case .containers: return Color(hex: "4ECDC4")
        case .logs: return Color(hex: "FFD93D")
        case .savedState: return Color(hex: "6BCB77")
        case .other: return Color(hex: "9CA3AF")
        }
    }
}

import SwiftUI
