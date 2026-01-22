import Foundation
import CryptoKit
import AppKit

/// Scanner service for finding duplicate files using hash-based comparison
class DuplicateScanner {
    
    private let fileManager = FileManager.default
    
    private var homeDir: URL {
        if let accessURL = PermissionManager.shared.homeURL {
            return accessURL
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }
    
    /// Folders to scan for duplicates
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
        ".cache",
        ".Spotlight-V100",
        ".fseventsd"
    ]
    
    /// Minimum file size to consider (skip tiny files)
    private let minFileSize: Int64 = 1024 // 1KB minimum
    
    /// Buffer size for reading files (64KB)
    private let bufferSize = 64 * 1024
    
    /// Partial hash size for quick comparison (4KB)
    private let partialHashSize = 4 * 1024
    
    /// Flag to stop scanning
    var shouldStopScan = false
    
    // MARK: - Main Scanning Method
    
    /// Scan for duplicate files using 3-phase algorithm
    /// - Parameters:
    ///   - onProgress: Progress callback with current status
    /// - Returns: Array of duplicate groups
    func scanForDuplicates(onProgress: ((String, Double) -> Void)? = nil) -> [DuplicateGroup] {
        shouldStopScan = false
        
        // Phase 1: Collect all files and group by size
        onProgress?("Collecting files...", 0.0)
        let filesBySize = collectFilesBySize(onProgress: onProgress)
        
        if shouldStopScan { return [] }
        
        // Filter to only groups with 2+ files (potential duplicates)
        let potentialDuplicates = filesBySize.filter { $0.value.count >= 2 }
        
        if potentialDuplicates.isEmpty {
            return []
        }
        
        // Phase 2 & 3: Hash and group duplicates
        onProgress?("Comparing files...", 0.5)
        let duplicateGroups = findDuplicatesWithHash(sizeGroups: potentialDuplicates, onProgress: onProgress)
        
        if shouldStopScan { return [] }
        
        // Mark original file in each group
        let finalGroups = markOriginals(groups: duplicateGroups)
        
        return finalGroups.sorted { $0.duplicateSize > $1.duplicateSize }
    }
    
    // MARK: - Phase 1: Collect Files by Size
    
    private func collectFilesBySize(onProgress: ((String, Double) -> Void)?) -> [Int64: [FileInfo]] {
        var filesBySize: [Int64: [FileInfo]] = [:]
        
        for (index, folder) in foldersToScan.enumerated() {
            if shouldStopScan { break }
            
            guard fileManager.fileExists(atPath: folder.path) else { continue }
            
            let progress = Double(index) / Double(foldersToScan.count) * 0.4
            onProgress?("Scanning \(folder.lastPathComponent)...", progress)
            
            scanDirectory(folder) { fileInfo in
                if filesBySize[fileInfo.size] == nil {
                    filesBySize[fileInfo.size] = []
                }
                filesBySize[fileInfo.size]?.append(fileInfo)
            }
        }
        
        return filesBySize
    }
    
