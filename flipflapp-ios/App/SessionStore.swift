import Foundation
import Observation
import OSLog

enum SessionState: Sendable {
    case restoring
    case signedOut
    case signedIn(CurrentUser)
}

@MainActor
@Observable
final class SessionStore {
    private(set) var state: SessionState = .restoring
    private(set) var restorationMessage: String?

    private let api: APIClient
    private let tokenStore: any TokenStoring
    private let logger = Logger(subsystem: "fr.flipflapp.ios", category: "Session")

    init(api: APIClient, tokenStore: any TokenStoring) {
        self.api = api
        self.tokenStore = tokenStore
    }

    var currentUser: CurrentUser? {
        guard case let .signedIn(user) = state else { return nil }
        return user
    }

    func restore() async {
        state = .restoring
        restorationMessage = nil
        do {
            guard try await tokenStore.readToken() != nil else {
                state = .signedOut
                return
            }
            state = .signedIn(try await api.currentUser())
        } catch let error as APIError where error.isUnauthorized {
            try? await tokenStore.deleteToken()
            state = .signedOut
        } catch {
            restorationMessage = error.localizedDescription
            state = .signedOut
        }
    }

    func signIn(email: String, password: String) async throws {
        let authenticatedSession = try await api.signIn(email: email, password: password)
        do {
            try await tokenStore.writeToken(authenticatedSession.token)
            state = .signedIn(authenticatedSession.user)
        } catch {
            try? await tokenStore.deleteToken()
            throw error
        }
    }

    func signOut() async {
        do {
            try await api.signOut()
        } catch {
            logger.notice("Remote token revocation failed during explicit sign-out")
        }
        try? await tokenStore.deleteToken()
        state = .signedOut
    }

    func updateCurrentUser(_ user: CurrentUser) {
        state = .signedIn(user)
    }

    func handleAPIError(_ error: APIError) async {
        guard error.isUnauthorized else { return }
        try? await tokenStore.deleteToken()
        state = .signedOut
    }
}
