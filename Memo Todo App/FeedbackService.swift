import Foundation

enum FeedbackSubmissionError: LocalizedError {
    case notConfigured
    case requestFailed(Int)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Feedback isn't configured yet. Please try again later."
        case .requestFailed(let statusCode):
            return "Couldn't send feedback (server returned \(statusCode)). Please try again."
        case .transport:
            return "Couldn't send feedback. Check your internet connection and try again."
        }
    }
}

/// Submits feedback to Firestore via its REST API — no Firebase SDK dependency required.
enum FeedbackService {
    static func submit(type: FeedbackType, email: String, description: String) async throws {
        if let rateLimitError = FeedbackRateLimiter.canSubmit() {
            throw rateLimitError
        }

        guard FirebaseConfig.isConfigured else {
            throw FeedbackSubmissionError.notConfigured
        }

        let urlString = "https://firestore.googleapis.com/v1/projects/\(FirebaseConfig.projectID)/databases/(default)/documents/\(FirebaseConfig.feedbackCollection)"
        guard let url = URL(string: urlString) else {
            throw FeedbackSubmissionError.notConfigured
        }

        let isoTimestamp = ISO8601DateFormatter().string(from: Date())
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"

        let body: [String: Any] = [
            "fields": [
                "type": ["stringValue": type.rawValue],
                "email": ["stringValue": email],
                "description": ["stringValue": description],
                "appVersion": ["stringValue": appVersion],
                "createdAt": ["timestampValue": isoTimestamp]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                throw FeedbackSubmissionError.requestFailed(statusCode)
            }
            FeedbackRateLimiter.recordSubmission()
        } catch let error as FeedbackSubmissionError {
            throw error
        } catch {
            throw FeedbackSubmissionError.transport(error)
        }
    }
}
