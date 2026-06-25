import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSplash = true
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            if showSplash {
                SplashView(onComplete: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showSplash = false
                        showOnboarding = !appState.hasCompletedOnboarding
                    }
                })
                .transition(.asymmetric(
                    insertion: .identity,
                    removal: .scale(scale: 1.5).combined(with: .opacity)
                ))
            } else if showOnboarding {
                OnboardingView(onComplete: {
                    appState.hasCompletedOnboarding = true
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showOnboarding = false
                    }
                })
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showSplash)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showOnboarding)
    }
}
