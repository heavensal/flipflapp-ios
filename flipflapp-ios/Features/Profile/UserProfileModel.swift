import Observation

@MainActor
@Observable
final class UserProfileModel {
    private(set) var state: LoadState<PublicUser> = .idle

    private let userID: UserID
    private let api: APIClient
    private let session: SessionStore

    init(userID: UserID, api: APIClient, session: SessionStore) {
        self.userID = userID
        self.api = api
        self.session = session
    }

    func load() async {
        guard case .idle = state else { return }
        state = .loading
        do {
            state = .loaded(try await api.user(id: userID))
        } catch let error as APIError {
            await session.handleAPIError(error)
            state = .failed(error)
        } catch {
            state = .failed(.invalidResponse)
        }
    }

    func retry() async {
        state = .idle
        await load()
    }
}
