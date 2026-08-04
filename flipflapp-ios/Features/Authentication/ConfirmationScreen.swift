import SwiftUI

struct ConfirmationScreen: View {
    @State private var model: ConfirmationModel
    @State private var email = ""
    @State private var token = ""

    init(api: APIClient, session: SessionStore) {
        _model = State(initialValue: ConfirmationModel(api: api, session: session))
    }

    var body: some View {
        Form {
            Section {
                TextField(String(localized: "Email"), text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text(String(localized: "Resend confirmation"))
            } footer: {
                Text(String(localized: "We will send a fresh account confirmation link."))
            }

            Section {
                TextField(String(localized: "Confirmation token"), text: $token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button {
                    Task { _ = await model.confirm(token: token) }
                } label: {
                    ProgressButtonLabel(
                        title: "Confirm account",
                        systemImage: "checkmark.seal.fill",
                        isWorking: model.isConfirming
                    )
                }
                .disabled(token.isEmpty || model.isConfirming)
            } header: {
                Text(String(localized: "Confirm with token"))
            } footer: {
                Text(String(localized: "Paste the token from your confirmation email to sign in automatically."))
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
                    Task { await model.resend(email: email) }
                } label: {
                    ProgressButtonLabel(
                        title: "Send confirmation",
                        systemImage: "envelope.fill",
                        isWorking: model.isSubmitting
                    )
                }
                .disabled(email.isEmpty || model.isSubmitting)
            }
        }
        .navigationTitle(String(localized: "Confirm your account"))
    }
}
