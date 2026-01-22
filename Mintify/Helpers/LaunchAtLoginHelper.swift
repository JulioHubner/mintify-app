import ServiceManagement

/// Helper class for managing launch at login functionality using SMAppService
class LaunchAtLoginHelper {
    
    /// Check if the app is set to launch at login
    static var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    /// Enable or disable launch at login
    /// - Parameter enable: True to enable, false to disable
    /// - Returns: True if the operation succeeded
    @discardableResult
    static func setEnabled(_ enable: Bool) -> Bool {
        guard #available(macOS 13.0, *) else {
            return false
        }
        
        do {
            if enable {
                if SMAppService.mainApp.status == .enabled {
                    return true // Already enabled
                }
                try SMAppService.mainApp.register()
            } else {
                if SMAppService.mainApp.status != .enabled {
                    return true // Already disabled
                }
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            print("Failed to \(enable ? "enable" : "disable") launch at login: \(error)")
            return false
        }
    }
    
    /// Get the current status as a readable string
    static var statusDescription: String {
        guard #available(macOS 13.0, *) else {
            return "Not available"
        }
        
        switch SMAppService.mainApp.status {
        case .enabled:
            return "Enabled"
        case .notRegistered:
            return "Not registered"
        case .requiresApproval:
            return "Requires approval"
        case .notFound:
            return "Not found"
        @unknown default:
            return "Unknown"
        }
    }
}
