import PhotosUI
import SwiftUI

struct ProfileScreen: View {
    let session: SessionStore

    @State private var model: ProfileModel
    @State private var isConfirmingSignOut = false
    @State private var selectedPhoto: PhotosPickerItem?

    init(api: APIClient, session: SessionStore, currentUser: CurrentUser) {
        self.session = session
        _model = State(initialValue: ProfileModel(api: api, session: session, currentUser: currentUser))
    }

    private var currentUser: CurrentUser? {
        session.currentUser
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        if let user = currentUser {
                            AvatarView(user: user.publicProfile, size: 64)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.title3.bold())
                                if let username = user.username {
                                    Text(username)
                                        .foregroundStyle(.secondary)
                                }
                                if user.role == .admin {
                                    StatusPill(title: "Administrator", systemImage: "checkmark.seal.fill")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(String(localized: "Change photo"), systemImage: "photo")
                    }
                    .disabled(model.isUpdatingAvatar)

                    if currentUser?.avatarURL != nil {
                        Button(String(localized: "Remove photo"), role: .destructive) {
                            Task { await model.removeAvatar() }
                        }
                        .disabled(model.isUpdatingAvatar)
                    }
                }

                Section(String(localized: "Personal information")) {
                    TextField(String(localized: "First name"), text: $model.firstName)
                        .textContentType(.givenName)
                    TextField(String(localized: "Last name"), text: $model.lastName)
                        .textContentType(.familyName)
                    TextField(String(localized: "Email"), text: $model.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                if let pendingEmailMessage = model.pendingEmailMessage {
                    Section {
                        Label(pendingEmailMessage, systemImage: "envelope.badge")
                            .foregroundStyle(.orange)
                    }
                }

                Section {
                    SecureField(String(localized: "New password (optional)"), text: $model.password)
                        .textContentType(.newPassword)
                    SecureField(String(localized: "Confirm new password"), text: $model.passwordConfirmation)
                        .textContentType(.newPassword)
                } header: {
                    Text(String(localized: "Security"))
                } footer: {
                    Text(String(localized: "Leave both fields empty to keep your current password."))
                }

                if let errorMessage = model.errorMessage {
                    Section { InlineErrorView(message: errorMessage) }
                }
                if let successMessage = model.successMessage {
                    Section {
                        Label(successMessage, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Section {
                    Button {
                        Task { await model.save() }
                    } label: {
                        ProgressButtonLabel(
                            title: "Save profile",
                            systemImage: "checkmark.circle.fill",
                            isWorking: model.isSaving
                        )
                    }
                    .disabled(
                        model.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || model.lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || model.email.isEmpty
                            || model.isSaving
                    )
                }

                Section {
                    Button(role: .destructive) {
                        isConfirmingSignOut = true
                    } label: {
                        Label(String(localized: "Sign out"), systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle(String(localized: "Profile"))
            .onChange(of: selectedPhoto) { _, newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self) {
                        let mimeType = newValue.supportedContentTypes.first?.preferredMIMEType ?? "image/jpeg"
                        let filename = newValue.supportedContentTypes.first?.preferredFilenameExtension.map { "avatar.\($0)" } ?? "avatar.jpg"
                        await model.uploadAvatar(data: data, filename: filename, mimeType: mimeType)
                    }
                    selectedPhoto = nil
                }
            }
            .confirmationDialog(
                String(localized: "Sign out of FlipFlapp?"),
                isPresented: $isConfirmingSignOut,
                titleVisibility: .visible
            ) {
                Button(String(localized: "Sign out"), role: .destructive) {
                    Task { await model.signOut() }
                }
                Button(String(localized: "Cancel"), role: .cancel) {}
            }
        }
    }
}
