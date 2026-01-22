import Foundation
import AppKit
import SwiftUI

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var hasHomeAccess: Bool = false
    @Published var hasFullDiskAccess: Bool = false
    @Published var homeURL: URL?
    
    private let bookmarkKey = "security_scoped_bookmarks"
    
    init() {
        restoreBookmarks()
        checkPermissions()
    }
    
    func checkPermissions() {
        checkHomeAccess()
        checkFullDiskAccess()
    }
    
    private func checkHomeAccess() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let desktop = home.appendingPathComponent("Desktop")
        let documents = home.appendingPathComponent("Documents")
        let downloads = home.appendingPathComponent("Downloads")
        
        // In Sandbox with "User Selected File" entitlement, we only get access if user explicitly grants it.
        // Even if we have access to Downloads by entitlement, we prioritize checking if we have broader access.
        
        let fileManager = FileManager.default
        
        // Check if we can read Desktop and Documents
        // Note: isReadableFile might return false positives/negatives in some edge cases, 
        // but typically valid for Sandbox checks on these folders.
        let canReadDesktop = fileManager.isReadableFile(atPath: desktop.path)
        let canReadDocuments = fileManager.isReadableFile(atPath: documents.path)
        
        DispatchQueue.main.async {
            self.hasHomeAccess = canReadDesktop && canReadDocuments
        }
    }
    
    private func checkFullDiskAccess() {
        // Checking access to Trace/Trash is a common heuristic
        let trashPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        let isReadable = FileManager.default.isReadableFile(atPath: trashPath.path)
        
        DispatchQueue.main.async {
            self.hasFullDiskAccess = isReadable
        }
    }
    
    func requestHomeAccess(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let openPanel = NSOpenPanel()
            openPanel.message = "Mintify needs access to your Home folder to scan for duplicates and clean files."
            openPanel.prompt = "Grant Access"
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.treatsFilePackagesAsDirectories = false
            openPanel.allowsMultipleSelection = false
            
            // Set directory to Home
            openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser
            
            openPanel.begin { response in
                if response == .OK, let url = openPanel.url {
                    // Check if they actually selected Home or a subfolder?
                    // Ideally we want Home. but if they select Documents, we stick with that.
                    // For now, assume whatever they picked is what we get access to.
                    
                    self.saveBookmark(for: url)
                    self.checkPermissions()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    private func saveBookmark(for url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            var bookmarks = UserDefaults.standard.dictionary(forKey: bookmarkKey) ?? [:]
            bookmarks[url.path] = bookmarkData
            UserDefaults.standard.set(bookmarks, forKey: bookmarkKey)
            
            // Start accessing immediately
            if url.startAccessingSecurityScopedResource() {
                print("[PermissionManager] Started accessing: \(url.path)")
                
                DispatchQueue.main.async {
                    self.homeURL = url
                }
            }
        } catch {
            print("[PermissionManager] Failed to save bookmark: \(error)")
        }
    }
    
    func restoreBookmarks() {
        guard let bookmarks = UserDefaults.standard.dictionary(forKey: bookmarkKey) as? [String: Data] else { return }
        
        for (path, bookmarkData) in bookmarks {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if isStale {
                    print("[PermissionManager] Bookmark stale for: \(path)")
                    // Ideally check if we can regenerate it, but usually requires new permission
                }
                
                if url.startAccessingSecurityScopedResource() {
                    print("[PermissionManager] Restored access to: \(url.path)")
                    
                    // If this is likely the home folder, set it
                    if url.path.hasSuffix(NSUserName()) {
                        DispatchQueue.main.async {
                            self.homeURL = url
                        }
                    }
                } else {
                    print("[PermissionManager] Failed to start accessing, access revoked? \(url.path)")
                }
            } catch {
                print("[PermissionManager] Failed to resolve bookmark for \(path): \(error)")
            }
        }
    }
}
