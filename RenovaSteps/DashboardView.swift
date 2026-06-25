import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var showAddProject = false
    @State private var showAutoPlan = false
    @State private var animateProgress = false

    var project: Project? { projectVM.activeProject }

    var currentStep: RepairStep? {
        project?.steps.first(where: { $0.status == .inProgress })
    }

    var nextStep: RepairStep? {
        guard let p = project else { return nil }
        return p.steps.sorted(by: { $0.sortOrder < $1.sortOrder })
            .first(where: { $0.status == .notStarted || $0.status == .blocked })
    }

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Header
                        dashboardHeader

                        if let p = project {
                            // Progress ring
                            progressCard(project: p)

                            // Current + Next
                            HStack(spacing: 12) {
                                stepCard(title: "Current Step", step: currentStep, color: DS.blue, icon: "arrow.clockwise.circle.fill")
                                stepCard(title: "Next Step", step: nextStep, color: DS.amber, icon: "arrow.right.circle.fill")
                            }

                            // Errors block
                            errorsBlock

                            // Quick actions
                            quickActions(project: p)
                        } else {
                            emptyState
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddProject) {
                AddProjectView()
            }
        }
    }

    var dashboardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(DS.textPrimary)
                if let p = project {
                    Text(p.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(DS.textMuted)
                }
            }
            Spacer()
            Button { showAddProject = true } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(DS.amber)
            }
        }
        .padding(.top, 16)
    }

    func progressCard(project: Project) -> some View {
        HStack(spacing: 20) {
            // Ring
            ZStack {
                Circle()
                    .stroke(DS.divider, lineWidth: 8)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(from: 0, to: animateProgress ? project.progress : 0)
                    .stroke(DS.amber, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: animateProgress)
                Text("\(Int(project.progress * 100))%")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(DS.textPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Overall Progress")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DS.textMuted)
                Text("\(project.steps.filter { $0.status == .done }.count) of \(project.steps.count) steps done")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(DS.textPrimary)
                HStack(spacing: 12) {
                    statusDot(color: DS.success, count: project.steps.filter { $0.status == .done }.count, label: "Done")
                    statusDot(color: DS.blue, count: project.steps.filter { $0.status == .inProgress }.count, label: "Active")
                    statusDot(color: DS.danger, count: project.steps.filter { $0.status == .blocked }.count, label: "Blocked")
                }
            }
            Spacer()
        }
        .padding(16)
        .background(DS.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(DS.divider, lineWidth: 1))
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { animateProgress = true } }
    }

    func statusDot(color: Color, count: Int, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(count) \(label)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DS.textMuted)
        }
    }

    func stepCard(title: String, step: RepairStep?, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon).foregroundColor(color).font(.system(size: 16))
                Text(title).font(.system(size: 12, weight: .medium)).foregroundColor(DS.textMuted)
            }
            if let s = step {
                Text(s.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(DS.textPrimary)
                    .lineLimit(2)
                Text(s.status.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: s.status.color))
            } else {
                Text("—")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(DS.textMuted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.card)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.divider, lineWidth: 1))
    }

    var errorsBlock: some View {
        HStack {
            Image(systemName: projectVM.totalErrorCount > 0 ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(projectVM.totalErrorCount > 0 ? DS.danger : DS.success)
            VStack(alignment: .leading, spacing: 2) {
                Text(projectVM.totalErrorCount > 0 ? "\(projectVM.totalErrorCount) Error(s) Detected" : "No Errors")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(DS.textPrimary)
                Text(projectVM.totalErrorCount > 0 ? "Sequence issues found" : "All steps in correct order")
                    .font(.system(size: 12))
                    .foregroundColor(DS.textMuted)
            }
            Spacer()
            if projectVM.totalErrorCount > 0 {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DS.textMuted)
            }
        }
        .padding(14)
        .background(projectVM.totalErrorCount > 0 ? DS.danger.opacity(0.1) : DS.success.opacity(0.1))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(
            projectVM.totalErrorCount > 0 ? DS.danger.opacity(0.3) : DS.success.opacity(0.3), lineWidth: 1))
    }

    func quickActions(project: Project) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DS.textMuted)

            HStack(spacing: 12) {
                NavigationLink(destination: StepListView(project: project)) {
                    quickActionBtn(icon: "list.number", label: "Add Step", color: DS.amber)
                }

                Button {
                    projectVM.autoOrderSteps(in: project.id)
                } label: {
                    quickActionBtn(icon: "wand.and.stars", label: "Auto Plan", color: DS.blue)
                }
            }

            HStack(spacing: 12) {
                NavigationLink(destination: TimelineView(project: project)) {
                    quickActionBtn(icon: "calendar", label: "Timeline", color: DS.success)
                }
                NavigationLink(destination: ReportsView(project: project)) {
                    quickActionBtn(icon: "chart.bar.fill", label: "Reports", color: DS.orange)
                }
            }
        }
    }

    func quickActionBtn(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 18))
            Text(label).font(.system(size: 14, weight: .semibold)).foregroundColor(DS.textPrimary)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(DS.textMuted)
        }
        .padding(14)
        .background(DS.card)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.divider, lineWidth: 1))
    }

    var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.badge.plus")
                .font(.system(size: 56))
                .foregroundColor(DS.amber.opacity(0.6))
                .padding(.top, 60)
            Text("No Projects Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(DS.textPrimary)
            Text("Create your first renovation project to get started.")
                .font(.system(size: 15))
                .foregroundColor(DS.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Create Project") { showAddProject = true }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 40)
        }
    }
}
