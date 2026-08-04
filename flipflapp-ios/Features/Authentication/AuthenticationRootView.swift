import SwiftUI

struct AuthenticationRootView: View {
    let api: APIClient
    let session: SessionStore
    let initialMessage: String?
    let deepLinkRouter: AppDeepLinkRouter

    @State private var resetToken = ""

    var body: some View {
        NavigationStack {
            SignInScreen(session: session, initialMessage: initialMessage)
                .navigationDestination(for: AuthenticationDestination.self) { destination in
                    switch destination {
                    case .registration:
                        RegistrationScreen(api: api)
                    case .passwordRecovery:
                        PasswordRecoveryScreen(api: api, initialResetToken: resetToken)
                    case .confirmation:
                        ConfirmationScreen(api: api, session: session)
                    }
                }
        }
        .onChange(of: deepLinkRouter.pending) { _, newValue in
            guard let link = newValue else { return }
            handleDeepLink(link)
        }
        .task {
            if let link = deepLinkRouter.consume() {
                handleDeepLink(link)
            }
        }
    }

    private func handleDeepLink(_ link: AppDeepLink) {
        switch link {
        case let .confirmAccount(token):
            Task {
                try? await session.confirmUser(token: token)
            }
        case let .resetPassword(token):
            resetToken = token
        }
    }
}

enum AuthenticationDestination: Hashable {
    case registration
    case passwordRecovery
    case confirmation
}
