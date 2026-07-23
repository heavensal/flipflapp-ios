import Foundation
import Observation

@MainActor
@Observable
final class FriendsSearchModel {
    var query = ""
    private(set) var state: LoadState<[PublicUser]> = .empty
    private(set) var sendingUserID: UserID?
    var errorMessage: String?

    private let api: APIClient
    private let session: SessionStore

    init(api: APIClient, session: SessionStore) {
        self.api = api
        self.session = session
    }

    func search() async {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            state = .empty
            return
        }
        do {
            try await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            state = .loading
            let users = try await api.searchFriendshipCandidates(query: value)
            guard value == query.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            state = users.isEmpty ? .empty : .loaded(users)
        } catch is CancellationError {
            return
        } catch let error as APIError {
            if case .cancelled = error { return }
            await session.handleAPIError(error)
            state = .failed(error)
        } catch {
            state = .failed(.invalidResponse)
        }
    }

    func sendRequest(to user: PublicUser) async -> Bool {
        guard sendingUserID == nil else { return false }
        sendingUserID = user.id
        errorMessage = nil
        defer { sendingUserID = nil }
        do {
            _ = try await api.createFriendship(userID: user.id)
            if case var .loaded(users) = state {
                users.removeAll { $0.id == user.id }
                state = users.isEmpty ? .empty : .loaded(users)
            }
            return true
        } catch let error as APIError {
            await session.handleAPIError(error)
            errorMessage = error.localizedDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
