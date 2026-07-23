import SwiftUI

struct ConfirmationScreen: View {
    @State private var model: ConfirmationModel
    @State private var email = ""

    init(api: APIClient) {
        _model = State(initialValue: ConfirmationModel(api: api))
    }

    var body: some View {
        Form {
            Section {
                TextField(String(localized: "Email"), text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } footer: {
                Text(String(localized: "We will send a fresh account confirmation link."))
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
