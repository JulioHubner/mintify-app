import SwiftUI

/// App-wide state management for App Uninstaller feature
class AppUninstallerState: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var filteredApps: [AppInfo] = []
    @Published var selectedApp: AppInfo?
    @Published var hasScanned = false
    @Published var isScanning = false
    @Published var isFindingLeftovers = false
    @Published var searchText = ""
    @Published var scanProgress: Int = 0
    @Published var scanTotal: Int = 0
    @Published var currentScanningApp: String = ""
    
    let scanner = AppUninstallScanner.shared
    
    func filterApps(_ query: String) {
        if query.isEmpty {
            filteredApps = apps
        } else {
            filteredApps = apps.filter { $0.name.lowercased().contains(query.lowercased()) }
        }
    }
}
