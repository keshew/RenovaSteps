import SwiftUI

struct DS {
    // Backgrounds
    static let bg0 = Color(hex: "#0F172A")
    static let bg1 = Color(hex: "#111827")
    static let bg2 = Color(hex: "#1A1F2E")
    static let card = Color(hex: "#1E293B")
    static let cardHover = Color(hex: "#263244")
    static let divider = Color(hex: "#334155")

    // Accents
    static let orange = Color(hex: "#F97316")
    static let yellow = Color(hex: "#EAB308")
    static let yellowBright = Color(hex: "#FDE047")
    static let amber = Color(hex: "#FACC15")
    static let amberSoft = Color(hex: "#FB923C")
    static let amberLight = Color(hex: "#FDBA74")
    static let blue = Color(hex: "#3B82F6")
    static let blueSoft = Color(hex: "#60A5FA")

    // Status
    static let success = Color(hex: "#22C55E")
    static let info = Color(hex: "#3B82F6")
    static let warning = Color(hex: "#FACC15")
    static let danger = Color(hex: "#EF4444")

    // Text
    static let textPrimary = Color(hex: "#F8FAFC")
    static let textSecondary = Color(hex: "#CBD5E1")
    static let textMuted = Color(hex: "#64748B")

    // Glows
    static let glowYellow = Color(hex: "#FACC15").opacity(0.35)
    static let glowOrange = Color(hex: "#F97316").opacity(0.3)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(DS.bg0)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DS.amber)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
            .shadow(color: DS.glowYellow, radius: 8, x: 0, y: 4)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(DS.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DS.card)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.divider, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DS.danger)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SmallPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(DS.bg0)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(DS.amber)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SmallSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(DS.textSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(DS.card)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.divider, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
