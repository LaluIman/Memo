import Foundation

enum CompletedTaskBehavior: String, Codable, CaseIterable, Identifiable, Equatable {
    case keepInPlace, moveToBottom, hideImmediately

    var id: String { rawValue }

    var label: String {
        switch self {
        case .keepInPlace: return "Keep in Place"
        case .moveToBottom: return "Move to Bottom"
        case .hideImmediately: return "Hide Immediately"
        }
    }
}
