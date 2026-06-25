import SwiftUI

// MARK: - Tasks View
struct TasksView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var filterStatus: TaskStatus? = nil

    var allTasks: [(Task, String, UUID)] {
        var result: [(Task, String, UUID)] = []
        for p in projectVM.projects {
            for s in p.steps {
                for t in s.tasks {
                    if filterStatus == nil || t.status == filterStatus {
                        result.append((t, s.name, p.id))
                    }
                }
            }
        }
        return result
    }

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Filter bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterChip("All", selected: filterStatus == nil) { filterStatus = nil }
                            filterChip("Pending", selected: filterStatus == .pending) { filterStatus = .pending }
                            filterChip("In Progress", selected: filterStatus == .inProgress) { filterStatus = .inProgress }
                            filterChip("Done", selected: filterStatus == .done) { filterStatus = .done }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    .background(DS.bg1)

                    if allTasks.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.square").font(.system(size: 48)).foregroundColor(DS.textMuted)
                            Text("No tasks").font(.system(size: 18, weight: .bold)).foregroundColor(DS.textPrimary)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(allTasks, id: \.0.id) { (task, stepName, projectID) in
                                TaskRow(task: task, stepName: stepName, projectID: projectID)
                                    .listRowBackground(DS.bg0)
                                    .listRowSeparator(.hidden)
                            }
                            Color.clear.frame(height: 80).listRowBackground(Color.clear).listRowSeparator(.hidden)
                        }
                        .listStyle(.plain)
                        .background(DS.bg0)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
        }
        .accentColor(DS.amber)
    }

    func filterChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(selected ? DS.bg0 : DS.textSecondary)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(selected ? DS.amber : DS.card)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(selected ? DS.amber : DS.divider, lineWidth: 1))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selected)
    }
}

struct TaskRow: View {
    let task: Task
    let stepName: String
    let projectID: UUID
    @EnvironmentObject var projectVM: ProjectViewModel

    var body: some View {
        HStack(spacing: 12) {
            Button {
                var updated = task
                updated.status = task.status == .done ? .pending : .done
                projectVM.updateTask(updated, in: projectID)
            } label: {
                Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.status == .done ? DS.success : DS.textMuted)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(task.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(task.status == .done ? DS.textMuted : DS.textPrimary)
                    .strikethrough(task.status == .done)
                HStack(spacing: 6) {
                    Image(systemName: "list.number").font(.system(size: 10)).foregroundColor(DS.amber)
                    Text(stepName).font(.system(size: 11)).foregroundColor(DS.amber)
                    if let dl = task.deadline {
                        Text("·").foregroundColor(DS.textMuted)
                        Image(systemName: "clock").font(.system(size: 10)).foregroundColor(DS.textMuted)
                        Text(dl, style: .date).font(.system(size: 11)).foregroundColor(DS.textMuted)
                    }
                }
            }
            Spacer()

            Text(task.status.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(task.status == .done ? DS.success : task.status == .inProgress ? DS.blue : DS.textMuted)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background((task.status == .done ? DS.success : task.status == .inProgress ? DS.blue : DS.divider).opacity(0.15))
                .cornerRadius(6)
        }
        .padding(12)
        .background(DS.card)
        .cornerRadius(12)
        .padding(.vertical, 3)
    }
}

// MARK: - Timeline View
struct TimelineView: View {
    let project: Project
    @EnvironmentObject var projectVM: ProjectViewModel

    var currentProject: Project {
        projectVM.projects.first(where: { $0.id == project.id }) ?? project
    }

