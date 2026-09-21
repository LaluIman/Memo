import Foundation

enum FirebaseConfig {
    /// Firebase project ID, from Firebase Console → Project Settings → General.
    static let projectID = "todo-menubar-mac"

    /// Firestore collection feedback submissions are written to.
    static let feedbackCollection = "feedback"

    static var isConfigured: Bool {
        !projectID.isEmpty && projectID != "YOUR_FIREBASE_PROJECT_ID"
    }
}
