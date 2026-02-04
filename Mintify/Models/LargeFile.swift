import Foundation
import AppKit

/// Represents a large file found on the system
struct LargeFile: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let name: String
    let size: Int64
    let modifiedDate: Date
    let fileType: String
    var isSelected: Bool = false
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: modifiedDate)
    }
    
    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: path)
    }
    
    var url: URL {
        URL(fileURLWithPath: path)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
    
    static func == (lhs: LargeFile, rhs: LargeFile) -> Bool {
        lhs.path == rhs.path
    }
}

/// Size filter options for large files finder
enum FileSizeFilter: Int, CaseIterable, Identifiable {
    case mb100 = 100
    case mb500 = 500
    case gb1 = 1024
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .mb100: return "100 MB"
        case .mb500: return "500 MB"
        case .gb1: return "1 GB"
        }
    }
    
    var bytes: Int64 {
        Int64(rawValue) * 1024 * 1024
    }
}

/// Sort options for file list
enum FileSortOption: String, CaseIterable, Identifiable {
    case sizeDesc = "sizeDesc"
    case sizeAsc = "sizeAsc"
    case dateDesc = "dateDesc"
    case dateAsc = "dateAsc"
    case name = "name"
    
    var id: String { rawValue }
    
    /// Localized display name
    var localizedName: String {
        return "sort.\(rawValue)".localized
    }
}

/// File type/location category
enum FileTypeCategory: String, CaseIterable, Identifiable {
    case all = "all"
    case downloads = "downloads"
    case desktop = "desktop"
    case documents = "documents"
    case videos = "videos"
    case images = "images"
    case archives = "archives"
    case apps = "apps"
    case other = "other"
    
    var id: String { rawValue }
    
    /// Localized display name
    var localizedName: String {
        return "fileType.\(rawValue)".localized
    }
    
    var icon: String {
        switch self {
        case .all: return "doc.fill"
        case .downloads: return "arrow.down.circle.fill"
        case .desktop: return "desktopcomputer"
        case .documents: return "doc.text.fill"
        case .videos: return "film.fill"
        case .images: return "photo.fill"
        case .archives: return "archivebox.fill"
        case .apps: return "app.fill"
        case .other: return "questionmark.folder.fill"
        }
    }
    
    /// Check if file path matches this category
    static func category(forPath path: String, fileExtension: String) -> FileTypeCategory {
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        
        // Check location-based categories first
        if path.hasPrefix("\(homePath)/Downloads/") { return .downloads }
        if path.hasPrefix("\(homePath)/Desktop/") { return .desktop }
        
        // Then check file type
        return category(for: fileExtension)
    }
    
    static func category(for fileExtension: String) -> FileTypeCategory {
        let ext = fileExtension.lowercased()
        
        let documents = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "pages", "numbers", "keynote"]
        let videos = ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v"]
        let images = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "raw", "psd", "ai"]
        let archives = ["zip", "rar", "7z", "tar", "gz", "dmg", "iso", "pkg"]
        let apps = ["app"]
        
        if documents.contains(ext) { return .documents }
        if videos.contains(ext) { return .videos }
        if images.contains(ext) { return .images }
        if archives.contains(ext) { return .archives }
        if apps.contains(ext) { return .apps }
        return .other
    }
}

