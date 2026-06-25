import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @State private var showAdd = false

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                if projectVM.projects.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(projectVM.projects) { project in
                                NavigationLink(destination: StepListView(project: project)) {
                                    ProjectCard(project: project)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        projectVM.deleteProject(project)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(DS.amber)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddProjectView() }
        }
        .accentColor(DS.amber)
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus").font(.system(size: 56)).foregroundColor(DS.amber.opacity(0.5))
            Text("No Projects").font(.system(size: 20, weight: .bold)).foregroundColor(DS.textPrimary)
            Button("Create Project") { showAdd = true }.buttonStyle(PrimaryButtonStyle()).padding(.horizontal, 60)
        }
    }
}

struct ProjectCard: View {
    let project: Project
    @State private var appear = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(DS.textPrimary)
                    Text(project.repairType.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DS.amber)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(DS.amber.opacity(0.15))
                        .cornerRadius(6)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DS.textMuted)
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "list.number").font(.system(size: 12)).foregroundColor(DS.textMuted)
                    Text("\(project.steps.count) steps")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(DS.textMuted)
                }
                HStack(spacing: 4) {
                    Image(systemName: "door.left.hand.open").font(.system(size: 12)).foregroundColor(DS.textMuted)
                    Text("\(project.roomsCount) rooms")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(DS.textMuted)
                }
                if project.errorCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill").font(.system(size: 12)).foregroundColor(DS.danger)
                        Text("\(project.errorCount) errors")
                            .font(.system(size: 12, weight: .medium)).foregroundColor(DS.danger)
                    }
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(DS.textMuted)
                    Spacer()
                    Text("\(Int(project.progress * 100))%")
                        .font(.system(size: 12, weight: .bold)).foregroundColor(DS.amber)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(DS.divider).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4).fill(DS.amber)
                            .frame(width: geo.size.width * (appear ? project.progress : 0), height: 6)
                            .animation(.easeInOut(duration: 0.8).delay(0.2), value: appear)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(16)
        .background(DS.card)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(DS.divider, lineWidth: 1))
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { appear = true } }
    }
}

// MARK: - Add Project
struct AddProjectView: View {
    @EnvironmentObject var projectVM: ProjectViewModel
    @Environment(\.presentationMode) var dismiss
    @State private var name = ""
    @State private var repairType: RepairType = .fullRenovation
    @State private var roomsCount = 2
    @State private var startDate = Date()
    @State private var notes = ""
    @State private var showValidation = false
    @State private var saved = false

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationView {
            ZStack {
                DS.bg0.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        formField(label: "Project Name") {
                            TextField("e.g. Apartment Renovation", text: $name)
                                .textFieldStyle(RSTextFieldStyle())
                        }

                        formField(label: "Repair Type") {
                            Picker("Type", selection: $repairType) {
                                ForEach(RepairType.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(DS.amber)
                            .padding(12)
                            .background(DS.cardHover)
                            .cornerRadius(10)
                        }

                        formField(label: "Number of Rooms") {
                            Stepper("\(roomsCount) room\(roomsCount > 1 ? "s" : "")", value: $roomsCount, in: 1...20)
                                .foregroundColor(DS.textPrimary)
                                .padding(12)
                                .background(DS.cardHover)
                                .cornerRadius(10)
                        }

                        formField(label: "Start Date") {
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .colorScheme(.dark)
                                .labelsHidden()
                                .padding(12)
                                .background(DS.cardHover)
                                .cornerRadius(10)
                        }

                        formField(label: "Notes (optional)") {
                            TextEditor(text: $notes)
                                .frame(height: 90)
                                .foregroundColor(DS.textPrimary)
                                .padding(8)
                                .background(DS.cardHover)
                                .cornerRadius(10)
                        }

                        if showValidation && !isValid {
                            Text("Project name is required")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(DS.danger)
                        }

                        Button(saved ? "Saved ✓" : "Save Project") {
                            if isValid {
                                let project = Project(name: name, repairType: repairType, roomsCount: roomsCount, startDate: startDate, notes: notes)
                                projectVM.addProject(project)
                                saved = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { dismiss.wrappedValue.dismiss() }
                            } else {
                                showValidation = true
                            }
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
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss.wrappedValue.dismiss() }
                        .foregroundColor(DS.textMuted)
                }
            }
        }
        .accentColor(DS.amber)
    }

    func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DS.textMuted)
                .textCase(.uppercase)
            content()
        }
    }
}

struct RSTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .foregroundColor(DS.textPrimary)
            .padding(12)
            .background(DS.cardHover)
            .cornerRadius(10)
    }
}
