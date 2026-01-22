import SwiftUI

struct PermissionBannerView: View {
    let onOpenSettings: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Full Disk Access Required")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Grant permission to scan Trash folder")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            Button(action: onOpenSettings) {
                Text("Open Settings")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.8))
                    )
            }
            .buttonStyle(.plain)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// Helper to check and open Full Disk Access
struct PermissionHelper {
    
    /// Check if app has Full Disk Access by trying to read .Trash
    static func hasFullDiskAccess() -> Bool {
        let trashPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        return FileManager.default.isReadableFile(atPath: trashPath.path)
    }
    
    /// Open System Settings to Full Disk Access pane
    static func openFullDiskAccessSettings() {
        // Try macOS 13+ URL first
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        } else if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Show an alert prompting user to grant Full Disk Access
    static func showPermissionAlert() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            
            let alert = NSAlert()
            alert.messageText = "Full Disk Access Required"
            alert.informativeText = """
            Mintify needs Full Disk Access to scan your Trash folder.
            
            To grant access:
            1. Click "Open Settings"
            2. Find Mintify in the list (or click + to add it)
            3. Enable the toggle
            4. Restart Mintify
            """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Later")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                openFullDiskAccessSettings()
            }
        }
    }
}

#Preview {
    PermissionBannerView(
        onOpenSettings: {},
        onDismiss: {}
    )
    .padding()
    .background(Color.black)
}
