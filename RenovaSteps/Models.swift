import Foundation

// MARK: - Enums

enum RepairType: String, CaseIterable, Codable {
    case fullRenovation = "Full Renovation"
    case cosmetic = "Cosmetic Repair"
    case partialRenovation = "Partial Renovation"
    case commercial = "Commercial"
    case bathroom = "Bathroom Remodel"
    case kitchen = "Kitchen Remodel"
}

enum StepStatus: String, CaseIterable, Codable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case done = "Done"
    case blocked = "Blocked"
    case skipped = "Skipped"

    var color: String {
        switch self {
        case .notStarted: return "#64748B"
        case .inProgress: return "#3B82F6"
        case .done: return "#22C55E"
        case .blocked: return "#EF4444"
        case .skipped: return "#FACC15"
        }
    }

    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "arrow.clockwise.circle.fill"
        case .done: return "checkmark.circle.fill"
        case .blocked: return "xmark.circle.fill"
        case .skipped: return "minus.circle.fill"
        }
    }
}

enum TaskStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case inProgress = "In Progress"
    case done = "Done"
}

enum ErrorSeverity: String, Codable {
    case error = "Error"
    case warning = "Warning"
}

// MARK: - Models

struct Project: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var repairType: RepairType
    var roomsCount: Int
    var startDate: Date
    var notes: String
    var steps: [RepairStep] = []
    var createdAt: Date = Date()

    var progress: Double {
        guard !steps.isEmpty else { return 0 }
        let done = steps.filter { $0.status == .done }.count
        return Double(done) / Double(steps.count)
    }

    var errorCount: Int {
        steps.filter { $0.status == .blocked }.count
    }

    static func == (lhs: Project, rhs: Project) -> Bool { lhs.id == rhs.id }
}

struct RepairStep: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var stepDescription: String
    var status: StepStatus = .notStarted
    var deadline: Date?
    var dependsOnIDs: [UUID] = []
    var materials: [Material] = []
    var tasks: [Task] = []
    var sortOrder: Int = 0
    var estimatedDays: Int = 1
    var notes: String = ""

    var isBlocked: Bool { status == .blocked }

    static func == (lhs: RepairStep, rhs: RepairStep) -> Bool { lhs.id == rhs.id }
}

struct Material: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var quantity: String
    var unit: String
    var isPurchased: Bool = false
}

struct Task: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var status: TaskStatus = .pending
    var deadline: Date?
    var stepID: UUID
}

struct Dependency: Identifiable, Codable {
    var id: UUID = UUID()
    var stepAID: UUID
    var stepBID: UUID
}

struct RepairError: Identifiable, Codable {
    var id: UUID = UUID()
    var message: String
    var severity: ErrorSeverity
    var stepID: UUID?
    var isIgnored: Bool = false
    var timestamp: Date = Date()
}

struct ActivityRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var message: String
    var timestamp: Date = Date()
    var projectID: UUID?
    var icon: String = "clock"
}

struct Suggestion: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var detail: String
    var isApplied: Bool = false
}

// MARK: - Default Steps

extension RepairStep {
    static func defaultSteps() -> [RepairStep] {
        let names: [(String, String, Int)] = [
            ("Demolition", "Remove old finishes, walls, flooring as needed.", 3),
            ("Wiring", "Electrical rough-in: cables, conduits, junction boxes.", 5),
            ("Plumbing", "Rough-in plumbing: pipes, drains, supply lines.", 4),
            ("HVAC", "Heating, ventilation and air conditioning installation.", 3),
            ("Insulation", "Thermal and acoustic insulation in walls and ceilings.", 2),
            ("Drywall", "Install and tape drywall panels.", 4),
            ("Plaster", "Apply base coat and finish plaster.", 5),
            ("Priming", "Prime all plastered surfaces.", 2),
            ("Painting", "Apply finish paint coats.", 4),
            ("Flooring", "Install flooring material.", 5),
            ("Trim & Moldings", "Install baseboards, door casings, crown molding.", 3),
            ("Fixtures", "Install lighting, switches, outlets, plumbing fixtures.", 3)
        ]
        return names.enumerated().map { i, item in
            RepairStep(name: item.0, stepDescription: item.1, sortOrder: i, estimatedDays: item.2)
        }
    }
}
