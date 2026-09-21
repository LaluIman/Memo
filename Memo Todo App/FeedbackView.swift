import Combine
import SwiftUI

private let cooldownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var type: FeedbackType = .bug
    @State private var email: String = ""
    @State private var description: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var didSubmit = false
    @State private var cooldownRemaining = FeedbackRateLimiter.remainingCooldownSeconds()

    private var canSubmit: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedEmail.isEmpty && trimmedEmail.isValidEmail
            && !trimmedDescription.isEmpty
            && !isSubmitting
            && cooldownRemaining == 0
    }

    var body: some View {
        VStack(spacing: 0) {
            if didSubmit {
                confirmationView
            } else {
                formView
            }
        }
        .frame(width: 380)
        .onReceive(cooldownTimer) { _ in
            cooldownRemaining = FeedbackRateLimiter.remainingCooldownSeconds()
        }
    }

    private var formView: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(FeedbackType.allCases) { type in
                            Text(type.label).tag(type)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)

                        if !email.isEmpty && !email.trimmingCharacters(in: .whitespacesAndNewlines).isValidEmail {
                            Text("Enter a valid email address.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                        TextEditor(text: $description)
                            .frame(height: 100)
                            .font(.body)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if cooldownRemaining > 0 {
                        Text("Please wait \(cooldownRemaining)s before sending more feedback.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    submit()
                } label: {
                    if isSubmitting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Send")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSubmit)
            }
            .padding([.horizontal, .bottom], 14)
        }
    }

    private var confirmationView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green)
            Text("Thanks for your feedback!")
                .font(.headline)
            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(32)
    }

    private func submit() {
        errorMessage = nil
        isSubmitting = true
        Task {
            do {
                try await FeedbackService.submit(type: type, email: email, description: description)
                isSubmitting = false
                didSubmit = true
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

private extension String {
    var isValidEmail: Bool {
        let regex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
        return (try? regex.wholeMatch(in: self)) != nil
    }
}

#Preview {
    FeedbackView()
}
