import SwiftUI

// MARK: - Dependencies View
struct DependenciesView: View {
    let projectID: UUID
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss
    @State private var selectedA: UUID? = nil
    @State private var selectedB: UUID? = nil
    @State private var showConfirm = false

    var project: Project? { projectVM.projects.first(where: { $0.id == projectID }) }
    var steps: [RepairStep] { project?.steps.sorted(by: { $0.sortOrder < $1.sortOrder }) ?? [] }

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Add dependency section
                        addDependencySection

                        // Existing deps
                        existingDepsSection

                        Spacer().frame(height: 60)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Dependencies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss.wrappedValue.dismiss() }.foregroundColor(DS.textMuted)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: DependencyGraphView(project: project ?? Project(name: "", repairType: .fullRenovation, roomsCount: 0, startDate: Date(), notes: ""))) {
                        Image(systemName: "network").foregroundColor(DS.blue)
                    }
                }
            }
        }
        .accentColor(DS.amber)
    }

    var addDependencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Dependency")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DS.textMuted)
                .textCase(.uppercase)

            // Step A picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Step").font(.system(size: 12)).foregroundColor(DS.textMuted)
                Picker("Step A", selection: $selectedA) {
                    Text("Select step").tag(nil as UUID?)
                    ForEach(steps) { s in
                        Text(s.name).tag(s.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .foregroundColor(DS.textPrimary)
                .padding(12)
                .background(DS.cardHover)
                .cornerRadius(10)
            }

            HStack {
                Spacer()
                Image(systemName: "arrow.down")
                    .foregroundColor(DS.amber)
                    .font(.system(size: 16, weight: .medium))
                Text("depends on")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(DS.textMuted)
                Spacer()
            }

            // Step B picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Must complete first").font(.system(size: 12)).foregroundColor(DS.textMuted)
                Picker("Step B", selection: $selectedB) {
                    Text("Select dependency").tag(nil as UUID?)
                    ForEach(steps) { s in
                        Text(s.name).tag(s.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .foregroundColor(DS.textPrimary)
                .padding(12)
                .background(DS.cardHover)
                .cornerRadius(10)
            }

            Button("Add Dependency") {
                guard let a = selectedA, let b = selectedB, a != b else { return }
                projectVM.addDependency(stepA: a, dependsOn: b, in: projectID)
                selectedA = nil; selectedB = nil
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selectedA == nil || selectedB == nil || selectedA == selectedB)
        }
        .padding(16)
        .background(DS.card)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.divider, lineWidth: 1))
    }

    var existingDepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Existing Dependencies")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DS.textMuted)
                .textCase(.uppercase)

            let pairs = dependencyPairs()
            if pairs.isEmpty {
                Text("No dependencies defined")
                    .font(.system(size: 14)).foregroundColor(DS.textMuted)
                    .padding(.vertical, 8)
            } else {
                ForEach(pairs, id: \.0.id) { (stepA, stepB) in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stepA.name)
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(DS.textPrimary)
                            Text("depends on")
                                .font(.system(size: 11)).foregroundColor(DS.textMuted)
                            Text(stepB.name)
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(DS.amber)
                        }
                        Spacer()
                        Button {
                            projectVM.removeDependency(stepA: stepA.id, dependsOn: stepB.id, in: projectID)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(DS.danger)
                        }
                    }
                    .padding(12)
                    .background(DS.cardHover)
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(DS.card)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.divider, lineWidth: 1))
    }

    func dependencyPairs() -> [(RepairStep, RepairStep)] {
        var result: [(RepairStep, RepairStep)] = []
        for step in steps {
            for depID in step.dependsOnIDs {
                if let dep = steps.first(where: { $0.id == depID }) {
                    result.append((step, dep))
                }
            }
        }
        return result
    }
}

// MARK: - Dependency Graph View
struct DependencyGraphView: View {
    let project: Project
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero

    var currentProject: Project {
        projectVM.projects.first(where: { $0.id == project.id }) ?? project
    }

    var steps: [RepairStep] {
        currentProject.steps.sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack {
                    // Draw arrows
                    Canvas { context, size in
                        for (i, step) in steps.enumerated() {
                            for depID in step.dependsOnIDs {
                                if let di = steps.firstIndex(where: { $0.id == depID }) {
                                    let fromX = CGFloat(di % 3) * 180 + 90
                                    let fromY = CGFloat(di / 3) * 120 + 80
                                    let toX = CGFloat(i % 3) * 180 + 90
                                    let toY = CGFloat(i / 3) * 120 + 30

                                    var path = Path()
                                    path.move(to: CGPoint(x: fromX, y: fromY))
                                    path.addCurve(
                                        to: CGPoint(x: toX, y: toY),
                                        control1: CGPoint(x: fromX, y: fromY + 30),
                                        control2: CGPoint(x: toX, y: toY - 30)
                                    )
                                    let isConflict = steps[di].sortOrder > step.sortOrder
                                    context.stroke(path, with: .color(isConflict ? DS.danger : DS.amber.opacity(0.7)),
                                                   style: StrokeStyle(lineWidth: 2, dash: isConflict ? [4, 4] : []))
                                }
                            }
                        }
                    }

                    // Step nodes
                    ForEach(Array(steps.enumerated()), id: \.element.id) { i, step in
                        let col = i % 3
                        let row = i / 3
                        let x = CGFloat(col) * 180 + 90
                        let y = CGFloat(row) * 120 + 55

                        stepNode(step: step)
                            .position(x: x, y: y)
                    }
                }
                .frame(
                    width: max(560, CGFloat(min(steps.count, 3)) * 180 + 40),
                    height: CGFloat((steps.count + 2) / 3) * 120 + 60
                )
                .padding(20)
            }
            .scaleEffect(scale)

