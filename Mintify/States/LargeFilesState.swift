import SwiftUI

/// App-wide state management for Large Files feature
class LargeFilesState: ObservableObject {
    @Published var files: [LargeFile] = []
    @Published var isScanning = false
    @Published var shouldStopScan = false
    @Published var scanProgress: String = ""
    
    // Filter/Sort State
    @Published var selectedFilter: FileSizeFilter = .mb100
    @Published var sizeInputText: String = "100"
    @Published var sizeUnit: SizeUnit = .mb
    @Published var sortOption: FileSortOption = .sizeDesc
    @Published var selectedCategory: FileTypeCategory = .all
    
    // Selection State
    @Published var selectedPaths: Set<String> = []
    
    let scanner = LargeFilesScanner()
}
