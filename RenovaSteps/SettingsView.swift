import SwiftUI
import UserNotifications

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var notifPermGranted = false
    @State private var showClearConfirm = false
    @State private var showResetConfirm = false
    @State private var showNotifications = false
    @State private var showActivity = false
    @State private var exportAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Appearance
                        settingsSection(title: "Appearance") {
                            VStack(spacing: 0) {
                                HStack {
                                    Label("Theme", systemImage: "moon.fill")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(DS.textPrimary)
                                    Spacer()
                                    Picker("Theme", selection: $appState.themeMode) {
                                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                                            Text(mode.label).tag(mode)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 180)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                            }
                        }

                        // Units & Defaults
                        settingsSection(title: "Units & Defaults") {
                            VStack(spacing: 0) {
                                settingsRow {
                                    HStack {
                                        Label("Unit System", systemImage: "ruler")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(DS.textPrimary)
                                        Spacer()
                                        Picker("Units", selection: $appState.unitSystem) {
                                            Text("Metric").tag("Metric")
                                            Text("Imperial").tag("Imperial")
                                        }
                                        .pickerStyle(.menu)
                                        .foregroundColor(DS.amber)
                                    }
                                }
                                Divider().background(DS.divider).padding(.horizontal, 16)
                                settingsRow {
                                    HStack {
                                        Label("Default Step Order", systemImage: "list.number")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(DS.textPrimary)
                                        Spacer()
                                        Picker("Order", selection: $appState.defaultStepOrder) {
                                            Text("Standard").tag("Standard")
                                            Text("Custom").tag("Custom")
                                            Text("None").tag("None")
                                        }
                                        .pickerStyle(.menu)
                                        .foregroundColor(DS.amber)
                                    }
                                }
                            }
                        }

                        // Notifications
                        settingsSection(title: "Notifications") {
                            VStack(spacing: 0) {
                                settingsRow {
                                    Toggle(isOn: $appState.notificationsEnabled) {
                                        Label("Enable Notifications", systemImage: "bell.fill")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(DS.textPrimary)
                                    }
                                    .tint(DS.amber)
                                    .onChange(of: appState.notificationsEnabled) { enabled in
                                        if enabled {
                                            projectVM.requestNotificationPermission { granted in
                                                notifPermGranted = granted
                                                if granted {
                                                    scheduleReminders()
                                                }
                                            }
                                        } else {
                                            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                                        }
                                    }
                                }
                                Divider().background(DS.divider).padding(.horizontal, 16)
                                Button {
                                    showNotifications = true
                                } label: {
                                    settingsNavRow(icon: "bell.badge", label: "Manage Reminders")
                                }
                            }
                        }

                        // Data
                        settingsSection(title: "Data") {
                            VStack(spacing: 0) {
                                Button {
                                    showActivity = true
                                } label: {
                                    settingsNavRow(icon: "clock.arrow.circlepath", label: "Activity History")
                                }
                                Divider().background(DS.divider).padding(.horizontal, 16)
                                Button {
                                    exportAlert = true
                                } label: {
                                    settingsNavRow(icon: "square.and.arrow.up", label: "Export Data")
                                }
                                Divider().background(DS.divider).padding(.horizontal, 16)
                                Button {
                                    showClearConfirm = true
                                } label: {
                                    HStack {
                                        Label("Clear Activity Log", systemImage: "trash")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(DS.danger)
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                }
                            }
                        }

                        // About
                        settingsSection(title: "About") {
                            VStack(spacing: 0) {
                                settingsInfoRow(icon: "info.circle", label: "Version", value: "1.0.0")
                                Divider().background(DS.divider).padding(.horizontal, 16)
                                settingsInfoRow(icon: "hammer.fill", label: "Build", value: "Production")
                            }
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showNotifications) { NotificationsView() }
            .sheet(isPresented: $showActivity) {
                NavigationView { ActivityHistoryView() }
            }
            .alert("Clear Activity Log", isPresented: $showClearConfirm) {
                Button("Clear", role: .destructive) {
                    projectVM.activityLog = []
                    projectVM.save()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently clear all activity history.")
            }
            .alert("Export Data", isPresented: $exportAlert) {
                Button("OK") { }
            } message: {
                Text("Export functionality exports project data as JSON. Integration with Files app available in production build.")
            }
        }
        .accentColor(DS.amber)
    }

    func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DS.textMuted)
                .textCase(.uppercase)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content()
            }
            .background(DS.card)
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.divider, lineWidth: 1))
        }
    }

    func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
    }

    func settingsNavRow(icon: String, label: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(DS.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DS.textMuted)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }

    func settingsInfoRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(DS.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(DS.textMuted)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }

    func scheduleReminders() {
        for project in projectVM.projects {
            for step in project.steps {
                if let dl = step.deadline, dl > Date() {
                    let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: dl) ?? dl
                    projectVM.scheduleNotification(
                        title: "Step Due Tomorrow",
                        body: "'\(step.name)' in '\(project.name)' is due tomorrow.",
                        date: reminderDate,
                        id: "step_\(step.id.uuidString)"
                    )
                }
            }
        }
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss
    @State private var stepStartReminder = true
    @State private var blockedAlert = true
    @State private var orderViolation = true
    @State private var saved = false

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        notifRow(
                            icon: "play.circle.fill",
                            color: DS.success,
                            title: "Step Starting Tomorrow",
                            subtitle: "Remind when a step is scheduled for tomorrow",
                            isOn: $stepStartReminder
                        )
                        notifRow(
                            icon: "lock.fill",
                            color: DS.danger,
                            title: "Step Blocked",
                            subtitle: "Alert when a dependency blocks progress",
                            isOn: $blockedAlert
                        )
                        notifRow(
                            icon: "exclamationmark.triangle.fill",
                            color: DS.warning,
                            title: "Order Violation",
                            subtitle: "Notify when a step is done out of order",
                            isOn: $orderViolation
                        )

                        Button(saved ? "Saved ✓" : "Save Settings") {
                            applyNotificationSettings()
                            saved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { dismiss.wrappedValue.dismiss() }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(saved)
                        .padding(.top, 8)

                        Spacer().frame(height: 60)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss.wrappedValue.dismiss() }.foregroundColor(DS.textMuted)
                }
            }
        }
        .accentColor(DS.amber)
    }

    func notifRow(icon: String, color: Color, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 15, weight: .semibold)).foregroundColor(DS.textPrimary)
                Text(subtitle).font(.system(size: 12)).foregroundColor(DS.textMuted)
            }
            Spacer()
            Toggle("", isOn: isOn).tint(DS.amber).labelsHidden()
        }
        .padding(16)
        .background(DS.card)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.divider, lineWidth: 1))
    }

    func applyNotificationSettings() {
        guard appState.notificationsEnabled else { return }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        if stepStartReminder {
            for project in projectVM.projects {
                for step in project.steps where step.status != .done {
                    if let dl = step.deadline, dl > Date() {
                        let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: dl) ?? dl
                        if reminderDate > Date() {
                            projectVM.scheduleNotification(
                                title: "Step Due Tomorrow",
                                body: "'\(step.name)' is due tomorrow in '\(project.name)'",
                                date: reminderDate,
                                id: "start_\(step.id.uuidString)"
                            )
                        }
                    }
                }
            }
        }
        if blockedAlert {
            for project in projectVM.projects {
                for step in project.steps where step.status == .blocked {
                    projectVM.scheduleNotification(
                        title: "Step Blocked",
                        body: "'\(step.name)' is blocked in '\(project.name)'",
                        date: Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date(),
                        id: "blocked_\(step.id.uuidString)"
                    )
                }
            }
        }
        projectVM.log("Notification settings saved", icon: "bell.fill")
    }
}
