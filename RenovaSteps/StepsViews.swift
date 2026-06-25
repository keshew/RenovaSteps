import SwiftUI

// MARK: - Step List View
struct StepListView: View {
    let project: Project
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var showAddStep = false
    @State private var showDependencies = false
    @State private var isReordering = false

    var currentProject: Project {
        projectVM.projects.first(where: { $0.id == project.id }) ?? project
    }

    var sortedSteps: [RepairStep] {
        currentProject.steps.sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            VStack(spacing: 0) {
                // Action bar
                HStack(spacing: 10) {
                    Button {
                        showAddStep = true
                    } label: {
                        Label("Add Step", systemImage: "plus")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DS.bg0)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(DS.amber)
                            .cornerRadius(8)
                    }

                    Button {
                        withAnimation { isReordering.toggle() }
                    } label: {
                        Label(isReordering ? "Done" : "Reorder", systemImage: "arrow.up.arrow.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DS.textSecondary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(DS.card)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.divider, lineWidth: 1))
                    }

                    Spacer()

                    NavigationLink(destination: DependencyGraphView(project: currentProject)) {
                        Label("Graph", systemImage: "network")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(DS.blue)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(DS.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(DS.bg1)

                List {
                    ForEach(sortedSteps) { step in
                        NavigationLink(destination: StepDetailView(step: step, projectID: project.id)) {
                            StepRow(step: step, projectID: project.id, allSteps: sortedSteps)
                        }
                        .listRowBackground(DS.bg0)
                        .listRowSeparator(.hidden)
                    }
                    .onMove { from, to in
                        projectVM.reorderSteps(in: project.id, from: from, to: to)
                    }
                    .onDelete { offsets in
                        for i in offsets {
                            projectVM.deleteStep(sortedSteps[i], from: project.id)
                        }
                    }
                    Color.clear.frame(height: 80).listRowBackground(Color.clear).listRowSeparator(.hidden)
                }
                .environment(\.editMode, .constant(isReordering ? .active : .inactive))
                .listStyle(.plain)
                .background(DS.bg0)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(currentProject.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddStep) {
            AddStepView(projectID: project.id)
        }
    }
}

// MARK: - Step Row
struct StepRow: View {
    let step: RepairStep
    let projectID: UUID
    let allSteps: [RepairStep]

    var blockedByNames: [String] {
        step.dependsOnIDs.compactMap { id in allSteps.first(where: { $0.id == id })?.name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                // Status icon
                Image(systemName: step.status.icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: step.status.color))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(step.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(DS.textPrimary)
                    if let dl = step.deadline {
                        HStack(spacing: 4) {
                            Image(systemName: "clock").font(.system(size: 10))
                            Text(dl, style: .date)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(dl < Date() && step.status != .done ? DS.danger : DS.textMuted)
                    }
                }
                Spacer()
                Text(step.status.rawValue)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: step.status.color))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color(hex: step.status.color).opacity(0.15))
                    .cornerRadius(6)
            }

            if !blockedByNames.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill").font(.system(size: 10)).foregroundColor(DS.warning)
                    Text("Blocked by: \(blockedByNames.joined(separator: ", "))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(DS.warning)
                }
                .padding(.leading, 38)
            }
        }
        .padding(14)
        .background(DS.card)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(step.status == .blocked ? DS.danger.opacity(0.4) : DS.divider, lineWidth: 1)
        )
        .padding(.vertical, 4)
    }
}

// MARK: - Step Detail View
struct StepDetailView: View {
    let step: RepairStep
    let projectID: UUID
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var showAddTask = false
    @State private var showAddMaterial = false
    @State private var showDependencies = false

    var currentStep: RepairStep {
        projectVM.projects.first(where: { $0.id == projectID })?.steps.first(where: { $0.id == step.id }) ?? step
    }

    var projectSteps: [RepairStep] {
        projectVM.projects.first(where: { $0.id == projectID })?.steps.sorted(by: { $0.sortOrder < $1.sortOrder }) ?? []
    }

    var blockedBySteps: [RepairStep] {
        currentStep.dependsOnIDs.compactMap { id in projectSteps.first(where: { $0.id == id }) }
    }