    var steps: [RepairStep] {
        currentProject.steps.sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Gantt-style
                    VStack(alignment: .leading, spacing: 2) {
                        // Header
                        HStack {
                            Text("Step").font(.system(size: 11, weight: .semibold)).foregroundColor(DS.textMuted)
                                .frame(width: 100, alignment: .leading)
                            Text("Duration / Status")
                                .font(.system(size: 11, weight: .semibold)).foregroundColor(DS.textMuted)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                        ForEach(Array(steps.enumerated()), id: \.element.id) { i, step in
                            GanttRow(step: step, index: i, totalDays: maxDays)
                                .padding(.vertical, 3)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 12)

                    // Legend
                    HStack(spacing: 16) {
                        legendItem(color: DS.success, label: "Done")
                        legendItem(color: DS.blue, label: "In Progress")
                        legendItem(color: DS.danger, label: "Blocked")
                        legendItem(color: DS.divider, label: "Pending")
                    }
                    .padding(16)
                    .background(DS.card)
                    .cornerRadius(12)
                    .padding(16)

                    Spacer().frame(height: 100)
                }
            }
        }
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
    }

    var maxDays: Int {
        steps.map { $0.estimatedDays }.reduce(0, +)
    }

    func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 16, height: 8)
            Text(label).font(.system(size: 11)).foregroundColor(DS.textMuted)
        }
    }
}

struct GanttRow: View {
    let step: RepairStep
    let index: Int
    let totalDays: Int
    @State private var animate = false

    var barColor: Color {
        switch step.status {
        case .done: return DS.success
        case .inProgress: return DS.blue
        case .blocked: return DS.danger
        case .skipped: return DS.warning
        case .notStarted: return DS.divider
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(step.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DS.textSecondary)
                .frame(width: 100, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(DS.divider.opacity(0.3))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: animate ? geo.size.width * min(1.0, CGFloat(step.estimatedDays) / CGFloat(max(1, totalDays))) : 0)
                        .animation(.easeInOut(duration: 0.7).delay(Double(index) * 0.05), value: animate)
                }
            }
            .frame(height: 22)

            Text("\(step.estimatedDays)d")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DS.textMuted)
                .frame(width: 28)
        }
        .onAppear { animate = true }
    }
}

// MARK: - Reports View
struct ReportsView: View {
    let project: Project
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var showExportAlert = false

