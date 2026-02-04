import Foundation
import AppKit

/// Scanner service for finding large files on the system
class LargeFilesScanner {
    
    private let fileManager = FileManager.default
    
    private var homeDir: URL {
        // Use ensureHomeAccess() to guarantee security-scoped access is active
        return PermissionManager.shared.ensureHomeAccess() ?? FileManager.default.homeDirectoryForCurrentUser
    }
    
    /// Folders to scan for large files
    private var foldersToScan: [URL] {
        [
            homeDir.appendingPathComponent("Desktop"),
            homeDir.appendingPathComponent("Documents"),
            homeDir.appendingPathComponent("Downloads"),
            homeDir.appendingPathComponent("Movies"),
            homeDir.appendingPathComponent("Music"),
            homeDir.appendingPathComponent("Pictures"),
        ]
    }
    
    /// Folders to exclude from scanning
    private let excludedFolders = [
        ".Trash",
        ".git",
        "node_modules",
        ".npm",
        "Library",
        ".cache"
    ]
    
    /// Scan for large files above the minimum size
    /// - Parameters:
    ///   - minSize: Minimum file size in bytes
    ///   - onProgress: Progress callback with current folder name
    /// - Returns: Array of large files found
    func scanForLargeFiles(minSize: Int64, onProgress: ((String) -> Void)? = nil) -> [LargeFile] {
        var largeFiles: [LargeFile] = []
        
        for folder in foldersToScan {
            guard fileManager.fileExists(atPath: folder.path) else { continue }
            
            onProgress?(folder.lastPathComponent)
            
            let files = scanDirectory(folder, minSize: minSize)
            largeFiles.append(contentsOf: files)
        }
        
        // Sort by size descending
        return largeFiles.sorted { $0.size > $1.size }
    }
    
    /// Scan a single directory recursively
    private func scanDirectory(_ directory: URL, minSize: Int64) -> [LargeFile] {
        var files: [LargeFile] = []
        
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return files
        }
        
        for case let fileURL as URL in enumerator {
            // Skip excluded folders
            if excludedFolders.contains(where: { fileURL.path.contains("/\($0)/") }) {
                enumerator.skipDescendants()
                continue
            }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey, .isRegularFileKey])
                
                // Skip directories
                if resourceValues.isDirectory == true {
                    continue
                }
                
                // Check if regular file
                guard resourceValues.isRegularFile == true else { continue }
                
                // Get file size
                guard let fileSize = resourceValues.fileSize, Int64(fileSize) >= minSize else { continue }
                
                // Get modification date
                let modDate = resourceValues.contentModificationDate ?? Date.distantPast
                
                // Get file extension for type
                let fileType = fileURL.pathExtension
                
                let largeFile = LargeFile(
                    path: fileURL.path,
                    name: fileURL.lastPathComponent,
                    size: Int64(fileSize),
                    modifiedDate: modDate,
                    fileType: fileType
                )
                
                files.append(largeFile)
                
            } catch {
                // Skip files we can't access
                continue
            }
        }
        
        return files
    }
    
    /// Move files to trash
    /// - Parameter files: Files to move to trash
    /// - Returns: Tuple of (success count, failed count)
    func moveToTrash(_ files: [LargeFile]) -> (success: Int, failed: Int) {
        var success = 0
        var failed = 0
        
        for file in files {
            do {
                try fileManager.trashItem(at: file.url, resultingItemURL: nil)
                success += 1
            } catch {
                print("[LargeFilesScanner] Failed to trash: \(file.path) - \(error)")
                failed += 1
            }
        }
        
        return (success, failed)
    }
    
    /// Reveal file in Finder
    func revealInFinder(_ file: LargeFile) {
        NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "")
    }
    
    /// Open file with default application
    func openFile(_ file: LargeFile) {
        NSWorkspace.shared.open(file.url)
    }
}
