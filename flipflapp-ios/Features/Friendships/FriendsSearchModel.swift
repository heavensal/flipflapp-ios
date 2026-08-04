import Foundation
import Observation

@MainActor
@Observable
final class FriendsSearchModel {
    var query = "" {
        didSet { scheduleSearch() }
    }

    private(set) var results: [PublicUser] = []
    private(set) var isSearching = false
    private(set) var sentUserIDs: Set<UserID> = []
    private(set) var sendingUserID: UserID?
    var errorMessage: String?

    private let api: APIClient
    private let session: SessionStore
    private let debouncer = DebouncedTask()
    private var searchGeneration = 0

    init(api: APIClient, session: SessionStore) {
        self.api = api
        self.session = session
    }

    func scheduleSearch() {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count >= 2 else {
            debouncer.cancel()
            isSearching = false
            results = []
            errorMessage = nil
            return
        }

        isSearching = true
        debouncer.schedule { [weak self] in
            await self?.performSearch()
        }
    }

    private func performSearch() async {
        let value = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.count >= 2 else {
            isSearching = false
            return
        }

        searchGeneration += 1
        let generation = searchGeneration
        errorMessage = nil

        do {
            let users = try await api.searchFriendshipCandidates(query: value)
            guard generation == searchGeneration else { return }
            guard value == query.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            results = users.filter { !sentUserIDs.contains($0.id) }
            isSearching = false
        } catch is CancellationError {
            return
        } catch let error as APIError {
            guard generation == searchGeneration else { return }
            if case .cancelled = error { return }
            await session.handleAPIError(error)
            errorMessage = error.localizedDescription
            isSearching = false
        } catch {
            guard generation == searchGeneration else { return }
            errorMessage = error.localizedDescription
            isSearching = false
        }
    }

    func sendRequest(to user: PublicUser) async -> Bool {
        guard sendingUserID == nil else { return false }
        sendingUserID = user.id
        errorMessage = nil
        defer { sendingUserID = nil }

        sentUserIDs.insert(user.id)
        results.removeAll { $0.id == user.id }

        do {
            _ = try await api.createFriendship(userID: user.id)
            return true
        } catch let error as APIError {
            sentUserIDs.remove(user.id)
            await session.handleAPIError(error)
            errorMessage = error.localizedDescription
            await performSearch()
            return false
        } catch {
            sentUserIDs.remove(user.id)
            errorMessage = error.localizedDescription
            await performSearch()
            return false
        }
    }
}
