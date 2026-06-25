import SwiftUI
import Combine

class AppState: ObservableObject {
    @AppStorage("themeMode") var themeMode: ThemeMode = .dark {
        didSet { objectWillChange.send() }
    }
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("unitSystem") var unitSystem: String = "Metric"
    @AppStorage("defaultStepOrder") var defaultStepOrder: String = "Standard"

    var colorScheme: ColorScheme? {
        switch themeMode {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}

enum ThemeMode: String, CaseIterable, Codable {
    case dark = "dark"
    case light = "light"
    case system = "system"

    var label: String {
        switch self {
        case .dark: return "Dark"
        case .light: return "Light"
        case .system: return "System"
        }
    }
}
