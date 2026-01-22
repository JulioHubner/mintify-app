import Foundation

/// Represents a file or directory in the disk visualization
struct DiskItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let isDirectory: Bool
    var children: [DiskItem]?
    
    var percentage: Double = 0
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var url: URL {
        URL(fileURLWithPath: path)
    }
    
    // For navigation breadcrumb
    var pathComponents: [String] {
        path.split(separator: "/").map(String.init)
    }
    
    // Hashable conformance (exclude children to avoid infinite recursion)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DiskItem, rhs: DiskItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// Category colors for different file types
enum DiskItemCategory {
    case applications
    case documents
    case media
    case developer
    case system
    case other
    
    var color: Color {
        switch self {
        case .applications: return Color(hex: "7B68EE")    // Purple
        case .documents: return Color(hex: "20B2AA")       // Teal
        case .media: return Color(hex: "FF6B6B")           // Coral
        case .developer: return Color(hex: "4ECDC4")       // Turquoise
        case .system: return Color(hex: "708090")          // Slate gray
        case .other: return Color(hex: "9CA3AF")           // Gray
        }
    }
    
    static func from(path: String) -> DiskItemCategory {
        let lowercasePath = path.lowercased()
        
        if lowercasePath.contains("/applications") {
            return .applications
        } else if lowercasePath.contains("/documents") || lowercasePath.contains("/desktop") {
            return .documents
        } else if lowercasePath.contains("/movies") || lowercasePath.contains("/music") || lowercasePath.contains("/pictures") || lowercasePath.contains("/photos") {
            return .media
        } else if lowercasePath.contains("/developer") || lowercasePath.contains("/xcode") || lowercasePath.contains("deriveddata") {
            return .developer
        } else if lowercasePath.contains("/library/caches") || lowercasePath.contains("/system") {
            return .system
        }
        
        return .other
    }
}

import SwiftUI