    /// Scan a directory and collect file info
    private func scanDirectory(_ directory: URL, onFile: (FileInfo) -> Void) {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey, .isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            if shouldStopScan { break }
            
            // Skip excluded folders
            if excludedFolders.contains(where: { fileURL.path.contains("/\($0)/") }) {
                enumerator.skipDescendants()
                continue
            }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey, .contentModificationDateKey, .isDirectoryKey, .isRegularFileKey, .isSymbolicLinkKey])
                
                // Skip directories and symbolic links
                if resourceValues.isDirectory == true || resourceValues.isSymbolicLink == true {
                    continue
                }
                
                // Check if regular file
                guard resourceValues.isRegularFile == true else { continue }
                
                // Get file size and skip small files
                guard let fileSize = resourceValues.fileSize, Int64(fileSize) >= minFileSize else { continue }
                
                let fileInfo = FileInfo(
                    url: fileURL,
                    size: Int64(fileSize),
                    createdDate: resourceValues.creationDate ?? Date.distantPast,
                    modifiedDate: resourceValues.contentModificationDate ?? Date.distantPast
                )
                
                onFile(fileInfo)
                
            } catch {
                // Skip files we can't access
                continue
            }
        }
    }
    
    // MARK: - Phase 2 & 3: Hash Comparison
    
    private func findDuplicatesWithHash(sizeGroups: [Int64: [FileInfo]], onProgress: ((String, Double) -> Void)?) -> [DuplicateGroup] {
        var duplicateGroups: [DuplicateGroup] = []
        let totalGroups = sizeGroups.count
        var processedGroups = 0
        
        for (_, files) in sizeGroups {
            if shouldStopScan { break }
            
            processedGroups += 1
            let progress = 0.5 + (Double(processedGroups) / Double(totalGroups)) * 0.45
            
            if let firstFile = files.first {
                onProgress?("Hashing \(firstFile.url.lastPathComponent)...", progress)
            }
            
            // Phase 2: Group by partial hash
            var partialHashGroups: [String: [FileInfo]] = [:]
            
            for file in files {
                if shouldStopScan { break }
                
                if let partialHash = calculatePartialHash(for: file.url) {
                    if partialHashGroups[partialHash] == nil {
                        partialHashGroups[partialHash] = []
                    }
                    partialHashGroups[partialHash]?.append(file)
                }
            }
            
            // Phase 3: For groups with matching partial hash, compute full hash
            for (_, partialFiles) in partialHashGroups where partialFiles.count >= 2 {
                if shouldStopScan { break }
                
                var fullHashGroups: [String: [FileInfo]] = [:]
                
                for file in partialFiles {
                    if shouldStopScan { break }
                    
                    if let fullHash = calculateFullHash(for: file.url) {
                        if fullHashGroups[fullHash] == nil {
                            fullHashGroups[fullHash] = []
                        }
                        fullHashGroups[fullHash]?.append(file)
                    }
                }
                
                // Create duplicate groups for files with same full hash
                for (hash, hashFiles) in fullHashGroups where hashFiles.count >= 2 {
                    let duplicateFiles = hashFiles.map { fileInfo -> DuplicateFile in
                        DuplicateFile(
                            path: fileInfo.url.path,
                            name: fileInfo.url.lastPathComponent,
                            size: fileInfo.size,
                            createdDate: fileInfo.createdDate,
                            modifiedDate: fileInfo.modifiedDate,
                            fileType: fileInfo.url.pathExtension
                        )
                    }
                    
                    let group = DuplicateGroup(hash: hash, files: duplicateFiles)
                    duplicateGroups.append(group)
                }
            }
        }
        
        return duplicateGroups
    }
    
    // MARK: - Hashing
    
    /// Calculate partial hash (first 4KB) for quick comparison
    private func calculatePartialHash(for url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer { try? handle.close() }
        
        guard let data = try? handle.read(upToCount: partialHashSize) else {
            return nil
        }
        
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Calculate full SHA256 hash using streaming
    private func calculateFullHash(for url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return nil
        }
        defer { try? handle.close() }
        
        var hasher = SHA256()
        
        while true {
            if shouldStopScan { return nil }
            
            guard let data = try? handle.read(upToCount: bufferSize) else {
                break
            }
            
            if data.isEmpty { break }
            
            hasher.update(data: data)
        }
        
        let hash = hasher.finalize()
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Mark Originals
    
    /// Mark the original file in each group (oldest creation date, then shortest path)
    private func markOriginals(groups: [DuplicateGroup]) -> [DuplicateGroup] {
        return groups.map { group in
            var mutableGroup = group
            
            // Sort files: oldest first, then shortest path
            let sortedFiles = group.files.sorted { file1, file2 in
                if file1.createdDate != file2.createdDate {
                    return file1.createdDate < file2.createdDate
                }
                return file1.path.count < file2.path.count
            }
            
            // Mark first one as original
            mutableGroup.files = sortedFiles.enumerated().map { index, file in
                var mutableFile = file
                mutableFile.isOriginal = (index == 0)
                return mutableFile
            }
            
            return mutableGroup
        }
    }
    
    // MARK: - Actions
    
    /// Move files to trash
    /// - Parameter files: Files to move to trash
    /// - Returns: Tuple of (success count, failed count)
    func moveToTrash(_ files: [DuplicateFile]) -> (success: Int, failed: Int) {
        var success = 0
        var failed = 0
        
        for file in files {
            do {
                try fileManager.trashItem(at: file.url, resultingItemURL: nil)
                success += 1
            } catch {
                print("[DuplicateScanner] Failed to trash: \(file.path) - \(error)")
                failed += 1
            }
        }
        
        return (success, failed)
    }
    
    /// Reveal file in Finder
    func revealInFinder(_ file: DuplicateFile) {
        NSWorkspace.shared.selectFile(file.path, inFileViewerRootedAtPath: "")
    }
    
    /// Open file with default application
    func openFile(_ file: DuplicateFile) {
        NSWorkspace.shared.open(file.url)
    }
}

// MARK: - Helper Structs

/// Internal struct for collecting file info during scanning
private struct FileInfo {
    let url: URL
    let size: Int64
    let createdDate: Date
    let modifiedDate: Date
}
