import Foundation

enum FeedbackRateLimitError: LocalizedError {
    case cooldown(remainingSeconds: Int)
    case dailyLimitReached

    var errorDescription: String? {
        switch self {
        case .cooldown(let remainingSeconds):
            return "Please wait \(remainingSeconds)s before sending more feedback."
        case .dailyLimitReached:
            return "You've reached today's feedback limit. Please try again tomorrow."
        }
    }
}

/// Client-side spam guard: enforces a cooldown between individual submissions
/// and a rolling daily cap, tracked locally in UserDefaults.
enum FeedbackRateLimiter {
    static let cooldownInterval: TimeInterval = 60
    static let maxSubmissionsPerDay = 5
    private static let dailyWindow: TimeInterval = 86_400

    private static let lastSubmissionKey = "feedback.lastSubmissionDate"
    private static let submissionTimestampsKey = "feedback.submissionTimestamps"

    static func remainingCooldownSeconds() -> Int {
        guard let last = UserDefaults.standard.object(forKey: lastSubmissionKey) as? Date else { return 0 }
        let remaining = cooldownInterval - Date().timeIntervalSince(last)
        return remaining > 0 ? Int(remaining.rounded(.up)) : 0
    }

    static func canSubmit() -> FeedbackRateLimitError? {
        let remainingCooldown = remainingCooldownSeconds()
        if remainingCooldown > 0 {
            return .cooldown(remainingSeconds: remainingCooldown)
        }
        if recentTimestamps().count >= maxSubmissionsPerDay {
            return .dailyLimitReached
        }
        return nil
    }

    static func recordSubmission() {
        let now = Date()
        UserDefaults.standard.set(now, forKey: lastSubmissionKey)
        var timestamps = recentTimestamps()
        timestamps.append(now)
        UserDefaults.standard.set(timestamps.map(\.timeIntervalSince1970), forKey: submissionTimestampsKey)
    }

    private static func recentTimestamps() -> [Date] {
        let raw = UserDefaults.standard.array(forKey: submissionTimestampsKey) as? [Double] ?? []
        let now = Date()
        return raw.map { Date(timeIntervalSince1970: $0) }.filter { now.timeIntervalSince($0) < dailyWindow }
    }
}
