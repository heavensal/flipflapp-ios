import Foundation
import Observation

@MainActor
@Observable
final class FriendsModel {
    private(set) var state: LoadState<FriendshipBuckets> = .idle
    private(set) var mutatingFriendshipID: FriendshipID?
    var actionErrorMessage: String?

    private let api: APIClient
    private let session: SessionStore
    private let badges: AppBadgeStore

    init(api: APIClient, session: SessionStore, badges: AppBadgeStore) {
        self.api = api
        self.session = session
        self.badges = badges
    }

    func load() async {
        if case .loading = state { return }
        if case .idle = state { state = .loading }
        await fetch()
    }

    func retry() async {
        state = .loading
        await fetch()
    }

    func accept(_ friendship: Friendship) async {
        await transition(friendship, to: .accepted)
    }

    func decline(_ friendship: Friendship) async {
        await transition(friendship, to: .declined)
    }

    func delete(_ friendship: Friendship) async {
        guard mutatingFriendshipID == nil else { return }
        mutatingFriendshipID = friendship.id
        actionErrorMessage = nil
        defer { mutatingFriendshipID = nil }
        do {
            try await api.deleteFriendship(id: friendship.id)
            await fetch()
        } catch let error as APIError {
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    private func transition(_ friendship: Friendship, to status: Friendship.Status) async {
        guard mutatingFriendshipID == nil else { return }
        mutatingFriendshipID = friendship.id
        actionErrorMessage = nil
        defer { mutatingFriendshipID = nil }
        do {
            _ = try await api.updateFriendship(id: friendship.id, status: status)
            await fetch()
        } catch let error as APIError {
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    private func fetch() async {
        do {
            let buckets = try await api.friendships()
            badges.receivedFriendRequests = buckets.received.count
            let isEmpty = buckets.accepted.isEmpty
                && buckets.sent.isEmpty
                && buckets.received.isEmpty
                && buckets.declined.isEmpty
            state = isEmpty ? .empty : .loaded(buckets)
        } catch let error as APIError {
            await session.handleAPIError(error)
            if case .cancelled = error { return }
            state = .failed(error)
        } catch {
            state = .failed(.invalidResponse)
        }
    }
}
