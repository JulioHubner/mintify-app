import IOKit

/// Helper class to get system stats like memory, CPU, and storage
class SystemStatsHelper {
    static let shared = SystemStatsHelper()
    
    private init() {}
    
    // MARK: - Memory Stats
    
    struct MemoryStats {
        let total: UInt64       // Total RAM in bytes
        let used: UInt64        // Used RAM in bytes
        let free: UInt64        // Free RAM in bytes
        let usedPercentage: Double
        
        var formattedTotal: String {
            ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .memory)
        }
        
        var formattedUsed: String {
            ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .memory)
        }
        
        var formattedFree: String {
            ByteCountFormatter.string(fromByteCount: Int64(free), countStyle: .memory)
        }
    }
    
    func getMemoryStats() -> MemoryStats {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        let pageSize = UInt64(vm_kernel_page_size)
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        
        if result == KERN_SUCCESS {
            let activeMemory = UInt64(stats.active_count) * pageSize
            _ = UInt64(stats.inactive_count) * pageSize
            let wiredMemory = UInt64(stats.wire_count) * pageSize
            let compressedMemory = UInt64(stats.compressor_page_count) * pageSize
            
            let usedMemory = activeMemory + wiredMemory + compressedMemory
            let freeMemory = totalMemory > usedMemory ? totalMemory - usedMemory : 0
            let usedPercentage = Double(usedMemory) / Double(totalMemory) * 100
            
            return MemoryStats(
                total: totalMemory,
                used: usedMemory,
                free: freeMemory,
                usedPercentage: usedPercentage
            )
        }
        
        return MemoryStats(total: totalMemory, used: 0, free: totalMemory, usedPercentage: 0)
    }
    
    // MARK: - Mac Info
    
    struct MacInfo {
        let modelName: String
        let processorName: String
        let osVersion: String
        let memorySize: String
        let volumeName: String
        let volumeTotalSize: String
    }
    
    func getMacInfo() -> MacInfo {
        // Model Name
        var model = "Mac"
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var modelChars = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &modelChars, &size, nil, 0)
        let rawModel = String(cString: modelChars)
        model = mapModelToMarketingName(rawModel)
        
        // Processor Name
        var processor = "Unknown Chip"
        size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var cpuChars = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &cpuChars, &size, nil, 0)
        processor = String(cString: cpuChars)
        
        // OS Version
        let os = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "macOS \(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        
        // Memory
        let memory = ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory)
        
        // Boot Volume Name
        let volumeName = (try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeNameKey]).volumeName) ?? "Macintosh HD"
        
        let totalSize = (try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeTotalCapacityKey]).volumeTotalCapacity) ?? 0
        let formattedTotalSize = ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file)
        
        return MacInfo(
            modelName: model,
            processorName: processor,
            osVersion: osVersion,
            memorySize: memory,
            volumeName: volumeName,
            volumeTotalSize: formattedTotalSize
        )
    }
    
    private func mapModelToMarketingName(_ modelIdentifier: String) -> String {
        let mapping: [String: String] = [
            // MacBook Air
            "Mac14,2": "MacBook Air (M2, 2022)",
            "Mac14,15": "MacBook Air (15-inch, M2, 2023)",
            "Mac15,12": "MacBook Air (13-inch, M3, 2024)",
            "Mac15,13": "MacBook Air (15-inch, M3, 2024)",
            "MacBookAir10,1": "MacBook Air (M1, 2020)",
            "MacBookAir9,1": "MacBook Air (Retina, 13-inch, 2020)",
            
            // MacBook Pro
            "MacBookPro18,3": "MacBook Pro (14-inch, 2021)",
            "MacBookPro18,4": "MacBook Pro (14-inch, 2021)",
            "MacBookPro18,1": "MacBook Pro (16-inch, 2021)",
            "MacBookPro18,2": "MacBook Pro (16-inch, 2021)",
            "MacBookPro17,1": "MacBook Pro (13-inch, M1, 2020)",
            "Mac14,9": "MacBook Pro (14-inch, M2 Pro/Max, 2023)",
            "Mac14,5": "MacBook Pro (14-inch, M2 Pro/Max, 2023)",
            "Mac14,10": "MacBook Pro (16-inch, M2 Pro/Max, 2023)",
            "Mac14,6": "MacBook Pro (16-inch, M2 Pro/Max, 2023)",
            "Mac15,3": "MacBook Pro (14-inch, M3, 2023)",
            "Mac15,6": "MacBook Pro (14-inch, M3 Pro/Max, 2023)",
            "Mac15,8": "MacBook Pro (14-inch, M3 Pro/Max, 2023)",
            "Mac15,10": "MacBook Pro (14-inch, M3 Pro/Max, 2023)",
            "Mac15,7": "MacBook Pro (16-inch, M3 Pro/Max, 2023)",
            "Mac15,9": "MacBook Pro (16-inch, M3 Pro/Max, 2023)",
            "Mac15,11": "MacBook Pro (16-inch, M3 Pro/Max, 2023)",
            
            // Mac mini
            "Macmini9,1": "Mac mini (M1, 2020)",
            "Mac14,3": "Mac mini (M2, 2023)",
            "Mac14,12": "Mac mini (M2 Pro, 2023)",
            
            // Mac Studio
            "Mac13,1": "Mac Studio (M1 Max, 2022)",
            "Mac13,2": "Mac Studio (M1 Ultra, 2022)",
            "Mac14,13": "Mac Studio (M2 Max, 2023)",
            "Mac14,14": "Mac Studio (M2 Ultra, 2023)",
            
            // iMac
            "iMac21,1": "iMac (24-inch, M1, 2021)",
            "iMac21,2": "iMac (24-inch, M1, 2021)",
            "Mac15,4": "iMac (24-inch, M3, 2023)",
            "Mac15,5": "iMac (24-inch, M3, 2023)",
            
            // Mac Pro
            "Mac14,8": "Mac Pro (2023)",
        ]
        
        return mapping[modelIdentifier] ?? modelIdentifier
    }
    
    // MARK: - CPU Stats
    
    struct CPUStats {
        let usagePercentage: Double
        let coreCount: Int
        let thermalState: ProcessInfo.ThermalState
        
        var formattedUsage: String {
            String(format: "%.0f%%", usagePercentage)
        }
        
        var thermalStateString: String {
            switch thermalState {
            case .nominal: return "Normal"
            case .fair: return "Fair"
            case .serious: return "High"
            case .critical: return "Critical"
            @unknown default: return "Unknown"
            }
        }
    }
    
    func getCPUStats() -> CPUStats {
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0
        
        let err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCpus, &cpuInfo, &numCpuInfo)
        
        // Get Thermal State
        let thermalState = ProcessInfo.processInfo.thermalState
        
        if err == KERN_SUCCESS, let cpuInfo = cpuInfo {
            var totalUser: Int32 = 0
            var totalSystem: Int32 = 0
            var totalIdle: Int32 = 0
            
            for i in 0..<Int(numCpus) {
                let offset = Int(CPU_STATE_MAX) * i
                totalUser += cpuInfo[offset + Int(CPU_STATE_USER)]
                totalSystem += cpuInfo[offset + Int(CPU_STATE_SYSTEM)]
                totalIdle += cpuInfo[offset + Int(CPU_STATE_IDLE)]
            }
            
            let totalTicks = totalUser + totalSystem + totalIdle
            let usedTicks = totalUser + totalSystem
            let usagePercentage = totalTicks > 0 ? Double(usedTicks) / Double(totalTicks) * 100 : 0
            
            // Deallocate
            let cpuInfoSize = vm_size_t(numCpuInfo) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), cpuInfoSize)
            
            return CPUStats(
                usagePercentage: min(usagePercentage, 100),
                coreCount: Int(numCpus),
                thermalState: thermalState
            )
        }
        
        return CPUStats(
            usagePercentage: 0,
            coreCount: ProcessInfo.processInfo.processorCount,
            thermalState: thermalState
        )
    }
    
    // MARK: - Storage Stats
    
    struct StorageStats {
        let total: Int64
        let used: Int64
        let free: Int64
        let usedPercentage: Double
        
        var formattedTotal: String {
            ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
        }
        
        var formattedUsed: String {
            ByteCountFormatter.string(fromByteCount: used, countStyle: .file)
        }
        
        var formattedFree: String {
            ByteCountFormatter.string(fromByteCount: free, countStyle: .file)
        }
    }
    
    func getStorageStats() -> StorageStats {
        let fileURL = URL(fileURLWithPath: "/")
        
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
            
            let total = Int64(values.volumeTotalCapacity ?? 0)
            let free = Int64(values.volumeAvailableCapacityForImportantUsage ?? 0)
            let used = total - free
            let usedPercentage = total > 0 ? Double(used) / Double(total) * 100 : 0
            
            return StorageStats(
                total: total,
                used: used,
                free: free,
                usedPercentage: usedPercentage
            )
        } catch {
            return StorageStats(total: 0, used: 0, free: 0, usedPercentage: 0)
        }
    }
    
    // MARK: - Temp Files Size
    
    // Folders that trigger Apple Media permission popup - skip them
    private let excludedCachePrefixes = [
        "com.apple.Music",
        "com.apple.iTunes",
        "com.apple.AMPLibraryAgent",
        "com.apple.mediaanalysisd",
        "com.apple.Photos",
        "com.apple.photoanalysisd",
        "com.apple.amsengagementd",
        "com.apple.Safari",
        "com.apple.ap."
    ]
    
    func getTempFilesSize() -> Int64 {
        // Only scan temporary directory, not Library/Caches (to avoid permission popups)
        let tempPath = FileManager.default.temporaryDirectory
        
        if let size = calculateDirectorySize(at: tempPath) {
            return size
        }
        
        return 0
    }
    
    var formattedTempFilesSize: String {
        ByteCountFormatter.string(fromByteCount: getTempFilesSize(), countStyle: .file)
    }
    
    private func calculateDirectorySize(at url: URL) -> Int64? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return nil }
        
        var totalSize: Int64 = 0
        
        if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                // Skip excluded folders
                let name = fileURL.lastPathComponent
                if excludedCachePrefixes.contains(where: { name.hasPrefix($0) }) {
                    enumerator.skipDescendants()
                    continue
                }
                
                if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }
        }
        
        return totalSize
    }
    
    // MARK: - Detailed Memory Stats
    
    struct DetailedMemoryStats {
        let wired: UInt64
        let compressed: UInt64
        let appMemory: UInt64 // Active + Inactive
        let swapUsed: UInt64
        let swapTotal: UInt64
        let pressurePercentage: Double 
        
        var formattedWired: String { ByteCountFormatter.string(fromByteCount: Int64(wired), countStyle: .memory) }
        var formattedCompressed: String { ByteCountFormatter.string(fromByteCount: Int64(compressed), countStyle: .memory) }
        var formattedApp: String { ByteCountFormatter.string(fromByteCount: Int64(appMemory), countStyle: .memory) }
        var formattedSwap: String { ByteCountFormatter.string(fromByteCount: Int64(swapUsed), countStyle: .memory) }
    }
    
    func getDetailedMemoryStats() -> DetailedMemoryStats {
        // reuse basic stats logic to get vm_stat
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        var wired: UInt64 = 0
        var compressed: UInt64 = 0
        var active: UInt64 = 0
        var inactive: UInt64 = 0
        
        let pageSize = UInt64(vm_kernel_page_size)
        
        if result == KERN_SUCCESS {
            wired = UInt64(stats.wire_count) * pageSize
            compressed = UInt64(stats.compressor_page_count) * pageSize
            active = UInt64(stats.active_count) * pageSize
            inactive = UInt64(stats.inactive_count) * pageSize
        }
        
        // Swap usage via sysctl
        var swapUsed: UInt64 = 0
        var swapTotal: UInt64 = 0
        
        var size = MemoryLayout<xsw_usage>.size
        var sw_usage = xsw_usage()
        // "vm.swapusage"
        let sysctlResult = sysctlbyname("vm.swapusage", &sw_usage, &size, nil, 0)
        if sysctlResult == 0 {
            swapUsed = UInt64(sw_usage.xsu_used)
            swapTotal = UInt64(sw_usage.xsu_total)
        }
        
        // Memory Pressure
        // Approximate pressure based on free + inactive vs total, or use specific API. 
        // For simplicity/compatibility, we calculate usage ratio of "wired + active" vs total (ignoring compressed/inactive as "available-ish")
        // Or better, let's use the basic stats usedPercentage for now or derive from vm statistics
        // Pressure typical logic: (Wired + Compressed) / Total * scaling factor
        let total = ProcessInfo.processInfo.physicalMemory
        let pressure = Double(wired + compressed) / Double(total) * 100.0
        
        return DetailedMemoryStats(
            wired: wired,
            compressed: compressed,
            appMemory: active + inactive,
            swapUsed: swapUsed,
            swapTotal: swapTotal,
            pressurePercentage: min(pressure * 1.5, 100) // Scaling to make it feel more representative of "pressure"
        )
    }
    
    // MARK: - Processes
    
    struct AppProcess: Identifiable {
        let id = UUID()
        let pid: Int
        let name: String
        let icon: NSImage?
        let displayValue: String // "500 MB" or "12%"
        var sortValue: Double = 0 // For internal sorting
    }
    
    enum ProcessSort {
        case cpu
        case memory
    }
    
    // Cache for CPU calculation: [PID: (UserTime, SysTime, Timestamp)]
    private var storedCPUTimes: [Int32: (user: UInt64, system: UInt64, timestamp: TimeInterval)] = [:]
    
    // Timebase info for converting Mach ticks to Nanoseconds
    private var timebaseInfo: mach_timebase_info_data_t = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info
    }()
    
    // Cache for App Icons/Names to avoid repeated lookups
    private var appMetadataCache: [Int32: (name: String, icon: NSImage?)] = [:]
    
    // MARK: - Trash Size
    
    func getTrashSize() -> Int64 {
        guard let trashURL = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first else { return 0 }
        return calculateDirectorySize(at: trashURL) ?? 0
    }
    
    func emptyTrash() {
        let source = """
        tell application "Finder"
            empty trash
        end tell
        """
        if let script = NSAppleScript(source: source) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
        }
    }
    
    // MARK: - LibProc Wrapper
    
    // Helper to keep libproc handle open
    private class LibProc {
        static let shared = LibProc()
        
        private var handle: UnsafeMutableRawPointer?
        private var proc_pidinfo_sym: UnsafeMutableRawPointer?
        private var proc_listpids_sym: UnsafeMutableRawPointer?
        private var proc_name_sym: UnsafeMutableRawPointer?
        
        init() {
            handle = dlopen("/usr/lib/libproc.dylib", RTLD_LAZY)
            if let h = handle {
                proc_pidinfo_sym = dlsym(h, "proc_pidinfo")
                proc_listpids_sym = dlsym(h, "proc_listpids")
                proc_name_sym = dlsym(h, "proc_name")
            }
        }
        
        deinit {
            if let h = handle {
                dlclose(h)
            }
        }
        
        func proc_pidinfo(_ pid: Int32, _ flavor: Int32, _ arg: UInt64, _ buffer: UnsafeMutableRawPointer?, _ buffersize: Int32) -> Int32 {
            guard let sym = proc_pidinfo_sym else { return 0 }
            typealias ProcPidInfoPrototype = @convention(c) (Int32, Int32, UInt64, UnsafeMutableRawPointer?, Int32) -> Int32
            let function = unsafeBitCast(sym, to: ProcPidInfoPrototype.self)
            return function(pid, flavor, arg, buffer, buffersize)
        }
        
        func proc_listpids(_ type: UInt32, _ typeinfo: UInt32, _ buffer: UnsafeMutableRawPointer?, _ buffersize: Int32) -> Int32 {
            guard let sym = proc_listpids_sym else { return 0 }
            typealias ProcListPidsPrototype = @convention(c) (UInt32, UInt32, UnsafeMutableRawPointer?, Int32) -> Int32
            let function = unsafeBitCast(sym, to: ProcListPidsPrototype.self)
            return function(type, typeinfo, buffer, buffersize)
        }
        
        func proc_name(_ pid: Int32, _ buffer: UnsafeMutableRawPointer?, _ buffersize: UInt32) -> Int32 {
            guard let sym = proc_name_sym else { return 0 }
            typealias ProcNamePrototype = @convention(c) (Int32, UnsafeMutableRawPointer?, UInt32) -> Int32
            let function = unsafeBitCast(sym, to: ProcNamePrototype.self)
            return function(pid, buffer, buffersize)
        }
    }

    func getTopProcesses(by sort: ProcessSort, limit: Int = 10) -> [AppProcess] {
        // 1. Get GUI apps for Icons/Nice Names first (Failsafe source)
        let workspaceApps = NSWorkspace.shared.runningApplications
        var guiAppMap: [pid_t: NSRunningApplication] = [:]
        var pids = Set<Int32>()
        
        for app in workspaceApps {
            let pid = Int32(app.processIdentifier)
            guiAppMap[app.processIdentifier] = app
            pids.insert(pid)
        }
        
        // 2. Try to get ALL PIDs (Enhanced source)
        let allPids = getAllPIDs()
        if !allPids.isEmpty {
             for pid in allPids {
                 pids.insert(pid)
             }
        }
        
        var processes: [AppProcess] = []
        let currentTime = Date().timeIntervalSince1970
        var activePIDs = Set<Int32>()
        let libProc = LibProc.shared
        
        // Prepare timebase scale (Numer / Denom)
        let timeScale = Double(timebaseInfo.numer) / Double(timebaseInfo.denom)
        
        for pid in pids {
            activePIDs.insert(pid)
            if pid <= 0 { continue }
            
            var name = "Unknown"
            var icon: NSImage?
            
            if let app = guiAppMap[pid] {
                name = app.localizedName ?? "Unknown"
                icon = app.icon
            } else {
                name = getProcessName(pid: pid)
            }
            
            var display = "—"
            var sortValue: Double = 0
            
            // Get Task Info (Memory & CPU)
            var taskInfo = proc_taskinfo()
            let taskInfoSize = Int32(MemoryLayout<proc_taskinfo>.stride)
            let result = libProc.proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &taskInfo, taskInfoSize)
            
            if result == taskInfoSize {
                let memory = Int64(taskInfo.pti_resident_size)
                
                // CPU Calculation
                let totalTime = taskInfo.pti_total_user + taskInfo.pti_total_system
                
                var cpuUsage: Double = 0
                
                if let previous = storedCPUTimes[pid] {
                    let timeDiff = currentTime - previous.timestamp
                    let rawCpuDiff = Double(totalTime) - Double(previous.user + previous.system)
                    let cpuDiffNs = rawCpuDiff * timeScale
                    
                    if timeDiff > 0 {
                        // usage = (cpuDiff_ns / 1_000_000_000) / timeDiff * 100
                        cpuUsage = (cpuDiffNs / 1_000_000_000.0) / timeDiff * 100.0
                    }
                }
                
                // Update Cache
                storedCPUTimes[pid] = (taskInfo.pti_total_user, taskInfo.pti_total_system, currentTime)
                
                if sort == .memory {
                    display = ByteCountFormatter.string(fromByteCount: memory, countStyle: .memory)
                    sortValue = Double(memory)
                } else {
                    if cpuUsage > 0.1 {
                        display = String(format: "%.1f%%", cpuUsage)
                        sortValue = cpuUsage
                    } else {
                        display = storedCPUTimes[pid] != nil ? "0.0%" : "—"
                        sortValue = 0 
                        if cpuUsage > 0 { sortValue = cpuUsage }
                    }
                }
                
                processes.append(AppProcess(pid: Int(pid), name: name, icon: icon, displayValue: display, sortValue: sortValue))
            } else if let _ = guiAppMap[pid] {
                 // Even if proc_pidinfo fails, show GUI apps if possible?
            }
        }
        
        // Clean up old PIDs from cache
        for pid in storedCPUTimes.keys {
            if !activePIDs.contains(pid) {
                storedCPUTimes.removeValue(forKey: pid)
            }
        }
        
        let sorted = processes.sorted { $0.sortValue > $1.sortValue }
        return Array(sorted.prefix(limit))
    }
    
    private func getAllPIDs() -> [Int32] {
        let initialCapacity = 4096
        var buffer = [Int32](repeating: 0, count: initialCapacity)
        let bufferSize = Int32(MemoryLayout<Int32>.stride * initialCapacity)
        
        // Use persistent handle
        let countBytes = LibProc.shared.proc_listpids(1, 0, &buffer, bufferSize) // 1 = PROC_ALL_PIDS
        
        if countBytes <= 0 { return [] }
        
        let count = Int(countBytes) / MemoryLayout<Int32>.stride
        return Array(buffer.prefix(count))
    }
    
    private func getProcessName(pid: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: 256)
        let len = LibProc.shared.proc_name(pid, &buffer, 256)
        
        if len > 0 {
            return String(cString: buffer)
        }
        return "Process \(pid)"
    }
    
    // runShell is removed as it's not usable in Sandbox
    // private func runShell...
    

    
}

// Add import for NSImage
import AppKit
