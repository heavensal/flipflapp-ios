import SwiftUI

struct SignInScreen: View {
    @State private var model: SignInModel
    @State private var email = ""
    @State private var password = ""

    let initialMessage: String?

    init(session: SessionStore, initialMessage: String?) {
        _model = State(initialValue: SignInModel(session: session))
        self.initialMessage = initialMessage
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                AuthenticationHero()

                CardSurface {
                    VStack(spacing: 16) {
                        TextField(String(localized: "Email"), text: $email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Divider()

                        SecureField(String(localized: "Password"), text: $password)
                            .textContentType(.password)

                        if let message = model.errorMessage ?? initialMessage {
                            InlineErrorView(message: message)
                        }

                        Button {
                            Task { await model.signIn(email: email, password: password) }
                        } label: {
                            ProgressButtonLabel(
                                title: "Sign in",
                                systemImage: "arrow.right.circle.fill",
                                isWorking: model.isSubmitting
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(email.isEmpty || password.isEmpty || model.isSubmitting)
                    }
                }

                VStack(spacing: 12) {
                    NavigationLink(String(localized: "Create an account"), value: AuthenticationDestination.registration)
                    NavigationLink(String(localized: "Forgot your password?"), value: AuthenticationDestination.passwordRecovery)
                    NavigationLink(String(localized: "Resend confirmation email"), value: AuthenticationDestination.confirmation)
                }
                .font(.callout)
            }
            .padding(20)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "Sign in"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AuthenticationHero: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.soccer")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.indigo)
                .accessibilityHidden(true)
            Text("FlipFlapp")
                .font(.largeTitle.bold())
            Text(String(localized: "Organize your football events with friends."))
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
