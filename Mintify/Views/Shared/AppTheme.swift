import SwiftUI

struct AppTheme {
    // MARK: - Backgrounds
    static let mainBackground = LinearGradient(
        colors: [
            Color(hex: "2A1B3D"), // Deep Purple
            Color(hex: "44318D")  // Dark Violet
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Accents (Gradients)
    static let storageGradient = LinearGradient(
        colors: [Color(hex: "4CC9F0"), Color(hex: "4361EE")], // Cyan to Blue
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let memoryGradient = LinearGradient(
        colors: [Color(hex: "F72585"), Color(hex: "7209B7")], // Pink to Purple
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cpuGradient = LinearGradient(
        colors: [Color(hex: "F7D754"), Color(hex: "FF9F1C")], // Yellow to Orange
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let primaryActionGradient = LinearGradient(
        colors: [Color(hex: "EB6CA4"), Color(hex: "C5DAF7")], // Neon Pink to Tropical Blue
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let mintifyGradient = LinearGradient(
        colors: [Color(hex: "EB6CA4"), Color(hex: "7209B7")], // Pink -> Purple for Brand
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let cardBackground = Color.white.opacity(0.1)
    static let cardBorder = Color.white.opacity(0.2)
    
    static let cleanPink = Color(hex: "EB6CA4")
    static let cleanCyan = Color(hex: "4CC9F0")
}

// Helper for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
