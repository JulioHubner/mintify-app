import SwiftUI
import ServiceManagement

// MARK: - Settings Tabs
enum SettingsTab: String, CaseIterable {
    case general = "general"
    case appearance = "appearance"
    case permissions = "permissions"
    case language = "language"
    
    var icon: String {
        switch self {
        case .general: return "gearshape.fill"
        case .appearance: return "paintbrush.fill"
        case .permissions: return "lock.shield.fill"
        case .language: return "globe"
        }
    }
    
    var localizedName: String {
        return "settings.\(rawValue)".localized
    }
}

struct SettingsView: View {
    @EnvironmentObject var appState: CleanerState
    @EnvironmentObject var permissionManager: PermissionManager
    @ObservedObject var themeManager = ThemeManager.shared
    @ObservedObject var localizationManager = LocalizationManager.shared
    @State private var selectedTab: SettingsTab = .general
    @State private var launchAtLogin = LaunchAtLoginHelper.isEnabled
    
    var body: some View {
        ZStack {
            AppTheme.mainBackground
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Sidebar
                settingsSidebar
                
                Divider()
                    .background(AppTheme.cardBorder)
                
                // Content
                settingsContent
            }
        }
        .frame(width: 620, height: 560)
    }
    
    // MARK: - Sidebar
    private var settingsSidebar: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(AppTheme.mintifyGradient)
                    .font(.title2)
                
                Text("settings.title".localized)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            Divider()
                .background(AppTheme.cardBorder)
                .padding(.horizontal, 16)
            
            // Tab buttons
            VStack(spacing: 4) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    SettingsSidebarButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        action: { selectedTab = tab }
                    )
                }
            }
            .padding(.vertical, 16)
            
            Spacer()
            
            // Version info
            VStack(spacing: 4) {
                Text("Mintify")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                Text("about.version".localized("1.0.0"))
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.6))
            }
            .padding(.bottom, 16)
        }
        .frame(width: 180)
        .background(AppTheme.sidebarBackground)
    }
    
    // MARK: - Content
    @ViewBuilder
    private var settingsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                switch selectedTab {
                case .general:
                    generalSection
                case .appearance:
                    appearanceSection
                case .permissions:
                    permissionsSection
                case .language:
                    languageSection
                }
            }
            .padding(28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - General Section
    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Startup Section
            sectionHeader(title: "settings.launchAtLogin".localized, subtitle: nil)
            
            HStack(spacing: 14) {
                iconBox(icon: "power.circle", color: AppTheme.cleanCyan)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("settings.launchAtLogin".localized)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                    Text("settings.launchAtLoginDesc".localized)
                        .font(.system(size: 12))
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
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBackground))
            
            Divider().background(AppTheme.cardBorder).padding(.vertical, 8)
            
            // Scan Categories Section
            sectionHeader(title: "settings.scanCategories".localized, subtitle: "settings.scanCategoriesDesc".localized)
            
            // Categories List
            VStack(spacing: 0) {
                ForEach(CleanCategory.allCases, id: \.self) { category in
                    CategoryToggleRow(
                        category: category,
                        isEnabled: Binding(
                            get: { appState.enabledCategories.contains(category) },
                            set: { enabled in handleCategoryToggle(category: category, enabled: enabled) }
                        ),
                        needsPermission: category == .trash && !permissionManager.hasTrashAccess
                    )
                    
                    if category != CleanCategory.allCases.last {
                        Divider().background(AppTheme.overlayMedium)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBackground))
            
            // Quick Actions
            HStack(spacing: 10) {
                quickActionButton(title: "settings.selectAll".localized, color: AppTheme.cleanCyan) { selectAll() }
                quickActionButton(title: "settings.deselectAll".localized, color: AppTheme.cardBackground) { deselectAll() }
                quickActionButton(title: "settings.reset".localized, color: AppTheme.cardBackground) { resetToDefault() }
            }
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader(title: "settings.theme".localized, subtitle: "settings.themeDesc".localized)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ], spacing: 14) {
                ForEach(ThemeType.allCases) { themeType in
                    ThemeSelectionCard(
                        themeType: themeType,
                        isSelected: themeManager.currentThemeType == themeType,
                        onSelect: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                themeManager.switchTheme(to: themeType)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Permissions Section
    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader(title: "permission.accessStatus".localized, subtitle: "permission.accessDesc".localized)
            
            VStack(spacing: 12) {
                permissionRow(
                    title: "permission.homeFolder".localized,
                    description: "permission.homeFolderDesc".localized,
                    hasAccess: permissionManager.hasHomeAccess,
                    action: {
                        permissionManager.requestHomeAccess { _ in }
                    }
                )
                
                permissionRow(
                    title: "permission.trash".localized,
                    description: "permission.trashDesc".localized,
                    hasAccess: permissionManager.hasTrashAccess,
                    action: {
                        permissionManager.requestTrashAccess { _ in }
                    }
                )
            }
            
            // Info card
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(AppTheme.cleanCyan)
                    .font(.system(size: 16))
                
                Text("permission.info".localized)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.cleanCyan.opacity(0.1)))
        }
    }
    
    // MARK: - Language Section
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader(title: "settings.chooseLanguage".localized, subtitle: "settings.chooseLanguageDesc".localized)
            
            VStack(spacing: 0) {
                ForEach(AppLanguage.allCases) { language in
                    LanguageRow(
                        language: language,
                        isSelected: localizationManager.currentLanguage == language,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                localizationManager.setLanguage(language)
                            }
                        }
                    )
                    
                    if language != AppLanguage.allCases.last {
                        Divider().background(AppTheme.overlayMedium)
                    }
                }
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBackground))
            
            // Note about restart
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(AppTheme.cleanCyan)
                    .font(.system(size: 16))
                
                Text("settings.restartNote".localized)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.cleanCyan.opacity(0.1)))
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(title: String, subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.8))
            }
        }
    }
    
    private func iconBox(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.2))
                .frame(width: 38, height: 38)
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(color)
        }
    }
    
    private func quickActionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(color == AppTheme.cleanCyan ? 0.2 : 1)))
        }
        .buttonStyle(.plain)
    }
    
    private func permissionRow(title: String, description: String, hasAccess: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            iconBox(icon: hasAccess ? "checkmark.shield.fill" : "lock.fill", color: hasAccess ? .green : .orange)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            if hasAccess {
                Text("permission.granted".localized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.green)
            } else {
                Button(action: action) {
                    Text("permission.grant".localized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.orange))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBackground))
    }
    
    // MARK: - Actions
    private func handleCategoryToggle(category: CleanCategory, enabled: Bool) {
        if enabled {
            if category == .trash && !permissionManager.hasTrashAccess {
                permissionManager.requestTrashAccess { success in
                    if success { appState.enabledCategories.insert(category) }
                }
            } else {
                appState.enabledCategories.insert(category)
            }
        } else {
            appState.enabledCategories.remove(category)
        }
    }
    
    private func selectAll() {
        for category in CleanCategory.allCases {
            if category == .trash && !permissionManager.hasTrashAccess { continue }
            appState.enabledCategories.insert(category)
        }
    }
    
    private func deselectAll() { appState.enabledCategories.removeAll() }
    
    private func resetToDefault() {
        appState.enabledCategories = Set(CleanCategory.allCases.filter { $0 != .trash })
    }
}

