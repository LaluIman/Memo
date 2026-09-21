import AppKit
import SwiftUI

enum TaskPriority: String, Codable, CaseIterable, Identifiable, Hashable {
    case low, medium, high, critical

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .low: return Color(nsColor: .systemGreen)
        case .medium: return Color(nsColor: .systemYellow)
        case .high: return Color(nsColor: .systemOrange)
        case .critical: return Color(nsColor: .systemRed)
        }
    }
}

struct TodoItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var priority: TaskPriority

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, priority: TaskPriority = .medium) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.priority = priority
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, isCompleted, priority
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        priority = try container.decodeIfPresent(TaskPriority.self, forKey: .priority) ?? .medium
    }
}
