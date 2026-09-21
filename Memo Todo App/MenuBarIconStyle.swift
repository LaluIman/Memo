import Foundation

enum MenuBarIconStyle: String, Codable, CaseIterable, Identifiable, Equatable {
    case custom, checklist, checkmarkCircle, listBullet, star, tray

    var id: String { rawValue }

    var label: String {
        switch self {
        case .custom: return "Default"
        case .checklist: return "Checklist"
        case .checkmarkCircle: return "Checkmark Circle"
        case .listBullet: return "List"
        case .star: return "Star"
        case .tray: return "Tray"
        }
    }

    /// nil means use the bundled "MenuBarIcon" asset instead of an SF Symbol.
    var systemImageName: String? {
        switch self {
        case .custom: return nil
        case .checklist: return "checklist"
        case .checkmarkCircle: return "checkmark.circle"
        case .listBullet: return "list.bullet"
        case .star: return "star.fill"
        case .tray: return "tray.fill"
        }
    }
}
