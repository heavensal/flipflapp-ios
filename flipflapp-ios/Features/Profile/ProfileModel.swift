import Foundation
import Observation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
@Observable
final class ProfileModel {
    var firstName: String
    var lastName: String
    var email: String
    var password = ""
    var passwordConfirmation = ""
    var selectedPhoto: PhotosPickerItem?
    private(set) var localAvatarPreview: UIImage?
    private(set) var isSaving = false
    private(set) var isUploadingAvatar = false
    private(set) var isSigningOut = false
    private(set) var isUpdatingAvatar = false
    var errorMessage: String?
    var successMessage: String?
    var fieldErrors: [String: String] = [:]

    private let api: APIClient
    private let session: SessionStore
    private let fallbackUser: CurrentUser

    var pendingEmailMessage: String? {
        guard let pending = session.currentUser?.unconfirmedEmail, !pending.isEmpty else { return nil }
        return String(format: String(localized: "Confirm %@ from your inbox to finish changing your email."), pending)
    }

    init(api: APIClient, session: SessionStore, currentUser: CurrentUser) {
        self.api = api
        self.session = session
        fallbackUser = currentUser
        firstName = currentUser.firstName ?? ""
        lastName = currentUser.lastName ?? ""
        email = currentUser.email
    }

    var displayedUser: CurrentUser {
        session.currentUser ?? fallbackUser
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

    func handleSelectedPhotoChange() async {
        guard let selectedPhoto else { return }
        await uploadAvatar(from: selectedPhoto)
        self.selectedPhoto = nil
    }

    func signOut() async {
        guard !isSigningOut else { return }
        isSigningOut = true
        await session.signOut()
        isSigningOut = false
    }

    private func uploadAvatar(from item: PhotosPickerItem) async {
        guard !isUploadingAvatar else { return }

        isUploadingAvatar = true
        errorMessage = nil
        successMessage = nil
        defer { isUploadingAvatar = false }

        do {
            guard let rawData = try await item.loadTransferable(type: Data.self) else {
                errorMessage = String(localized: "Could not read that photo. Try another one.")
                return
            }
            guard let image = UIImage(data: rawData),
                  let jpegData = Self.jpegData(from: image)
            else {
                errorMessage = String(localized: "Only JPEG, PNG, or GIF photos are supported.")
                return
            }

            localAvatarPreview = image
            let updated = try await api.updateCurrentUserAvatar(.jpeg(jpegData))
            session.updateCurrentUser(updated)
            successMessage = String(localized: "Your profile photo has been updated.")
        } catch let error as APIError {
            localAvatarPreview = nil
            await session.handleAPIError(error)
            errorMessage = error.localizedDescription
        } catch {
            localAvatarPreview = nil
            errorMessage = error.localizedDescription
        }
    }

    private static func jpegData(from image: UIImage, maxPixelSize: CGFloat = 1600, quality: CGFloat = 0.82) -> Data? {
        let longestSide = max(image.size.width, image.size.height)
        let scaledImage: UIImage
        if longestSide > maxPixelSize {
            let scale = maxPixelSize / longestSide
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: size)
            scaledImage = renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        } else {
            scaledImage = image
        }
        return scaledImage.jpegData(compressionQuality: quality)
    }
}
