import SwiftUI

struct AuthenticationRootView: View {
    let api: APIClient
    let session: SessionStore
    let initialMessage: String?

    var body: some View {
        NavigationStack {
            SignInScreen(session: session, initialMessage: initialMessage)
                .navigationDestination(for: AuthenticationDestination.self) { destination in
                    switch destination {
                    case .registration:
                        RegistrationScreen(api: api)
                    case .passwordRecovery:
                        PasswordRecoveryScreen(api: api)
                    case .confirmation:
                        ConfirmationScreen(api: api)
                    }
                }
        }
    }
}

enum AuthenticationDestination: Hashable {
    case registration
    case passwordRecovery
    case confirmation
}
