import SwiftUI

struct AboutView: View {
    var body: some View {
        ZStack {
            // Background
            AppTheme.mainBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Title bar spacer
                Spacer()
                    .frame(height: 28)
                
                // App Icon
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 96, height: 96)
                
                // App Name
                Text("Mintify")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                
                // Version
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("Version \(version) (\(build))")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                // Description
                Text("Clean, Optimize & Monitor Your Mac")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.textSecondary)
                
                Divider()
                    .background(AppTheme.cardBorder)
                    .padding(.horizontal, 40)
                
                // Author Info
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .foregroundColor(AppTheme.cleanCyan)
                            .frame(width: 20)
                        Text("Yellow Studio Labs")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(AppTheme.cleanCyan)
                            .frame(width: 20)
                        Link("yellowstudio.vn@gmail.com", destination: URL(string: "mailto:yellowstudio.vn@gmail.com")!)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .foregroundColor(AppTheme.cleanCyan)
                            .frame(width: 20)
                        Link("GitHub Repository", destination: URL(string: "https://github.com/yellowstudio-labs/mintify-app")!)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.cleanCyan)
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                    .background(AppTheme.cardBorder)
                    .padding(.horizontal, 40)
                
                // Copyright
                VStack(spacing: 4) {
                    Text("Open Source under MIT License")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text("© 2025 Yellow Studio Labs. All rights reserved.")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.textSecondary.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .frame(width: 340, height: 480)
    }
}

#Preview {
    AboutView()
}
