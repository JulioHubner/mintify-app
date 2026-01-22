import Foundation

/// Service for scanning disk usage
class DiskScanner {
    static let shared = DiskScanner()
    
    private let fileManager = FileManager.default
    private var isCancelled = false
    
    /// Get the real home directory (not sandbox container)
    private var realHomeDirectory: URL {
        // In sandbox, homeDirectoryForCurrentUser returns container path
        // Use NSHomeDirectory() to get actual user home
        if let pw = getpwuid(getuid()), let homeDir = pw.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: homeDir))
        }
        // Fallback
        return fileManager.homeDirectoryForCurrentUser
    }
    
    private init() {}
    
    /// Cancel ongoing scan
    func cancelScan() {
        isCancelled = true
    }
    
    /// Scan a directory and return disk items sorted by size
    func scanDirectory(
        at url: URL,
        onProgress: @escaping (String) -> Void
    ) async -> [DiskItem] {
        isCancelled = false
        
        guard fileManager.fileExists(atPath: url.path) else {
            return []
        }
        
        var items: [DiskItem] = []
        
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .totalFileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            for itemURL in contents {
                if isCancelled { break }
                
                onProgress(itemURL.lastPathComponent)
                
                let isDirectory = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                
                let size: Int64
                if isDirectory {
                    size = calculateDirectorySize(at: itemURL)
                } else {
                    size = Int64((try? itemURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
                }
                
                let item = DiskItem(
                    name: itemURL.lastPathComponent,
                    path: itemURL.path,
                    size: size,
                    isDirectory: isDirectory,
                    children: nil
                )
                
                items.append(item)
            }
        } catch {
            print("Error scanning directory: \(error)")
        }
        
        // Sort by size descending
        items.sort { $0.size > $1.size }
        
        // Calculate percentages
        let totalSize = items.reduce(0) { $0 + $1.size }
        if totalSize > 0 {
            items = items.map { item in
                var mutableItem = item
                mutableItem.percentage = Double(item.size) / Double(totalSize) * 100
                return mutableItem
            }
        }
        
        return items
    }
    
    /// Scan home directory common folders using real home path
    func scanHomeDirectory(onProgress: @escaping (String) -> Void) async -> [DiskItem] {
        isCancelled = false
        
        let homeDir = realHomeDirectory
        
        let foldersToScan = [
            "Desktop",
            "Documents", 
            "Downloads",
            "Movies",
            "Music",
            "Pictures"
        ]
        
        var items: [DiskItem] = []
        
        for folder in foldersToScan {
            if isCancelled { break }
            
            let folderURL = homeDir.appendingPathComponent(folder)
            
            // Check if we have access
            guard fileManager.isReadableFile(atPath: folderURL.path) else { continue }
            
            onProgress("Scanning \(folder)...")
            
            let size = calculateDirectorySize(at: folderURL)
            
            // Only add if size > 0 (meaning we had access)
            if size > 0 {
                let item = DiskItem(
                    name: folder,
                    path: folderURL.path,
                    size: size,
                    isDirectory: true,
                    children: nil
                )
                items.append(item)
            }
        }
        
        // Add Applications (always accessible)
        onProgress("Scanning Applications...")
        let appsURL = URL(fileURLWithPath: "/Applications")
        let appsSize = calculateDirectorySize(at: appsURL)
        if appsSize > 0 {
            items.append(DiskItem(
                name: "Applications",
                path: appsURL.path,
                size: appsSize,
                isDirectory: true,
                children: nil
            ))
        }
        
        // Sort by size descending
        items.sort { $0.size > $1.size }
        
        // Calculate percentages
        let totalSize = items.reduce(0) { $0 + $1.size }
        if totalSize > 0 {
            items = items.map { item in
                var mutableItem = item
                mutableItem.percentage = Double(item.size) / Double(totalSize) * 100
                return mutableItem
            }
        }
        
        return items
    }
    
    /// Check if we have permission to scan a folder
    func hasPermission(for folder: String) -> Bool {
        let url = realHomeDirectory.appendingPathComponent(folder)
        return fileManager.isReadableFile(atPath: url.path)
    }
    
    /// Get real home directory path for UI
    func getHomeDirectoryPath() -> String {
        return realHomeDirectory.path
    }
    
    /// Calculate directory size recursively
    private func calculateDirectorySize(at url: URL) -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in return true } // Skip errors and continue
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            if isCancelled { break }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                if resourceValues.isRegularFile == true {
                    totalSize += Int64(resourceValues.fileSize ?? 0)
                }
            } catch {
                // Skip files we can't access
            }
        }
        
        return totalSize
    }
    
    /// Get storage overview
    func getStorageOverview() -> (total: Int64, used: Int64, free: Int64) {
        let fileURL = URL(fileURLWithPath: "/")
        
        do {
            let values = try fileURL.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ])
            
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = Int64(values.volumeAvailableCapacityForImportantUsage ?? 0)
            let used = total - free
            
            return (total, used, free)
        } catch {
            return (0, 0, 0)
        }
    }
}
