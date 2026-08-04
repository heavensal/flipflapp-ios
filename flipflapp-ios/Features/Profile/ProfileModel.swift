import Foundation
import Observation

@MainActor
@Observable
final class ProfileModel {
    var firstName: String
    var lastName: String
    var email: String
    var password = ""
    var passwordConfirmation = ""
    private(set) var isSaving = false
    private(set) var isSigningOut = false
    private(set) var isUpdatingAvatar = false
    var errorMessage: String?
    var successMessage: String?
    var fieldErrors: [String: String] = [:]

    private let api: APIClient
    private let session: SessionStore

    var pendingEmailMessage: String? {
        guard let pending = session.currentUser?.unconfirmedEmail, !pending.isEmpty else { return nil }
        return String(format: String(localized: "Confirm %@ from your inbox to finish changing your email."), pending)
    }

    init(api: APIClient, session: SessionStore, currentUser: CurrentUser) {
        self.api = api
        self.session = session
        firstName = currentUser.firstName ?? ""
        lastName = currentUser.lastName ?? ""
        email = currentUser.email
    }

    func save() async {
        guard !isSaving else { return }
        guard password.isEmpty || password == passwordConfirmation else {
            errorMessage = String(localized: "Passwords do not match.")
            return
        }

        isSaving = true
        errorMessage = nil
        successMessage = nil
        fieldErrors = [:]
        defer { isSaving = false }

        do {
            let passwordValue = password.isEmpty ? nil : password
            let updated = try await api.updateCurrentUser(
                UserUpdateInput(
                    firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                    lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: passwordValue,
                    passwordConfirmation: passwordValue == nil ? nil : passwordConfirmation
                )
            )
            password = ""
            passwordConfirmation = ""
            session.updateCurrentUser(updated)
            successMessage = String(localized: "Your profile has been updated.")
        } catch let error as APIError {
            await session.handleAPIError(error)
            applyValidation(error)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func uploadAvatar(data: Data, filename: String, mimeType: String) async {
        guard !isUpdatingAvatar else { return }
        isUpdatingAvatar = true
        errorMessage = nil
        defer { isUpdatingAvatar = false }

        do {
            let updated = try await api.updateCurrentUserAvatar(
                data: data,
                filename: filename,
                mimeType: mimeType
            )
            session.updateCurrentUser(updated)
            successMessage = String(localized: "Your profile photo has been updated.")
        } catch let error as APIError {
            await session.handleAPIError(error)
            applyValidation(error)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeAvatar() async {
        guard !isUpdatingAvatar else { return }
        isUpdatingAvatar = true
        errorMessage = nil
        defer { isUpdatingAvatar = false }
        do {
            let updated = try await api.removeCurrentUserAvatar()
            session.updateCurrentUser(updated)
            successMessage = String(localized: "Your profile photo has been removed.")
        } catch let error as APIError {
            await session.handleAPIError(error)
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        guard !isSigningOut else { return }
        isSigningOut = true
        await session.signOut()
        isSigningOut = false
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
