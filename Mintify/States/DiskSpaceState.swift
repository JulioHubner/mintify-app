import SwiftUI

/// App-wide state management for Disk Space Visualizer feature
class DiskSpaceState: ObservableObject {
    @Published var diskItems: [DiskItem] = []
    @Published var isScanning = false
    @Published var hasScanned = false
    @Published var scanStatus: String = ""
    @Published var currentPath: [DiskItem] = []
    @Published var storageOverview: (total: Int64, used: Int64, free: Int64) = (0, 0, 0)
    
    let scanner = DiskScanner.shared
    
    func loadStorageOverview() {
        storageOverview = scanner.getStorageOverview()
    }
}
