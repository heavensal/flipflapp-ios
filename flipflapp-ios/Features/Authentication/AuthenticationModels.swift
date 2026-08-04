import Foundation
import Observation

@MainActor
@Observable
final class SignInModel {
    var isSubmitting = false
    var errorMessage: String?
    var suggestsConfirmation = false

    private let session: SessionStore

    init(session: SessionStore) {
        self.session = session
    }

    func signIn(email: String, password: String) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        suggestsConfirmation = false
        defer { isSubmitting = false }

        do {
            try await session.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
        } catch let error as APIError {
            if case let .unauthorized(message) = error,
               message?.localizedCaseInsensitiveContains("confirm") == true {
                suggestsConfirmation = true
            }
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class RegistrationModel {
    var isSubmitting = false
    var errorMessage: String?
    var successMessage: String?
    var fieldErrors: [String: String] = [:]

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func register(
        firstName: String,
        lastName: String,
        email: String,
        password: String,
        confirmation: String
    ) async {
        guard !isSubmitting else { return }
        guard password == confirmation else {
            errorMessage = String(localized: "Passwords do not match.")
            return
        }

        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        fieldErrors = [:]
        defer { isSubmitting = false }

        do {
            _ = try await api.register(
                RegistrationInput(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password,
                    passwordConfirmation: confirmation,
                    firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                    lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
            successMessage = String(localized: "Account created. Check your email to confirm it before signing in.")
        } catch let error as APIError {
            applyValidation(error)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyValidation(_ error: APIError) {
        if let summary = error.validationSummary {
            errorMessage = summary
        } else {
            errorMessage = error.localizedDescription
        }
        fieldErrors = error.validationDetails.mapValues { $0.joined(separator: "\n") }
    }
}

@MainActor
@Observable
final class PasswordRecoveryModel {
    var isRequesting = false
    var isResetting = false
    var errorMessage: String?
    var successMessage: String?
    var fieldErrors: [String: String] = [:]

    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func request(email: String) async {
        guard !isRequesting else { return }
        isRequesting = true
        errorMessage = nil
        successMessage = nil
        fieldErrors = [:]
        defer { isRequesting = false }

        do {
            try await api.requestPasswordReset(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            successMessage = String(localized: "If this address exists, password reset instructions have been sent.")
        } catch let error as APIError {
            applyValidation(error)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reset(token: String, password: String, confirmation: String) async {
        guard !isResetting else { return }
        guard password == confirmation else {
            errorMessage = String(localized: "Passwords do not match.")
            return
        }
        isResetting = true
        errorMessage = nil
        successMessage = nil
        fieldErrors = [:]
        defer { isResetting = false }

        do {
            try await api.resetPassword(
                PasswordResetInput(
                    resetPasswordToken: token.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password,
                    passwordConfirmation: confirmation
                )
            )
            successMessage = String(localized: "Your password has been updated. You can now sign in.")
        } catch let error as APIError {
            applyValidation(error)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyValidation(_ error: APIError) {
        if let summary = error.validationSummary {
            errorMessage = summary
        } else {
            errorMessage = error.localizedDescription
        }
        fieldErrors = error.validationDetails.mapValues { $0.joined(separator: "\n") }
    }
}

@MainActor
@Observable
final class ConfirmationModel {
    var isSubmitting = false
    var isConfirming = false
    var errorMessage: String?
    var successMessage: String?
    var fieldErrors: [String: String] = [:]

    private let api: APIClient
    private let session: SessionStore

    init(api: APIClient, session: SessionStore) {
        self.api = api
        self.session = session
    }

    func resend(email: String) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        successMessage = nil
        fieldErrors = [:]
        defer { isSubmitting = false }

        do {
            try await api.resendConfirmation(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            successMessage = String(localized: "Confirmation instructions have been sent.")
        } catch let error as APIError {
            applyValidation(error)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirm(token: String) async -> Bool {
        guard !isConfirming else { return false }
        isConfirming = true
        errorMessage = nil
        successMessage = nil
        fieldErrors = [:]
        defer { isConfirming = false }

        do {
            try await session.confirmUser(token: token.trimmingCharacters(in: .whitespacesAndNewlines))
            return true
        } catch let error as APIError {
            applyValidation(error)
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func applyValidation(_ error: APIError) {
        if let summary = error.validationSummary {
            errorMessage = summary
        } else {
            errorMessage = error.localizedDescription
        }
        fieldErrors = error.validationDetails.mapValues { $0.joined(separator: "\n") }
    }
}
