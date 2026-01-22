import Foundation

enum ScanError: Error, LocalizedError {
    case accessDenied(path: String)
    case notFound(path: String)
    
    var errorDescription: String? {
        switch self {
        case .accessDenied(let path):
            return "Access denied to \(path). Please grant permission in System Settings > Privacy & Security."
        case .notFound(let path):
            return "Path not found: \(path)"
        }
    }
}

class StorageScanner {
    
    private let fileManager = FileManager.default
    
    private var homeDir: URL {
        if let accessURL = PermissionManager.shared.homeURL {
            return accessURL
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }
    
    init() {
        print("[StorageScanner] Initialized. Using homeDir: \(homeDir.path)")
    }
    
    /// Scan all cache categories and return cleanable items
    func scanAll() -> [CleanableCategory] {
        print("[StorageScanner] Starting scanAll...")
        var categories: [CleanableCategory] = []
        
        for category in CleanCategory.allCases {
            print("[StorageScanner] Scanning category: \(category.rawValue)")
            let items = scanCategory(category)
            print("[StorageScanner] Found \(items.count) items in \(category.rawValue)")
            if !items.isEmpty {
                categories.append(CleanableCategory(category: category, items: items))
            }
        }
        
        print("[StorageScanner] Total categories with items: \(categories.count)")
        return categories
    }
    
    /// Scan a specific category
    func scanCategory(_ category: CleanCategory) -> [CleanableItem] {
        return scanCategoryWithProgress(category, onProgress: nil)
    }
    
    /// Scan a specific category with progress callback
    func scanCategoryWithProgress(_ category: CleanCategory, onProgress: ((String) -> Void)?) -> [CleanableItem] {
        switch category {
        case .userCaches:
            return scanUserCachesWithProgress(onProgress)
        case .browserCaches:
            return scanBrowserCachesWithProgress(onProgress)
        case .logs:
            return scanLogsWithProgress(onProgress)
        case .xcode:
            return scanXcodeWithProgress(onProgress)
        case .developerTools:
            return scanDeveloperToolsWithProgress(onProgress)
        case .trash:
            return scanTrashWithProgress(onProgress)
        }
    }
    
    // MARK: - Category Scanners with Progress
    
    private func scanUserCachesWithProgress(_ onProgress: ((String) -> Void)?) -> [CleanableItem] {
        let cachesPath = homeDir.appendingPathComponent("Library/Caches")
        // Exclude Apple system caches that trigger permission popups (Music, Photos, etc.)
        return scanDirectoryWithProgress(cachesPath, category: .userCaches, excludePrefixes: [
            "com.apple.Safari",
            "com.apple.Music",
            "com.apple.iTunes",
            "com.apple.AMPLibraryAgent",
            "com.apple.mediaanalysisd",
            "com.apple.Photos",
            "com.apple.photoanalysisd",
            "com.apple.amsengagementd",
            "com.apple.ap.",
            "Google",
            "Firefox",
            "org.mozilla",
            "CocoaPods",
            "Homebrew"
        ], onProgress: onProgress)
    }
    
    private func scanBrowserCachesWithProgress(_ onProgress: ((String) -> Void)?) -> [CleanableItem] {
        var items: [CleanableItem] = []
        let cachesPath = homeDir.appendingPathComponent("Library/Caches")
        
        // Safari
        onProgress?("Safari")
        let safariCache = cachesPath.appendingPathComponent("com.apple.Safari")
        if let size = calculateSize(at: safariCache), size > 0 {
            items.append(CleanableItem(name: "Safari", path: safariCache.path, size: size, category: .browserCaches))
        }
        
        // Chrome
        onProgress?("Chrome")
        let chromeCache = homeDir.appendingPathComponent("Library/Caches/Google/Chrome")
        if let size = calculateSize(at: chromeCache), size > 0 {
            items.append(CleanableItem(name: "Chrome", path: chromeCache.path, size: size, category: .browserCaches))
        }
        
        // Firefox
        onProgress?("Firefox")
        let firefoxCache = cachesPath.appendingPathComponent("org.mozilla.firefox")
        if let size = calculateSize(at: firefoxCache), size > 0 {
            items.append(CleanableItem(name: "Firefox", path: firefoxCache.path, size: size, category: .browserCaches))
        }
        
        return items
    }
    
    private func scanLogsWithProgress(_ onProgress: ((String) -> Void)?) -> [CleanableItem] {
        let logsPath = homeDir.appendingPathComponent("Library/Logs")
        return scanDirectoryWithProgress(logsPath, category: .logs, excludePrefixes: [], onProgress: onProgress)
    }
    
    private func scanXcodeWithProgress(_ onProgress: ((String) -> Void)?) -> [CleanableItem] {
        var items: [CleanableItem] = []
        
        // DerivedData
        onProgress?("DerivedData")
        let derivedData = homeDir.appendingPathComponent("Library/Developer/Xcode/DerivedData")
        if let size = calculateSize(at: derivedData), size > 0 {
            items.append(CleanableItem(name: "DerivedData", path: derivedData.path, size: size, category: .xcode))
        }
        
        // iOS Device Support
        onProgress?("iOS Device Support")
        let deviceSupport = homeDir.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport")
        if let size = calculateSize(at: deviceSupport), size > 0 {
            items.append(CleanableItem(name: "iOS Device Support", path: deviceSupport.path, size: size, category: .xcode))
        }
        
        // Archives
        onProgress?("Archives")
        let archives = homeDir.appendingPathComponent("Library/Developer/Xcode/Archives")
        if let size = calculateSize(at: archives), size > 0 {
            items.append(CleanableItem(name: "Archives", path: archives.path, size: size, category: .xcode))
        }
        
        return items
    }
    
    private func scanDeveloperToolsWithProgress(_ onProgress: ((String) -> Void)?) -> [CleanableItem] {
        var items: [CleanableItem] = []
        
        // NPM Cache
        onProgress?("NPM Cache")
        let npmCache = homeDir.appendingPathComponent(".npm")
        if let size = calculateSize(at: npmCache), size > 0 {
            items.append(CleanableItem(name: "NPM Cache", path: npmCache.path, size: size, category: .developerTools))
        }
        
        // Yarn Cache
        onProgress?("Yarn Cache")
        let yarnCache = homeDir.appendingPathComponent(".yarn/cache")
        if let size = calculateSize(at: yarnCache), size > 0 {
            items.append(CleanableItem(name: "Yarn Cache", path: yarnCache.path, size: size, category: .developerTools))
        }
        
        // Yarn Berry
        onProgress?("Yarn Berry")
        let yarnBerry = homeDir.appendingPathComponent(".cache/yarn")
        if let size = calculateSize(at: yarnBerry), size > 0 {
            items.append(CleanableItem(name: "Yarn Berry Cache", path: yarnBerry.path, size: size, category: .developerTools))
        }
        
        // pnpm store
        onProgress?("pnpm Store")
        let pnpmStore = homeDir.appendingPathComponent(".pnpm-store")
        if let size = calculateSize(at: pnpmStore), size > 0 {
            items.append(CleanableItem(name: "pnpm Store", path: pnpmStore.path, size: size, category: .developerTools))
        }
        
        // Gradle Wrapper
        onProgress?("Gradle Wrapper")
        let gradleWrapper = homeDir.appendingPathComponent(".gradle/wrapper/dists")
        if let size = calculateSize(at: gradleWrapper), size > 0 {
            items.append(CleanableItem(name: "Gradle Wrapper", path: gradleWrapper.path, size: size, category: .developerTools))
        }
        
        // Gradle Caches
        onProgress?("Gradle Caches")
        let gradleCaches = homeDir.appendingPathComponent(".gradle/caches")
        if let size = calculateSize(at: gradleCaches), size > 0 {
            items.append(CleanableItem(name: "Gradle Caches", path: gradleCaches.path, size: size, category: .developerTools))
        }
        
        // CocoaPods Cache
        onProgress?("CocoaPods")
        let cocoaPodsCache = homeDir.appendingPathComponent("Library/Caches/CocoaPods")
        if let size = calculateSize(at: cocoaPodsCache), size > 0 {
            items.append(CleanableItem(name: "CocoaPods", path: cocoaPodsCache.path, size: size, category: .developerTools))
        }
        
        // Docker data
        onProgress?("Docker")
        let dockerData = homeDir.appendingPathComponent("Library/Containers/com.docker.docker")
        if let size = calculateSize(at: dockerData), size > 0 {
            items.append(CleanableItem(name: "Docker Data", path: dockerData.path, size: size, category: .developerTools))
        }
        
        // Carthage cache
        onProgress?("Carthage")
        let carthageCache = homeDir.appendingPathComponent("Library/Caches/org.carthage.CarthageKit")
        if let size = calculateSize(at: carthageCache), size > 0 {
            items.append(CleanableItem(name: "Carthage", path: carthageCache.path, size: size, category: .developerTools))
        }
        
        // Homebrew cache
        onProgress?("Homebrew")
        let homebrewCache = homeDir.appendingPathComponent("Library/Caches/Homebrew")
        if let size = calculateSize(at: homebrewCache), size > 0 {
            items.append(CleanableItem(name: "Homebrew Cache", path: homebrewCache.path, size: size, category: .developerTools))
        }
        
        // pip cache
        onProgress?("pip Cache")
        let pipCache = homeDir.appendingPathComponent(".cache/pip")
        if let size = calculateSize(at: pipCache), size > 0 {
            items.append(CleanableItem(name: "pip Cache", path: pipCache.path, size: size, category: .developerTools))
        }
        
        return items.sorted { $0.size > $1.size }
    }
    
    private func scanTrashWithProgress(_ onProgress: ((String) -> Void)?) -> [CleanableItem] {
        var items: [CleanableItem] = []
        
        // Try multiple trash locations
        let trashPaths = [
            homeDir.appendingPathComponent(".Trash"),
            URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash")
        ]
        
        // Also try to get trash via FileManager
        var trashURL: URL?
        do {
            trashURL = try fileManager.url(for: .trashDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            print("[StorageScanner] FileManager trash URL: \(trashURL?.path ?? "nil")")
        } catch {
            print("[StorageScanner] Could not get trash directory via FileManager: \(error)")
        }
        
        // Combine all possible paths
        var allPaths = trashPaths
        if let url = trashURL {
            allPaths.insert(url, at: 0)
        }
        
        for trashPath in allPaths {
            print("[StorageScanner] Trying Trash at: \(trashPath.path)")
            print("[StorageScanner] Trash exists: \(fileManager.fileExists(atPath: trashPath.path))")
            print("[StorageScanner] Trash readable: \(fileManager.isReadableFile(atPath: trashPath.path))")
            
            guard fileManager.fileExists(atPath: trashPath.path),
                  fileManager.isReadableFile(atPath: trashPath.path) else {
                print("[StorageScanner] Cannot access Trash at \(trashPath.path)")
                continue
            }
            
            do {
                let contents = try fileManager.contentsOfDirectory(at: trashPath, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey])
                print("[StorageScanner] Found \(contents.count) items in Trash")
                
                for item in contents {
                    let name = item.lastPathComponent
                    if name.hasPrefix(".") { continue } // Skip hidden files like .DS_Store
                    
                    onProgress?(name)
                    
                    if let size = calculateSize(at: item), size > 100_000 { // Show items > 100KB
                        print("[StorageScanner] Trash item: \(name) - \(size) bytes")
                        items.append(CleanableItem(name: name, path: item.path, size: size, category: .trash))
                    }
                }
                
                // If found items, no need to try other paths
                if !items.isEmpty {
                    break
                }
                
                // If no large items but trash has contents, show total
                if items.isEmpty && !contents.isEmpty {
                    if let totalSize = calculateSize(at: trashPath), totalSize > 0 {
                        items.append(CleanableItem(name: "All Trash Items (\(contents.count) files)", path: trashPath.path, size: totalSize, category: .trash))
                        break
                    }
                }
            } catch {
                print("[StorageScanner] Error reading Trash at \(trashPath.path): \(error)")
            }
        }
        
        // If still empty, try getting size via shell (fallback)
        if items.isEmpty {
            print("[StorageScanner] All Trash access methods failed. User may need to grant Full Disk Access.")
            onProgress?("Trash (requires Full Disk Access)")
        }
        
        print("[StorageScanner] Returning \(items.count) Trash items")
        return items.sorted { $0.size > $1.size }
    }
    
    // MARK: - Helpers
    
    private func scanDirectoryWithProgress(_ url: URL, category: CleanCategory, excludePrefixes: [String] = [], onProgress: ((String) -> Void)?) -> [CleanableItem] {
        var items: [CleanableItem] = []
        
        print("[StorageScanner] Scanning directory: \(url.path)")
        print("[StorageScanner] Directory exists: \(fileManager.fileExists(atPath: url.path))")
        print("[StorageScanner] Is readable: \(fileManager.isReadableFile(atPath: url.path))")
        
        // Check if directory exists
        guard fileManager.fileExists(atPath: url.path) else {
            print("[StorageScanner] Directory does not exist: \(url.path)")
            return items
        }
        
        // Check if we can access the directory
        guard fileManager.isReadableFile(atPath: url.path) else {
            print("[StorageScanner] Access denied to: \(url.path)")
            return items
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey])
            print("[StorageScanner] Found \(contents.count) items in \(url.lastPathComponent)")
            
            for item in contents {
                let name = item.lastPathComponent
                
                // Skip excluded prefixes
                if excludePrefixes.contains(where: { name.hasPrefix($0) }) {
                    continue
                }
                
                // Report progress
                onProgress?(name)
                
                if let size = calculateSize(at: item), size > 1_000_000 { // Only show items > 1MB
                    print("[StorageScanner] Adding item: \(name) with size \(size)")
                    items.append(CleanableItem(name: name, path: item.path, size: size, category: category))
                }
            }
        } catch {
            print("[StorageScanner] Error reading directory \(url.path): \(error)")
        }
        