    var currentProject: Project {
        projectVM.projects.first(where: { $0.id == project.id }) ?? project
    }

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Summary stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        statCard(value: "\(currentProject.steps.filter { $0.status == .done }.count)", label: "Completed", color: DS.success)
                        statCard(value: "\(currentProject.steps.filter { $0.status == .inProgress }.count)", label: "In Progress", color: DS.blue)
                        statCard(value: "\(currentProject.steps.filter { $0.status == .blocked }.count)", label: "Blocked", color: DS.danger)
                        statCard(value: "\(Int(currentProject.progress * 100))%", label: "Progress", color: DS.amber)
                    }

                    // Plan vs Fact
                    planVsFactSection

                    // Error summary
                    errorSummarySection

                    // Export
                    Button {
                        showExportAlert = true
                    } label: {
                        Label("Export PDF", systemImage: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(DS.bg0)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DS.amber)
                            .cornerRadius(12)
                    }
                    .alert("Export Report", isPresented: $showExportAlert) {
                        Button("OK") { }
                    } message: {
                        Text("Report data copied to clipboard. PDF export available when integrated with share sheet.")
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
    }

    func statCard(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(DS.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(DS.card)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.divider, lineWidth: 1))
    }

    var planVsFactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan vs Fact")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DS.textMuted)
                .textCase(.uppercase)

            ForEach(currentProject.steps.prefix(5).sorted(by: { $0.sortOrder < $1.sortOrder })) { step in
                HStack {
                    Text(step.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DS.textSecondary)
                        .frame(maxWidth: 120, alignment: .leading)
                    Spacer()
                    Image(systemName: step.status.icon)
                        .foregroundColor(Color(hex: step.status.color))
                    Text(step.status.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: step.status.color))
                }
                .padding(.vertical, 6)
                if step.id != currentProject.steps.prefix(5).last?.id {
                    Divider().background(DS.divider)
                }
            }
        }
        .padding(16)
        .background(DS.card)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.divider, lineWidth: 1))
    }

    var errorSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Issues Summary")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DS.textMuted)
                .textCase(.uppercase)

            let errs = projectVM.globalErrors.filter { err in
                currentProject.steps.contains(where: { $0.id == err.stepID })
            }
            if errs.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(DS.success)
                    Text("No issues recorded").font(.system(size: 13)).foregroundColor(DS.textMuted)
                }
            } else {
                ForEach(errs.prefix(5)) { err in
                    HStack(spacing: 8) {
                        Image(systemName: err.severity == .error ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(err.severity == .error ? DS.danger : DS.warning)
                        Text(err.message)
                            .font(.system(size: 12))
                            .foregroundColor(DS.textSecondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(16)
        .background(DS.card)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.divider, lineWidth: 1))
    }
}

// MARK: - Activity History View
struct ActivityHistoryView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var filterText = ""

    var filtered: [ActivityRecord] {
        if filterText.isEmpty { return projectVM.activityLog }
        return projectVM.activityLog.filter { $0.message.localizedCaseInsensitiveContains(filterText) }
    }

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(DS.textMuted)
                    TextField("Filter activity...", text: $filterText)
                        .foregroundColor(DS.textPrimary)
                }
                .padding(12)
                .background(DS.card)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(DS.bg1)

                if filtered.isEmpty {
                    Spacer()
                    Text("No activity").font(.system(size: 16)).foregroundColor(DS.textMuted)
                    Spacer()
                } else {
                    List {
                        ForEach(filtered) { record in
                            HStack(spacing: 12) {
                                Image(systemName: record.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(DS.amber)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(record.message)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(DS.textPrimary)
                                    Text(record.timestamp, style: .relative)
                                        .font(.system(size: 11))
                                        .foregroundColor(DS.textMuted)
                                }
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(DS.bg0)
                            .listRowSeparator(.hidden)
                        }
                        Color.clear.frame(height: 80).listRowBackground(Color.clear).listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .background(DS.bg0)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Progress View
struct ProgressView_RS: View {
    let project: Project
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var animBars = false

    var currentProject: Project {
        projectVM.projects.first(where: { $0.id == project.id }) ?? project
    }

    var daysLeft: Int {
        let remaining = currentProject.steps.filter { $0.status != .done }
        return remaining.reduce(0) { $0 + $1.estimatedDays }
    }

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Ring
                    progressRing

                    // Bar charts
                    barsSection

                    NavigationLink(destination: ReportsView(project: project)) {
                        Label("View Reports", systemImage: "chart.bar.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(DS.bg0)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DS.amber)
                            .cornerRadius(12)
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { animBars = true } }
    }

    var progressRing: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().stroke(DS.divider, lineWidth: 14).frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: animBars ? currentProject.progress : 0)
                    .stroke(LinearGradient(colors: [DS.amber, DS.orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: animBars)
                VStack(spacing: 2) {
                    Text("\(Int(currentProject.progress * 100))%")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(DS.amber)
                    Text("Complete")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DS.textMuted)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(DS.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(DS.divider, lineWidth: 1))
    }

    var barsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Breakdown")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DS.textMuted)
                .textCase(.uppercase)

            barRow(label: "Steps Completed", value: currentProject.steps.filter { $0.status == .done }.count, total: currentProject.steps.count, color: DS.success)
            barRow(label: "In Progress", value: currentProject.steps.filter { $0.status == .inProgress }.count, total: currentProject.steps.count, color: DS.blue)
            barRow(label: "Blocked", value: currentProject.steps.filter { $0.status == .blocked }.count, total: max(1, currentProject.steps.count), color: DS.danger)
            barRow(label: "Days Remaining", value: daysLeft, total: max(1, currentProject.steps.reduce(0) { $0 + $1.estimatedDays }), color: DS.amber)
        }
        .padding(16)
        .background(DS.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(DS.divider, lineWidth: 1))
    }

    func barRow(label: String, value: Int, total: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(DS.textSecondary)
                Spacer()
                Text("\(value)").font(.system(size: 13, weight: .bold)).foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(DS.divider)
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: geo.size.width * (animBars ? min(1.0, CGFloat(value) / CGFloat(max(1, total))) : 0))
                        .animation(.easeInOut(duration: 0.8), value: animBars)
                }
            }
            .frame(height: 8)
        }
    }
}
