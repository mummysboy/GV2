import SwiftUI

extension Color {
    // Primary Background Colors - Hinge-style clean whites
    static let appBackground = Color(hex: "#FFFFFF") // Pure white background
    static let appSurface = Color(hex: "#FFFFFF") // Pure white for cards/surfaces
    static let appSurfaceSecondary = Color(hex: "#FAFAFA") // Very light gray for secondary backgrounds
    
    // Primary Text Colors - Nearly black for strong contrast
    static let appText = Color(hex: "#1A1A1A") // Almost black for primary text
    static let appTextSecondary = Color(hex: "#4A4A4A") // Dark gray for secondary text
    
    // Accent Colors - Minimal but distinct
    static let appAccent = Color(hex: "#FF5864") // Soft coral red for primary actions
    static let appAccentLight = Color(hex: "#FF7A85") // Lighter coral for hover states
    
    // Neutral Grays - Soft and elegant
    static let appGray = Color(hex: "#9B9B9B") // Medium gray for form borders
    static let appGrayLight = Color(hex: "#E0E0E0") // Light gray for dividers
    static let appGrayDark = Color(hex: "#4A4A4A") // Dark gray for emphasis
    
    // Subtle Color Additions - Optional accents
    static let appInfo = Color(hex: "#C7E1F2") // Pale blue for info boxes
    static let appHighlight = Color(hex: "#F5D6E0") // Light blush for highlights
    
    // Status Colors - iOS-style
    static let appSuccess = Color(hex: "#34C759") // iOS-style green for success
    static let appWarning = Color(hex: "#FF9500") // iOS-style orange for warnings
    static let appError = Color(hex: "#FF3B30") // iOS-style red for errors
    
    // Verification Colors
    static let appVerification = Color(hex: "#007AFF") // iOS-style blue for verification
    static let appVerificationLight = Color(hex: "#5AC8FA") // Light blue for verification states
    
    // Legacy support - keeping these for backward compatibility
    static let appBlack = appText // Map to new text color
    static let appWhite = appSurface // Map to new surface color
}

// MARK: - Design System Extensions
extension Color {
    // Shadow colors for soft drop shadows
    static let appShadow = Color.black.opacity(0.08)
    static let appShadowLight = Color.black.opacity(0.04)
    
    // Border colors
    static let appBorder = Color(hex: "#E0E0E0")
    static let appBorderLight = Color(hex: "#F0F0F0")
}

// MARK: - View Modifiers for Consistent Styling
extension View {
    // Card styling with soft shadows and rounded corners
    func hingeCard() -> some View {
        self
            .background(Color.appSurface)
            .cornerRadius(16)
            .shadow(color: .appShadow, radius: 8, x: 0, y: 2)
    }
    
    // Button styling for primary actions
    func hingePrimaryButton() -> some View {
        self
            .background(Color.appAccent)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: .appAccent.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    // Button styling for secondary actions
    func hingeSecondaryButton() -> some View {
        self
            .background(Color.appSurfaceSecondary)
            .foregroundColor(.appText)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
    }
    
    // Input field styling
    func hingeInputField() -> some View {
        self
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.appSurfaceSecondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
    }
    
    // Subtle animation for button interactions
    func hingeButtonAnimation() -> some View {
        self
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: true)
    }
    
    // Card hover effect
    func hingeCardHover() -> some View {
        self
            .scaleEffect(1.0)
            .shadow(color: .appShadow, radius: 8, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.2), value: true)
    }
    
    // Smooth transition for page changes
    func hingePageTransition() -> some View {
        self
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.easeInOut(duration: 0.3), value: true)
    }
}

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
            (a, r, g, b) = (255, 0, 0, 0)
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