import Foundation
import AppKit

/// Represents a single file that may be part of a duplicate group
struct DuplicateFile: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let name: String
    let size: Int64
    let createdDate: Date
    let modifiedDate: Date
    let fileType: String
    var isSelected: Bool = false
    var isOriginal: Bool = false
    
    // MARK: - Computed Properties
    
    var url: URL {
        URL(fileURLWithPath: path)
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdDate)
    }
    
    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: path)
    }
    
    var parentFolder: String {
        URL(fileURLWithPath: path).deletingLastPathComponent().lastPathComponent
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }
    
    static func == (lhs: DuplicateFile, rhs: DuplicateFile) -> Bool {
        lhs.path == rhs.path
    }
}

/// Represents a group of duplicate files with the same content hash
struct DuplicateGroup: Identifiable {
    let id = UUID()
    let hash: String
    var files: [DuplicateFile]
    
    // MARK: - Computed Properties
    
    /// Total size of all files in the group
    var totalSize: Int64 {
        files.reduce(0) { $0 + $1.size }
    }
    
    /// Size that can be recovered by deleting duplicates (all except original)
    var duplicateSize: Int64 {
        files.filter { !$0.isOriginal }.reduce(0) { $0 + $1.size }
    }
    
    /// Number of files in the group
    var fileCount: Int {
        files.count
    }
    
    /// Number of selected files
    var selectedCount: Int {
        files.filter { $0.isSelected }.count
    }
    
    /// Size of selected files
    var selectedSize: Int64 {
        files.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    /// The original file (first one, marked as isOriginal)
    var originalFile: DuplicateFile? {
        files.first { $0.isOriginal }
    }
    
    /// File type extension (from first file)
    var fileType: String {
        files.first?.fileType ?? ""
    }
    
    /// File category for filtering
    var category: DuplicateCategory {
        DuplicateCategory.from(extension: fileType)
    }
}

/// Categories for filtering duplicate files
enum DuplicateCategory: String, CaseIterable {
    case all = "All"
    case images = "Images"
    case videos = "Videos"
    case audio = "Audio"
    case documents = "Documents"
    case archives = "Archives"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .images: return "photo"
        case .videos: return "film"
        case .audio: return "music.note"
        case .documents: return "doc.text"
        case .archives: return "archivebox"
        case .other: return "doc"
        }
    }
    
    static func from(extension ext: String) -> DuplicateCategory {
        let lowercased = ext.lowercased()
        
        // Images
        if ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp", "svg", "ico", "raw", "cr2", "nef"].contains(lowercased) {
            return .images
        }
        
        // Videos
        if ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v", "mpeg", "mpg", "3gp"].contains(lowercased) {
            return .videos
        }
        
        // Audio
        if ["mp3", "wav", "flac", "aac", "m4a", "wma", "ogg", "aiff", "alac"].contains(lowercased) {
            return .audio
        }
        
        // Documents
        if ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "pages", "numbers", "key", "odt", "ods", "odp"].contains(lowercased) {
            return .documents
        }
        
        // Archives
        if ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "dmg", "iso", "pkg"].contains(lowercased) {
            return .archives
        }
        
        return .other
    }
}

/// Sort options for duplicate groups
enum DuplicateSortOption: String, CaseIterable, Identifiable {
    case sizeDesc = "Size (Largest)"
    case sizeAsc = "Size (Smallest)"
    case countDesc = "Copies (Most)"
    case countAsc = "Copies (Least)"
    case name = "Name"
    
    var id: String { rawValue }
}
