import SwiftUI

struct RegistrationScreen: View {
    @State private var model: RegistrationModel
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""

    init(api: APIClient) {
        _model = State(initialValue: RegistrationModel(api: api))
    }

    var body: some View {
        Form {
            Section(String(localized: "Your profile")) {
                TextField(String(localized: "First name"), text: $firstName)
                    .textContentType(.givenName)
                TextField(String(localized: "Last name"), text: $lastName)
                    .textContentType(.familyName)
                TextField(String(localized: "Email"), text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section(String(localized: "Password")) {
                SecureField(String(localized: "Password"), text: $password)
                    .textContentType(.newPassword)
                SecureField(String(localized: "Confirm password"), text: $confirmation)
                    .textContentType(.newPassword)
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
                    Task {
                        await model.register(
                            firstName: firstName,
                            lastName: lastName,
                            email: email,
                            password: password,
                            confirmation: confirmation
                        )
                    }
                } label: {
                    ProgressButtonLabel(
                        title: "Create account",
                        systemImage: "person.crop.circle.badge.plus",
                        isWorking: model.isSubmitting
                    )
                }
                .disabled(!isComplete || model.isSubmitting)
            }
        }
        .navigationTitle(String(localized: "Create an account"))
    }

    private var isComplete: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty && password.count >= 6 && !confirmation.isEmpty
    }
}
