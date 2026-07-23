import SwiftUI

struct ContentView: View {
    let container: AppContainer

    var body: some View {
        Group {
            switch container.state {
            case .idle:
                ProgressView(String(localized: "Preparing FlipFlapp…"))
            case let .failed(message):
                ContentUnavailableView(
                    String(localized: "Unable to start FlipFlapp"),
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            case let .ready(environment, session):
                sessionRoot(environment: environment, session: session)
            }
        }
        .task {
            await container.start()
        }
    }

    @ViewBuilder
    private func sessionRoot(environment: AppEnvironment, session: SessionStore) -> some View {
        switch session.state {
        case .restoring:
            ProgressView(String(localized: "Restoring your session…"))
        case let .restorationFailed(message):
            ContentUnavailableView {
                Label(String(localized: "Unable to load"), systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button(String(localized: "Try again")) {
                    Task { await session.restore() }
                }
                .buttonStyle(.borderedProminent)
            }
        case .signedOut:
            AuthenticationRootView(
                api: environment.api,
                session: session,
                initialMessage: nil
            )
        case let .signedIn(user):
            SignedInRootView(environment: environment, session: session, currentUser: user)
        }
    }
}