// MARK: - Sidebar Button
struct SettingsSidebarButton: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14))
                    .frame(width: 20)
                Text(tab.localizedName)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
            }
            .foregroundColor(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppTheme.cardBackground : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
    }
}

// MARK: - Category Toggle Row
struct CategoryToggleRow: View {
    let category: CleanCategory
    @Binding var isEnabled: Bool
    var needsPermission: Bool = false
    
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
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 34, height: 34)
                Image(systemName: category.icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(categoryColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(category.localizedName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                    if needsPermission {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "FF9F1C"))
                    }
                }
                Text(category.localizedDescription)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .tint(AppTheme.cleanCyan)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Theme Selection Card
struct ThemeSelectionCard: View {
    let themeType: ThemeType
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var previewTheme: AppThemeProtocol { themeType.createTheme() }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(previewTheme.mainBackground)
                        .frame(height: 44)
                    Image(systemName: themeType.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(previewTheme.mintifyGradient)
                }
                
                Text(themeType.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? AppTheme.cleanCyan : AppTheme.textPrimary)
                
                Text(themeType.description)
                    .font(.system(size: 10))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(1)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.cleanCyan : AppTheme.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Language Row
struct LanguageRow: View {
    let language: AppLanguage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Flag
                Text(language.flag)
                    .font(.system(size: 24))
                
                // Language name
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.cleanCyan)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .environmentObject(CleanerState())
        .environmentObject(PermissionManager.shared)
}