    var body: some View {
        ZStack {
            DS.bg0.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Status + action header
                    statusHeader

                    // Description
                    if !currentStep.stepDescription.isEmpty {
                        sectionCard(title: "Description") {
                            Text(currentStep.stepDescription)
                                .font(.system(size: 14))
                                .foregroundColor(DS.textSecondary)
                        }
                    }

                    // Dependencies
                    if !blockedBySteps.isEmpty {
                        sectionCard(title: "Must complete first") {
                            VStack(spacing: 8) {
                                ForEach(blockedBySteps) { dep in
                                    HStack {
                                        Image(systemName: dep.status.icon)
                                            .foregroundColor(Color(hex: dep.status.color))
                                        Text(dep.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(DS.textPrimary)
                                        Spacer()
                                        Text(dep.status.rawValue)
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(hex: dep.status.color))
                                    }
                                }
                            }
                        }
                    }

                    // Materials
                    sectionCard(title: "Materials (\(currentStep.materials.count))") {
                        VStack(spacing: 8) {
                            if currentStep.materials.isEmpty {
                                Text("No materials added").font(.system(size: 13)).foregroundColor(DS.textMuted)
                            } else {
                                ForEach(currentStep.materials) { mat in
                                    HStack {
                                        Button {
                                            projectVM.toggleMaterialPurchased(mat, stepID: step.id, in: projectID)
                                        } label: {
                                            Image(systemName: mat.isPurchased ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(mat.isPurchased ? DS.success : DS.textMuted)
                                        }
                                        Text(mat.name)
                                            .font(.system(size: 14))
                                            .foregroundColor(mat.isPurchased ? DS.textMuted : DS.textPrimary)
                                            .strikethrough(mat.isPurchased)
                                        Spacer()
                                        Text("\(mat.quantity) \(mat.unit)")
                                            .font(.system(size: 12))
                                            .foregroundColor(DS.textMuted)
                                    }
                                }
                            }
                            Button {
                                showAddMaterial = true
                            } label: {
                                Label("Add Material", systemImage: "plus")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(DS.amber)
                            }
                            .padding(.top, 4)
                        }
                    }

                    // Tasks
                    sectionCard(title: "Tasks (\(currentStep.tasks.count))") {
                        VStack(spacing: 8) {
                            if currentStep.tasks.isEmpty {
                                Text("No tasks added").font(.system(size: 13)).foregroundColor(DS.textMuted)
                            } else {
                                ForEach(currentStep.tasks) { task in
                                    HStack {
                                        Button {
                                            var updated = task
                                            updated.status = task.status == .done ? .pending : .done
                                            projectVM.updateTask(updated, in: projectID)
                                        } label: {
                                            Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(task.status == .done ? DS.success : DS.textMuted)
                                        }
                                        Text(task.name)
                                            .font(.system(size: 14))
                                            .foregroundColor(task.status == .done ? DS.textMuted : DS.textPrimary)
                                            .strikethrough(task.status == .done)
                                        Spacer()
                                    }
                                }
                            }
                            Button { showAddTask = true } label: {
                                Label("Add Task", systemImage: "plus")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(DS.amber)
                            }
                            .padding(.top, 4)
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .navigationTitle(currentStep.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddTask) { AddTaskView(stepID: step.id, projectID: projectID) }
        .sheet(isPresented: $showAddMaterial) { AddMaterialView(stepID: step.id, projectID: projectID) }
        .sheet(isPresented: $showDependencies) { DependenciesView(projectID: projectID) }
    }

    var statusHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: currentStep.status.icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: currentStep.status.color))
                Text(currentStep.status.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: currentStep.status.color))
                Spacer()
                if let dl = currentStep.deadline {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Deadline")
                            .font(.system(size: 11)).foregroundColor(DS.textMuted)
                        Text(dl, style: .date)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(dl < Date() && currentStep.status != .done ? DS.danger : DS.textSecondary)
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    projectVM.markStepStarted(step, in: projectID)
                } label: {
                    Label("Mark Started", systemImage: "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(DS.bg0)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(currentStep.status == .inProgress ? DS.blue : DS.card)
                        .cornerRadius(8)
                }

                Button {
                    projectVM.markStepDone(step, in: projectID)
                } label: {
                    Label("Mark Done", systemImage: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(currentStep.status == .done ? DS.bg0 : DS.textSecondary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(currentStep.status == .done ? DS.success : DS.card)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.divider, lineWidth: 1))
                }

                Spacer()

                Button {
                    showDependencies = true
                } label: {
                    Label("Deps", systemImage: "arrow.right.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(DS.blue)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(DS.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(DS.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(DS.divider, lineWidth: 1))
    }

    func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(DS.textMuted)
                .textCase(.uppercase)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.card)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.divider, lineWidth: 1))
    }
}