        print("[StorageScanner] Returning \(items.count) items from \(url.lastPathComponent)")
        return items.sorted { $0.size > $1.size }
    }
    
    /// Calculate total size of a directory recursively
    func calculateSize(at url: URL) -> Int64? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        
        // Check read permission
        guard fileManager.isReadableFile(atPath: url.path) else {
            print("[StorageScanner] Cannot read: \(url.path)")
            return nil
        }
        
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory)
        
        if !isDirectory.boolValue {
            if let attrs = try? fileManager.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int64 {
                return size
            }
            return nil
        }
        
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return nil
        }
        
        for case let fileURL as URL in enumerator {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = resourceValues.fileSize {
                totalSize += Int64(size)
            }
        }
        
        return totalSize
    }
    
    // MARK: - Cleaning
    
    func cleanItems(_ items: [CleanableItem]) -> (success: Int, failed: Int, errors: [String]) {
        var success = 0
        var failed = 0
        var errors: [String] = []
        
        for item in items {
            do {
                try fileManager.removeItem(atPath: item.path)
                success += 1
                print("[StorageScanner] Cleaned: \(item.path)")
            } catch {
                failed += 1
                let errorMsg = "Failed to clean \(item.name): \(error.localizedDescription)"
                errors.append(errorMsg)
                print("[StorageScanner] \(errorMsg)")
            }
        }
        
        return (success, failed, errors)
    }
}
