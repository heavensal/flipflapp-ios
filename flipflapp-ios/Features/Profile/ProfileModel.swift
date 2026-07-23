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
    var errorMessage: String?
    var successMessage: String?

    private let api: APIClient
    private let session: SessionStore

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
}