// MARK: - Add Step View
struct AddStepView: View {
    let projectID: UUID
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var deadline = Date()
    @State private var hasDeadline = false
    @State private var estimatedDays = 1
    @State private var showValidation = false
    @State private var saved = false

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        formField(label: "Step Name") {
                            TextField("e.g. Plastering", text: $name)
                                .textFieldStyle(RSTextFieldStyle())
                        }

                        formField(label: "Description") {
                            TextEditor(text: $description)
                                .frame(height: 80)
                                .foregroundColor(DS.textPrimary)
                                .padding(8)
                                .background(DS.cardHover)
                                .cornerRadius(10)
                        }

                        formField(label: "Estimated Duration") {
                            Stepper("\(estimatedDays) day\(estimatedDays > 1 ? "s" : "")", value: $estimatedDays, in: 1...90)
                                .foregroundColor(DS.textPrimary)
                                .padding(12)
                                .background(DS.cardHover)
                                .cornerRadius(10)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Set Deadline", isOn: $hasDeadline)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DS.textSecondary)
                                .tint(DS.amber)
                            if hasDeadline {
                                DatePicker("", selection: $deadline, displayedComponents: .date)
                                    .colorScheme(.dark)
                                    .labelsHidden()
                                    .padding(12)
                                    .background(DS.cardHover)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(14)
                        .background(DS.card)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.divider, lineWidth: 1))

                        if showValidation && name.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text("Step name is required").font(.system(size: 13)).foregroundColor(DS.danger)
                        }

                        Button(saved ? "Saved ✓" : "Save Step") {
                            let trimmed = name.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else { showValidation = true; return }
                            var s = RepairStep(name: trimmed, stepDescription: description, estimatedDays: estimatedDays)
                            if hasDeadline { s.deadline = deadline }
                            projectVM.addStep(s, to: projectID)
                            saved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { dismiss.wrappedValue.dismiss() }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(saved)

                        Spacer().frame(height: 60)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("New Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(DS.textMuted)
                }
            }
        }
        .accentColor(DS.amber)
    }

    func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(DS.textMuted).textCase(.uppercase)
            content()
        }
    }
}

// MARK: - Add Task View
struct AddTaskView: View {
    let stepID: UUID
    let projectID: UUID
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss
    @State private var name = ""
    @State private var hasDeadline = false
    @State private var deadline = Date()
    @State private var saved = false

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                VStack(spacing: 16) {
                    TextField("Task name", text: $name).textFieldStyle(RSTextFieldStyle())

                    Toggle("Set Deadline", isOn: $hasDeadline)
                        .foregroundColor(DS.textSecondary).tint(DS.amber)
                        .padding(14).background(DS.card).cornerRadius(12)

                    if hasDeadline {
                        DatePicker("", selection: $deadline, displayedComponents: .date)
                            .colorScheme(.dark).labelsHidden()
                    }

                    Button(saved ? "Saved ✓" : "Add Task") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let t = Task(name: name, deadline: hasDeadline ? deadline : nil, stepID: stepID)
                        projectVM.addTask(t, to: projectID)
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss.wrappedValue.dismiss() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(saved)
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(DS.textMuted)
                }
            }
        }
        .accentColor(DS.amber)
    }
}

// MARK: - Add Material View
struct AddMaterialView: View {
    let stepID: UUID
    let projectID: UUID
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss
    @State private var name = ""
    @State private var quantity = ""
    @State private var unit = "pcs"
    @State private var saved = false

    let units = ["pcs", "m²", "m", "kg", "l", "bags", "rolls", "sheets"]

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                VStack(spacing: 16) {
                    TextField("Material name", text: $name).textFieldStyle(RSTextFieldStyle())
                    HStack(spacing: 10) {
                        TextField("Qty", text: $quantity)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RSTextFieldStyle())
                        Picker("Unit", selection: $unit) {
                            ForEach(units, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .foregroundColor(DS.amber)
                        .padding(12)
                        .background(DS.cardHover)
                        .cornerRadius(10)
                    }
                    Button(saved ? "Saved ✓" : "Add Material") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let m = Material(name: name, quantity: quantity.isEmpty ? "1" : quantity, unit: unit)
                        projectVM.addMaterial(m, to: stepID, in: projectID)
                        saved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { dismiss.wrappedValue.dismiss() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(saved)
                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Add Material")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }.foregroundColor(DS.textMuted)
                }
            }
        }
        .accentColor(DS.amber)
    }
}