            // Controls
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        withAnimation { scale = max(0.5, scale - 0.2) }
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.system(size: 20)).foregroundColor(DS.textPrimary)
                            .padding(12).background(DS.card).cornerRadius(10)
                    }
                    Button {
                        withAnimation { scale = 1.0 }
                    } label: {
                        Text("Reset")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(DS.textMuted)
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(DS.card).cornerRadius(10)
                    }
                    Button {
                        withAnimation { scale = min(2.0, scale + 0.2) }
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 20)).foregroundColor(DS.textPrimary)
                            .padding(12).background(DS.card).cornerRadius(10)
                    }
                    Spacer()
                    Button {
                        projectVM.autoOrderSteps(in: project.id)
                    } label: {
                        Label("Auto Fix", systemImage: "wand.and.stars")
                            .font(.system(size: 13, weight: .bold)).foregroundColor(DS.bg0)
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(DS.amber).cornerRadius(10)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Dependency Graph")
        .navigationBarTitleDisplayMode(.inline)
    }

    func stepNode(step: RepairStep) -> some View {
        VStack(spacing: 4) {
            Text(step.name)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(step.status == .blocked ? DS.danger : DS.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            Image(systemName: step.status.icon)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: step.status.color))
        }
        .frame(width: 140, height: 60)
        .background(step.status == .blocked ? DS.danger.opacity(0.1) : DS.card)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(step.status == .blocked ? DS.danger : DS.divider, lineWidth: 1.5)
        )
    }
}

// MARK: - Errors View
struct ErrorsView: View {
    @EnvironmentObject var projectVM: ProjectViewModel

    var activeErrors: [RepairError] { projectVM.globalErrors.filter { !$0.isIgnored } }
    var ignoredErrors: [RepairError] { projectVM.globalErrors.filter { $0.isIgnored } }

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                if projectVM.globalErrors.isEmpty {
                    allClearView
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            if !activeErrors.isEmpty {
                                errorsSection(title: "Active Issues", errors: activeErrors)
                            }

                            // Suggestions
                            SuggestionsSection()

                            if !ignoredErrors.isEmpty {
                                errorsSection(title: "Ignored", errors: ignoredErrors)
                            }

                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Errors")
            .navigationBarTitleDisplayMode(.large)
        }
        .accentColor(DS.amber)
    }

    func errorsSection(title: String, errors: [RepairError]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DS.textMuted)
                .textCase(.uppercase)

            ForEach(errors) { error in
                ErrorCard(error: error)
            }
        }
    }

    var allClearView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 60)).foregroundColor(DS.success)
            Text("No Errors Detected")
                .font(.system(size: 22, weight: .bold)).foregroundColor(DS.textPrimary)
            Text("Your renovation sequence looks correct.")
                .font(.system(size: 15)).foregroundColor(DS.textMuted)
        }
    }
}

struct ErrorCard: View {
    let error: RepairError
    @EnvironmentObject var projectVM: ProjectViewModel

    var projectID: UUID? {
        projectVM.projects.first(where: { p in
            p.steps.contains(where: { $0.id == error.stepID })
        })?.id
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: error.severity == .error ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(error.severity == .error ? DS.danger : DS.warning)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 6) {
                Text(error.message)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.textPrimary)

                HStack(spacing: 8) {
                    if !error.isIgnored {
                        Button("Fix Order") {
                            if let pid = projectID {
                                projectVM.fixOrderError(error, in: pid)
                            }
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(DS.bg0)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(DS.amber)
                        .cornerRadius(7)

                        Button("Ignore") { projectVM.ignoreError(error) }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(DS.textMuted)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(DS.card)
                            .cornerRadius(7)
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(DS.divider, lineWidth: 1))
                    } else {
                        Text("Ignored")
                            .font(.system(size: 12)).foregroundColor(DS.textMuted)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(error.severity == .error ? DS.danger.opacity(0.08) : DS.warning.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(error.severity == .error ? DS.danger.opacity(0.3) : DS.warning.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Suggestions Section
struct SuggestionsSection: View {
    @EnvironmentObject var projectVM: ProjectViewModel

    var activeSuggestions: [Suggestion] { projectVM.suggestions.filter { !$0.isApplied } }

    var body: some View {
        if !activeSuggestions.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Suggestions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.textMuted)
                    .textCase(.uppercase)

                ForEach(activeSuggestions) { suggestion in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 18))
                            .foregroundColor(DS.yellow)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(suggestion.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DS.textPrimary)
                            Text(suggestion.detail)
                                .font(.system(size: 12))
                                .foregroundColor(DS.textMuted)
                            Button("Apply Suggestion") {
                                projectVM.applySuggestion(suggestion)
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(DS.bg0)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(DS.yellow)
                            .cornerRadius(7)
                        }
                    }
                    .padding(14)
                    .background(DS.yellow.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.yellow.opacity(0.2), lineWidth: 1))
                }
            }
        }
    }
}
