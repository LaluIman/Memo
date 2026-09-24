import Foundation

enum TaskDueGroup: CaseIterable, Identifiable {
    case overdue, today, upcoming, noDueDate

    var id: Self { self }

    var label: String {
        switch self {
        case .overdue: return "Overdue"
        case .today: return "Today"
        case .upcoming: return "Upcoming"
        case .noDueDate: return "No Due Date"
        }
    }
}

extension TodoItem {
    var dueGroup: TaskDueGroup {
        guard let dueDate else { return .noDueDate }
        if isOverdue { return .overdue }
        let startOfToday = Calendar.current.startOfDay(for: Date())
        if dueDate <= startOfToday || Calendar.current.isDateInToday(dueDate) {
            return .today
        }
        return .upcoming
    }
}
