import SwiftUI

@main
struct RenovaStepsApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var projectVM = ProjectViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(projectVM)
                .preferredColorScheme(appState.colorScheme)
        }
    }
}
