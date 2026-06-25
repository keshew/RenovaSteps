import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                ProjectsView()
                    .tag(1)
                ErrorsView()
                    .tag(2)
                TasksView()
                    .tag(3)
                SettingsView()
                    .tag(4)
            }
            .background(DS.bg0)

            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var projectVM: ProjectViewModel

    let items: [(icon: String, label: String)] = [
        ("house.fill", "Dashboard"),
        ("folder.fill", "Projects"),
        ("exclamationmark.circle.fill", "Errors"),
        ("checkmark.square.fill", "Tasks"),
        ("gearshape.fill", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedTab = i }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if i == 2 && projectVM.totalErrorCount > 0 {
                                Circle()
                                    .fill(DS.danger)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 10, y: -10)
                                    .zIndex(1)
                            }
                            Image(systemName: items[i].icon)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(selectedTab == i ? DS.amber : DS.textMuted)
                                .scaleEffect(selectedTab == i ? 1.15 : 1.0)
                        }
                        Text(items[i].label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(selectedTab == i ? DS.amber : DS.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 20)
        .background(
            DS.card
                .overlay(Divider().foregroundColor(DS.divider), alignment: .top)
                .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: -8)
        )
    }
}
