import Foundation

enum FeedbackType: String, CaseIterable, Identifiable, Equatable {
    case bug, feature, question, other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .bug: return "Bug"
        case .feature: return "Feature Request"
        case .question: return "Question"
        case .other: return "Other"
        }
    }
}
