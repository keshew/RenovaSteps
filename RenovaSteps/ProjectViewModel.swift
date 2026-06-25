import Foundation
import Combine
import UserNotifications

class ProjectViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var activityLog: [ActivityRecord] = []
    @Published var globalErrors: [RepairError] = []
    @Published var suggestions: [Suggestion] = []

    private let projectsKey = "rs_projects"
    private let activityKey = "rs_activity"
    private let errorsKey = "rs_errors"
    private let suggestionsKey = "rs_suggestions"

    init() {
        load()
        if projects.isEmpty { seedDemoData() }
        refreshSuggestions()
    }

    // MARK: - Persistence
    func save() {
        if let d = try? JSONEncoder().encode(projects) { UserDefaults.standard.set(d, forKey: projectsKey) }
        if let d = try? JSONEncoder().encode(activityLog) { UserDefaults.standard.set(d, forKey: activityKey) }
        if let d = try? JSONEncoder().encode(globalErrors) { UserDefaults.standard.set(d, forKey: errorsKey) }
        if let d = try? JSONEncoder().encode(suggestions) { UserDefaults.standard.set(d, forKey: suggestionsKey) }
    }

    func load() {
        if let d = UserDefaults.standard.data(forKey: projectsKey), let v = try? JSONDecoder().decode([Project].self, from: d) { projects = v }
        if let d = UserDefaults.standard.data(forKey: activityKey), let v = try? JSONDecoder().decode([ActivityRecord].self, from: d) { activityLog = v }
        if let d = UserDefaults.standard.data(forKey: errorsKey), let v = try? JSONDecoder().decode([RepairError].self, from: d) { globalErrors = v }
        if let d = UserDefaults.standard.data(forKey: suggestionsKey), let v = try? JSONDecoder().decode([Suggestion].self, from: d) { suggestions = v }
    }

    // MARK: - Project CRUD
    func addProject(_ project: Project) {
        var p = project
        if p.steps.isEmpty { p.steps = RepairStep.defaultSteps() }
        projects.append(p)
        log("Project '\(p.name)' created", icon: "folder.badge.plus", projectID: p.id)
        validateAll()
        save()
    }

    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        log("Project '\(project.name)' deleted", icon: "trash")
        save()
    }

    func updateProject(_ project: Project) {
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx] = project
            validateAll()
            save()
        }
    }

    // MARK: - Step CRUD
    func addStep(_ step: RepairStep, to projectID: UUID) {
        guard let idx = projects.firstIndex(where: { $0.id == projectID }) else { return }
        var s = step
        s.sortOrder = projects[idx].steps.count
        projects[idx].steps.append(s)
        log("Step '\(s.name)' added", icon: "plus.circle", projectID: projectID)
        validateProject(at: idx)
        save()
    }

    func updateStep(_ step: RepairStep, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let sIdx = projects[pIdx].steps.firstIndex(where: { $0.id == step.id }) else { return }
        projects[pIdx].steps[sIdx] = step
        validateProject(at: pIdx)
        save()
    }

    func deleteStep(_ step: RepairStep, from projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[pIdx].steps.removeAll { $0.id == step.id }
        // Remove dependencies referencing this step
        for i in projects[pIdx].steps.indices {
            projects[pIdx].steps[i].dependsOnIDs.removeAll { $0 == step.id }
        }
        log("Step '\(step.name)' removed", icon: "minus.circle", projectID: projectID)
        validateProject(at: pIdx)
        save()
    }

    func markStepStarted(_ step: RepairStep, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let sIdx = projects[pIdx].steps.firstIndex(where: { $0.id == step.id }) else { return }
        projects[pIdx].steps[sIdx].status = .inProgress
        log("Step '\(step.name)' started", icon: "play.circle", projectID: projectID)
        validateProject(at: pIdx)
        save()
    }

    func markStepDone(_ step: RepairStep, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let sIdx = projects[pIdx].steps.firstIndex(where: { $0.id == step.id }) else { return }
        projects[pIdx].steps[sIdx].status = .done
        log("Step '\(step.name)' completed", icon: "checkmark.circle", projectID: projectID)
        validateProject(at: pIdx)
        save()
    }

    func reorderSteps(in projectID: UUID, from source: IndexSet, to destination: Int) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }) else { return }
        projects[pIdx].steps.move(fromOffsets: source, toOffset: destination)
        for i in projects[pIdx].steps.indices { projects[pIdx].steps[i].sortOrder = i }
        log("Steps reordered", icon: "arrow.up.arrow.down", projectID: projectID)
        validateProject(at: pIdx)
        save()
    }

    // MARK: - Dependencies
    func addDependency(stepA: UUID, dependsOn stepB: UUID, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let sIdx = projects[pIdx].steps.firstIndex(where: { $0.id == stepA }) else { return }
        if !projects[pIdx].steps[sIdx].dependsOnIDs.contains(stepB) {
            projects[pIdx].steps[sIdx].dependsOnIDs.append(stepB)
            log("Dependency added", icon: "arrow.right.circle", projectID: projectID)
            validateProject(at: pIdx)
            save()
        }
    }

    func removeDependency(stepA: UUID, dependsOn stepB: UUID, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let sIdx = projects[pIdx].steps.firstIndex(where: { $0.id == stepA }) else { return }
        projects[pIdx].steps[sIdx].dependsOnIDs.removeAll { $0 == stepB }
        log("Dependency removed", icon: "arrow.right.circle.fill", projectID: projectID)
        validateProject(at: pIdx)
        save()
    }

    // MARK: - Tasks
    func addTask(_ task: Task, to projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let sIdx = projects[pIdx].steps.firstIndex(where: { $0.id == task.stepID }) else { return }
        projects[pIdx].steps[sIdx].tasks.append(task)
        log("Task '\(task.name)' added", icon: "checkmark.square", projectID: projectID)
        save()
    }

    func updateTask(_ task: Task, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let sIdx = projects[pIdx].steps.firstIndex(where: { $0.id == task.stepID }),
              let tIdx = projects[pIdx].steps[sIdx].tasks.firstIndex(where: { $0.id == task.id }) else { return }
        projects[pIdx].steps[sIdx].tasks[tIdx] = task
        save()
    }

    func deleteTask(_ task: Task, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let sIdx = projects[pIdx].steps.firstIndex(where: { $0.id == task.stepID }) else { return }
        projects[pIdx].steps[sIdx].tasks.removeAll { $0.id == task.id }
        save()
    }

    // MARK: - Materials
    func addMaterial(_ material: Material, to stepID: UUID, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let sIdx = projects[pIdx].steps.firstIndex(where: { $0.id == stepID }) else { return }
        projects[pIdx].steps[sIdx].materials.append(material)
        save()
    }

    func toggleMaterialPurchased(_ material: Material, stepID: UUID, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let sIdx = projects[pIdx].steps.firstIndex(where: { $0.id == stepID }),
              let mIdx = projects[pIdx].steps[sIdx].materials.firstIndex(where: { $0.id == material.id }) else { return }
        projects[pIdx].steps[sIdx].materials[mIdx].isPurchased.toggle()
        save()
    }

    func deleteMaterial(_ material: Material, stepID: UUID, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let sIdx = projects[pIdx].steps.firstIndex(where: { $0.id == stepID }) else { return }
        projects[pIdx].steps[sIdx].materials.removeAll { $0.id == material.id }
        save()
    }

    // MARK: - Auto Plan
    func autoOrderSteps(in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }) else { return }
        let defaultOrder = ["Demolition","Wiring","Plumbing","HVAC","Insulation","Drywall","Plaster","Priming","Painting","Flooring","Trim & Moldings","Fixtures"]
        projects[pIdx].steps.sort { a, b in
            let ai = defaultOrder.firstIndex(of: a.name) ?? 999
            let bi = defaultOrder.firstIndex(of: b.name) ?? 999
            return ai < bi
        }
        for i in projects[pIdx].steps.indices { projects[pIdx].steps[i].sortOrder = i }
        log("Steps auto-planned", icon: "wand.and.stars", projectID: projectID)
        validateProject(at: pIdx)
        save()
    }

    // MARK: - Validation
    func validateAll() {
        globalErrors.removeAll()
        for project in projects {
            let errs = errorsFor(project: project)
            globalErrors.append(contentsOf: errs)
        }
        refreshSuggestions()
    }

    func validateProject(at idx: Int) {
        let project = projects[idx]
        globalErrors.removeAll { $0.stepID.flatMap { sid in project.steps.first(where: { $0.id == sid }) } != nil || $0.stepID == nil }
        let errs = errorsFor(project: project)
        globalErrors.append(contentsOf: errs)
        // Update blocked status
        for sIdx in projects[idx].steps.indices {
            let step = projects[idx].steps[sIdx]
            if step.status == .notStarted || step.status == .blocked {
                let deps = step.dependsOnIDs.compactMap { did in project.steps.first(where: { $0.id == did }) }
                let isBlocked = deps.contains { $0.status != .done }
                if isBlocked && !deps.isEmpty {
                    projects[idx].steps[sIdx].status = .blocked
                } else if projects[idx].steps[sIdx].status == .blocked {
                    projects[idx].steps[sIdx].status = .notStarted
                }
            }
        }
        refreshSuggestions()
    }

    func errorsFor(project: Project) -> [RepairError] {
        var errors: [RepairError] = []
        for step in project.steps {
            // Check if step is done but dependency is not done
            if step.status == .done {
                for depID in step.dependsOnIDs {
                    if let dep = project.steps.first(where: { $0.id == depID }), dep.status != .done {
                        errors.append(RepairError(
                            message: "'\(step.name)' marked done but '\(dep.name)' is not complete",
                            severity: .error, stepID: step.id))
                    }
                }
            }
            // Check order conflicts
            let stepOrder = step.sortOrder
            for depID in step.dependsOnIDs {
                if let dep = project.steps.first(where: { $0.id == depID }), dep.sortOrder > stepOrder {
                    errors.append(RepairError(
                        message: "'\(dep.name)' is scheduled AFTER '\(step.name)' but is a dependency",
                        severity: .error, stepID: step.id))
                }
            }
            // Overdue
            if let dl = step.deadline, dl < Date(), step.status != .done {
                errors.append(RepairError(
                    message: "'\(step.name)' is overdue",
                    severity: .warning, stepID: step.id))
            }
        }
        return errors
    }

    func fixOrderError(_ error: RepairError, in projectID: UUID) {
        guard let pIdx = projects.firstIndex(where: { $0.id == projectID }),
              let sid = error.stepID,
              let sIdx = projects[pIdx].steps.firstIndex(where: { $0.id == sid }) else {
            globalErrors.removeAll { $0.id == error.id }
            save()
            return
        }
        let step = projects[pIdx].steps[sIdx]
        for depID in step.dependsOnIDs {
            if let depIdx = projects[pIdx].steps.firstIndex(where: { $0.id == depID }) {
                let dep = projects[pIdx].steps[depIdx]
                if dep.sortOrder > step.sortOrder {
                    projects[pIdx].steps.remove(at: depIdx)
                    let newIdx = max(0, sIdx)
                    projects[pIdx].steps.insert(dep, at: newIdx)
                    for i in projects[pIdx].steps.indices { projects[pIdx].steps[i].sortOrder = i }
                }
            }
        }
        log("Order error fixed", icon: "wrench.and.screwdriver", projectID: projectID)
        validateProject(at: pIdx)
        save()
    }

    func ignoreError(_ error: RepairError) {
        if let idx = globalErrors.firstIndex(where: { $0.id == error.id }) {
            globalErrors[idx].isIgnored = true
        }
        save()
    }

    // MARK: - Suggestions
    func refreshSuggestions() {
        var s: [Suggestion] = []
        for project in projects {
            let hasPlaster = project.steps.first(where: { $0.name.lowercased().contains("plaster") })
            let hasPainting = project.steps.first(where: { $0.name.lowercased().contains("paint") })
            let hasPriming = project.steps.first(where: { $0.name.lowercased().contains("prim") })

            if let painting = hasPainting, let plaster = hasPlaster {
                if painting.sortOrder < plaster.sortOrder {
                    s.append(Suggestion(title: "Move Painting after Plastering",
                        detail: "Painting before plastering damages finished surfaces. Reorder to avoid rework."))
                }
            }
            if hasPriming == nil && hasPainting != nil {
                s.append(Suggestion(title: "Add Priming step",
                    detail: "Priming before painting ensures better adhesion and finish quality."))
            }
            let hasElectrical = project.steps.first(where: { $0.name.lowercased().contains("wiring") || $0.name.lowercased().contains("electric") })
            let hasFlooring = project.steps.first(where: { $0.name.lowercased().contains("floor") })
            if let e = hasElectrical, let f = hasFlooring, f.sortOrder < e.sortOrder {
                s.append(Suggestion(title: "Complete wiring before flooring",
                    detail: "Running cables after flooring requires cutting into finished surfaces."))
            }
        }
        if s.isEmpty {
            s.append(Suggestion(title: "Add a priming stage", detail: "A primer coat between plaster and paint extends finish life significantly."))
            s.append(Suggestion(title: "Split electrical and finishing", detail: "Keep rough electrical work separate from finishing stages."))
        }
        // Preserve applied state
        let appliedIDs = suggestions.filter { $0.isApplied }.map { $0.title }
        suggestions = s.map { sugg in
            var s2 = sugg
            if appliedIDs.contains(sugg.title) { s2.isApplied = true }
            return s2
        }
    }

    func applySuggestion(_ suggestion: Suggestion) {
        if let idx = suggestions.firstIndex(where: { $0.id == suggestion.id }) {
            suggestions[idx].isApplied = true
            log("Suggestion applied: '\(suggestion.title)'", icon: "lightbulb")
        }
        save()
    }

    // MARK: - Notifications
    func scheduleNotification(title: String, body: String, date: Date, id: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let comps = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    // MARK: - Logging
    func log(_ message: String, icon: String = "clock", projectID: UUID? = nil) {
        let record = ActivityRecord(message: message, projectID: projectID, icon: icon)
        activityLog.insert(record, at: 0)
        if activityLog.count > 100 { activityLog = Array(activityLog.prefix(100)) }
    }

    // MARK: - Computed
    var activeProject: Project? { projects.first(where: { !$0.steps.filter({ $0.status == .inProgress }).isEmpty }) ?? projects.first }
    var totalErrorCount: Int { globalErrors.filter { !$0.isIgnored }.count }
    var allTasks: [Task] { projects.flatMap { $0.steps.flatMap { $0.tasks } } }
    var allMaterials: [(Material, UUID, UUID)] {
        var result: [(Material, UUID, UUID)] = []
        for p in projects {
            for s in p.steps {
                for m in s.materials { result.append((m, s.id, p.id)) }
            }
        }
        return result
    }

    func steps(for projectID: UUID) -> [RepairStep] {
        projects.first(where: { $0.id == projectID })?.steps.sorted(by: { $0.sortOrder < $1.sortOrder }) ?? []
    }

    // MARK: - Demo
    private func seedDemoData() {
        var p1 = Project(name: "Apartment Renovation", repairType: .fullRenovation, roomsCount: 3, startDate: Date(), notes: "Full gut renovation of 3-room apartment")
        var steps = RepairStep.defaultSteps()
        steps[0].status = .done
        steps[1].status = .done
        steps[2].status = .done
        steps[3].status = .inProgress
        steps[2].dependsOnIDs = [steps[1].id]
        steps[3].dependsOnIDs = [steps[2].id]
        steps[4].dependsOnIDs = [steps[3].id]
        steps[4].deadline = Calendar.current.date(byAdding: .day, value: -2, to: Date())
        steps[0].materials = [
            Material(name: "Dust Sheets", quantity: "10", unit: "pcs"),
            Material(name: "Crowbar", quantity: "1", unit: "pcs", isPurchased: true)
        ]
        steps[1].tasks = [
            Task(name: "Install circuit breaker", status: .done, stepID: steps[1].id),
            Task(name: "Run cables to rooms", status: .done, stepID: steps[1].id)
        ]
        p1.steps = steps
        projects.append(p1)

        var p2 = Project(name: "Bathroom Remodel", repairType: .bathroom, roomsCount: 1, startDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(), notes: "Master bathroom full remodel")
        p2.steps = Array(RepairStep.defaultSteps().prefix(6))
        projects.append(p2)

        activityLog = [
            ActivityRecord(message: "Project 'Apartment Renovation' created", icon: "folder.badge.plus"),
            ActivityRecord(message: "Step 'Demolition' completed", icon: "checkmark.circle"),
            ActivityRecord(message: "Step 'Wiring' completed", icon: "checkmark.circle"),
            ActivityRecord(message: "Dependency added between Plumbing and Wiring", icon: "arrow.right.circle")
        ]

        globalErrors = [
            RepairError(message: "'Insulation' is overdue", severity: .warning),
            RepairError(message: "'HVAC' is blocked by 'Plumbing'", severity: .error)
        ]

        suggestions = [
            Suggestion(title: "Add Priming step", detail: "A primer coat between plaster and paint extends finish life significantly."),
            Suggestion(title: "Split electrical and finishing", detail: "Keep rough electrical work separate from finishing stages."),
            Suggestion(title: "Move Painting after Plastering", detail: "Painting before plastering damages finished surfaces. Reorder to avoid rework.")
        ]

        save()
    }
}
