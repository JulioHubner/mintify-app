import Foundation
import AppKit

/// Service for scanning apps and finding leftovers
class AppUninstallScanner {
    static let shared = AppUninstallScanner()
    
    private let fileManager = FileManager.default
    
    /// Get the real home directory (not sandbox container)
    private var homeDir: URL {
        if let pw = getpwuid(getuid()), let homeDir = pw.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: homeDir))
        }
        return fileManager.homeDirectoryForCurrentUser
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Scan /Applications for installed apps with progress callback
    func scanInstalledApps(progress: @escaping (Int, Int, String) -> Void = { _, _, _ in }) async -> [AppInfo] {
        var apps: [AppInfo] = []
        var allAppURLs: [URL] = []
        
        let applicationsURL = URL(fileURLWithPath: "/Applications")
        let userAppsURL = homeDir.appendingPathComponent("Applications")
        
        // First collect all app URLs
        for appsDir in [applicationsURL, userAppsURL] {
            guard fileManager.fileExists(atPath: appsDir.path) else { continue }
            
            do {
                let contents = try fileManager.contentsOfDirectory(
                    at: appsDir,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )
                
                for itemURL in contents {
                    if itemURL.pathExtension.lowercased() == "app" {
                        allAppURLs.append(itemURL)
                    }
                }
            } catch {
                print("Error scanning \(appsDir): \(error)")
            }
        }
        
        let total = allAppURLs.count
        
        // Now process with progress updates
        for (index, itemURL) in allAppURLs.enumerated() {
            let appName = itemURL.deletingPathExtension().lastPathComponent
            progress(index, total, appName)
            
            if let appInfo = createAppInfo(from: itemURL) {
                apps.append(appInfo)
            }
        }
        
        // Sort by name
        apps.sort { $0.name.lowercased() < $1.name.lowercased() }
        
        progress(total, total, "Complete")
        return apps
    }
    
    /// Find leftovers for a specific app
    func findLeftovers(for app: AppInfo) async -> [LeftoverItem] {
        var leftovers: [LeftoverItem] = []
        
        guard let bundleId = app.bundleIdentifier else {
            // Try to match by app name
            leftovers.append(contentsOf: findLeftoversByName(app.name))
            return leftovers
        }
        
        // Search in various Library locations
        let libraryURL = homeDir.appendingPathComponent("Library")
        
        // Application Support
        let appSupportDir = libraryURL.appendingPathComponent("Application Support")
        leftovers.append(contentsOf: searchForLeftovers(in: appSupportDir, bundleId: bundleId, appName: app.name, type: .applicationSupport))
        
        // Caches
        let cachesDir = libraryURL.appendingPathComponent("Caches")
        leftovers.append(contentsOf: searchForLeftovers(in: cachesDir, bundleId: bundleId, appName: app.name, type: .caches))
        
        // Preferences
        let prefsDir = libraryURL.appendingPathComponent("Preferences")
        leftovers.append(contentsOf: searchForPreferences(in: prefsDir, bundleId: bundleId))
        
        // Containers
        let containersDir = libraryURL.appendingPathComponent("Containers")
        if let containerPath = searchForContainer(in: containersDir, bundleId: bundleId) {
            leftovers.append(containerPath)
        }
        
        // Logs
        let logsDir = libraryURL.appendingPathComponent("Logs")
        leftovers.append(contentsOf: searchForLeftovers(in: logsDir, bundleId: bundleId, appName: app.name, type: .logs))
        
        // Saved Application State
        let savedStateDir = libraryURL.appendingPathComponent("Saved Application State")
        leftovers.append(contentsOf: searchForSavedState(in: savedStateDir, bundleId: bundleId))
        
        return leftovers
    }
    
    /// Move leftovers to trash and reveal app in Finder if in /Applications
    /// Returns: (leftoversDeleted, leftoversFailed, appRevealed)
    func moveToTrash(app: AppInfo, includeLeftovers: Bool = true) async -> (success: Int, failed: Int, revealed: Bool) {
        var successCount = 0
        var failedCount = 0
        var appRevealed = false
        
        // For apps in /Applications, we cannot delete directly due to App Sandbox
        // Set revealed flag so UI can show instruction popup for manual deletion
        if app.path.hasPrefix("/Applications") {
            // Don't open Finder here - let the UI show instruction popup with button
            appRevealed = true
        } else {
            // For apps in ~/Applications, we can delete directly
            let success = await trashItem(at: app.url)
            if success {
                successCount += 1
            } else {
                failedCount += 1
            }
        }
        
        // Delete leftovers (these are in ~/Library, should work without admin)
        if includeLeftovers {
            for leftover in app.leftovers where leftover.isSelected {
                let success = await trashItem(at: leftover.url)
                if success {
                    successCount += 1
                } else {
                    failedCount += 1
                }
            }
        }
        
        return (successCount, failedCount, appRevealed)
    }
    
    /// Simple trash method for user-owned files
    private func trashItem(at url: URL) async -> Bool {
        do {
            try fileManager.trashItem(at: url, resultingItemURL: nil)
            return true
        } catch {
            print("Failed to trash \(url.path): \(error)")
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func createAppInfo(from url: URL) -> AppInfo? {
        let name = url.deletingPathExtension().lastPathComponent
        
        // Get bundle info
        let bundle = Bundle(url: url)
        let bundleId = bundle?.bundleIdentifier
        
        // Get icon
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 32, height: 32)
        
        // Calculate bundle size
        let size = calculateDirectorySize(at: url)
        
        return AppInfo(
            name: name,
            bundleIdentifier: bundleId,
            path: url.path,
            icon: icon,
            bundleSize: size,
            leftovers: []
        )
    }
    
    private func searchForLeftovers(in directory: URL, bundleId: String, appName: String, type: LeftoverType) -> [LeftoverItem] {
        var leftovers: [LeftoverItem] = []
        
        guard fileManager.fileExists(atPath: directory.path) else { return leftovers }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            
            for itemURL in contents {
                let itemName = itemURL.lastPathComponent.lowercased()
                let bundleIdLower = bundleId.lowercased()
                let appNameLower = appName.lowercased()
                
                // Match by bundle ID parts or app name
                let bundleComponents = bundleIdLower.components(separatedBy: ".")
                let isMatch = itemName.contains(appNameLower) ||
                              itemName.contains(bundleIdLower) ||
                              bundleComponents.last.map { itemName.contains($0) } ?? false
                
                if isMatch {
                    let size = calculateDirectorySize(at: itemURL)
                    leftovers.append(LeftoverItem(
                        path: itemURL.path,
                        name: itemURL.lastPathComponent,
                        size: size,
                        type: type
                    ))
                }
            }
        } catch {
            // Skip inaccessible directories
        }
        
        return leftovers
    }
    
    private func searchForPreferences(in directory: URL, bundleId: String) -> [LeftoverItem] {
        var leftovers: [LeftoverItem] = []
        
        guard fileManager.fileExists(atPath: directory.path) else { return leftovers }
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            
            for itemURL in contents {
                let itemName = itemURL.lastPathComponent
                
                // Match .plist files by bundle ID
                if itemName.lowercased().contains(bundleId.lowercased()) && itemURL.pathExtension == "plist" {
                    let size = (try? fileManager.attributesOfItem(atPath: itemURL.path)[.size] as? Int64) ?? 0
                    leftovers.append(LeftoverItem(
                        path: itemURL.path,
                        name: itemName,
                        size: size,
                        type: .preferences
                    ))
                }
            }
        } catch {
            // Skip inaccessible directories
        }
        
        return leftovers
    }
    
    private func searchForContainer(in directory: URL, bundleId: String) -> LeftoverItem? {
        let containerURL = directory.appendingPathComponent(bundleId)
        
        guard fileManager.fileExists(atPath: containerURL.path) else { return nil }
        
        let size = calculateDirectorySize(at: containerURL)
        return LeftoverItem(
            path: containerURL.path,
            name: bundleId,
            size: size,
            type: .containers
        )
    }
    
    private func searchForSavedState(in directory: URL, bundleId: String) -> [LeftoverItem] {
        var leftovers: [LeftoverItem] = []
        
        let savedStateURL = directory.appendingPathComponent("\(bundleId).savedState")
        
        if fileManager.fileExists(atPath: savedStateURL.path) {
            let size = calculateDirectorySize(at: savedStateURL)
            leftovers.append(LeftoverItem(
                path: savedStateURL.path,
                name: savedStateURL.lastPathComponent,
                size: size,
                type: .savedState
            ))
        }
        
        return leftovers
    }
    
    private func findLeftoversByName(_ appName: String) -> [LeftoverItem] {
        // Fallback search by app name only
        var leftovers: [LeftoverItem] = []
        let libraryURL = homeDir.appendingPathComponent("Library")
        
        let searchDirs = [
            ("Application Support", LeftoverType.applicationSupport),
            ("Caches", LeftoverType.caches)
        ]
        
        for (subDir, type) in searchDirs {
            let dirURL = libraryURL.appendingPathComponent(subDir)
            guard fileManager.fileExists(atPath: dirURL.path) else { continue }
            
            do {
                let contents = try fileManager.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
                
                for itemURL in contents {
                    if itemURL.lastPathComponent.lowercased().contains(appName.lowercased()) {
                        let size = calculateDirectorySize(at: itemURL)
                        leftovers.append(LeftoverItem(
                            path: itemURL.path,
                            name: itemURL.lastPathComponent,
                            size: size,
                            type: type
                        ))
                    }
                }
            } catch {
                // Skip inaccessible directories
            }
        }
        
        return leftovers
    }
    
    private func calculateDirectorySize(at url: URL) -> Int64 {
        var totalSize: Int64 = 0
        
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return 0 }
        
        if !isDirectory.boolValue {
            return (try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        }
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
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
}
