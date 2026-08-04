import SwiftUI

struct PasswordRecoveryScreen: View {
    @State private var model: PasswordRecoveryModel
    @State private var email = ""
    @State private var token: String
    @State private var password = ""
    @State private var confirmation = ""

    init(api: APIClient, initialResetToken: String = "") {
        _model = State(initialValue: PasswordRecoveryModel(api: api))
        _token = State(initialValue: initialResetToken)
    }

    var body: some View {
        Form {
            Section {
                TextField(String(localized: "Email"), text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button(String(localized: "Send reset instructions")) {
                    Task { await model.request(email: email) }
                }
                .disabled(email.isEmpty || model.isRequesting)
            } header: {
                Text(String(localized: "Request a reset"))
            } footer: {
                Text(String(localized: "You will receive a secure reset token by email."))
            }

            Section(String(localized: "Set a new password")) {
                TextField(String(localized: "Reset token"), text: $token)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField(String(localized: "New password"), text: $password)
                    .textContentType(.newPassword)
                SecureField(String(localized: "Confirm password"), text: $confirmation)
                    .textContentType(.newPassword)
                Button(String(localized: "Update password")) {
                    Task {
                        await model.reset(token: token, password: password, confirmation: confirmation)
                    }
                }
                .disabled(token.isEmpty || password.count < 6 || confirmation.isEmpty || model.isResetting)
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
        }
        .navigationTitle(String(localized: "Password reset"))
    }
}
