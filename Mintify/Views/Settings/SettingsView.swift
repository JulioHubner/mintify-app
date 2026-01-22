import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject var appState: CleanerState
    @State private var showTrashPermissionAlert = false
    @State private var launchAtLogin = LaunchAtLoginHelper.isEnabled
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(AppTheme.mintifyGradient)
                        .font(.title2)
                    
                    Text("Settings")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                Divider()
                    .background(AppTheme.cardBorder)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Scan Categories Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Scan Categories")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("Choose which folders to include in the scan")
                                .font(.caption)
                                .foregroundColor(AppTheme.textSecondary.opacity(0.8))
                            
                            VStack(spacing: 0) {
                                ForEach(CleanCategory.allCases, id: \.self) { category in
                                    CategoryToggleRow(
                                        category: category,
                                        isEnabled: Binding(
                                            get: { appState.enabledCategories.contains(category) },
                                            set: { enabled in
                                                if enabled {
                                                    // Check permission for Trash
                                                    if category == .trash && !PermissionHelper.hasFullDiskAccess() {
                                                        showTrashPermissionAlert = true
                                                    } else {
                                                        appState.enabledCategories.insert(category)
                                                    }
                                                } else {
                                                    appState.enabledCategories.remove(category)
                                                }
                                            }
                                        )
                                    )
                                    
                                    if category != CleanCategory.allCases.last {
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.cardBackground)
                            )
                        }
                        
                        // Quick Actions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Actions")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            HStack(spacing: 12) {
                                Button(action: { selectAll() }) {
                                    Text("Select All")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(AppTheme.cleanCyan.opacity(0.2))
                                        )
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { deselectAll() }) {
                                    Text("Deselect All")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(AppTheme.cardBackground)
                                        )
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { resetToDefault() }) {
                                    Text("Reset to Default")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(AppTheme.cardBackground)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Startup Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Startup")
                                .font(.headline)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(AppTheme.cleanCyan.opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "power.circle")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.cleanCyan)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Launch at Login")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    Text("Start Mintify automatically when you log in")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $launchAtLogin)
                                    .toggleStyle(.switch)
                                    .tint(AppTheme.cleanCyan)
                                    .onChange(of: launchAtLogin) { _, newValue in
                                        LaunchAtLoginHelper.setEnabled(newValue)
                                    }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.cardBackground)
                            )
                        }
                        
                        // Full Disk Access Info
                        if !PermissionHelper.hasFullDiskAccess() {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Permissions")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.shield")
                                        .foregroundColor(Color(hex: "FF9F1C"))
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Full Disk Access")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppTheme.textPrimary)
                                        
                                        Text("Required to scan Trash folder")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: { PermissionHelper.openFullDiskAccessSettings() }) {
                                        Text("Grant Access")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(Color(hex: "FF9F1C").opacity(0.8))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "FF9F1C").opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: "FF9F1C").opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    .padding(24)
                }
            }
        }
        .frame(width: 450, height: 500)
        .alert("Full Disk Access Required", isPresented: $showTrashPermissionAlert) {
            Button("Open Settings") {
                PermissionHelper.openFullDiskAccessSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To scan the Trash folder, Mintify needs Full Disk Access permission. Would you like to open System Settings?")
                .foregroundColor(AppTheme.textPrimary)
        }
    }
    
    // ... helper methods (selectAll, deselectAll, resetToDefault) unchanged ...
    private func selectAll() {
        for category in CleanCategory.allCases {
            if category == .trash && !PermissionHelper.hasFullDiskAccess() {
                continue // Skip trash if no permission
            }
            appState.enabledCategories.insert(category)
        }
    }
    
    private func deselectAll() {
        appState.enabledCategories.removeAll()
    }
    
    private func resetToDefault() {
        appState.enabledCategories = Set(CleanCategory.allCases.filter { $0 != .trash })
    }
}

struct CategoryToggleRow: View {
    let category: CleanCategory
    @Binding var isEnabled: Bool
    
    private var categoryColor: Color {
        switch category.color {
        case "blue": return AppTheme.cleanCyan
        case "purple": return Color(hex: "7209B7")
        case "orange": return Color(hex: "FF9F1C")
        case "cyan": return AppTheme.cleanCyan
        case "green": return .green
        case "red": return AppTheme.cleanPink
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(categoryColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(category.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if category == .trash && !PermissionHelper.hasFullDiskAccess() {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "FF9F1C"))
                    }
                }
                
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .tint(AppTheme.cleanCyan)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    SettingsView()
        .environmentObject(CleanerState())
}
