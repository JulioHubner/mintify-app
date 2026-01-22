import SwiftUI

/// App-wide state management for Duplicate Finder feature
class DuplicateFinderState: ObservableObject {
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var isScanning = false
    @Published var scanProgress: Double = 0
    @Published var scanStatus: String = ""
    @Published var selectedCategory: DuplicateCategory = .all
    @Published var expandedGroups: Set<UUID> = []
    @Published var sortOption: DuplicateSortOption = .sizeDesc
    
    let scanner = DuplicateScanner()
}
