import Foundation
import Observation

@MainActor
@Observable
final class FriendsModel {
    private(set) var state: LoadState<FriendshipBuckets> = .idle
    private(set) var isRefreshing = false
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
        actionErrorMessage = nil
        if state.hasContent {
            isRefreshing = true
            defer { isRefreshing = false }
            await fetch()
        } else {
            state = .loading
            await fetch()
        }
    }

    func accept(_ friendship: Friendship) async {
        await transition(friendship, to: .accepted) {
            if case let .loaded(buckets) = state {
                let updated = FriendshipBuckets(
                    accepted: buckets.accepted,
                    sent: buckets.sent,
                    received: buckets.received.filter { $0.id != friendship.id },
                    declined: buckets.declined
                )
                state = updated.isTotallyEmpty ? .empty : .loaded(updated)
                badges.receivedFriendRequests = max(0, badges.receivedFriendRequests - 1)
            }
        }
    }

    func decline(_ friendship: Friendship) async {
        await transition(friendship, to: .declined) {
            if case let .loaded(buckets) = state {
                let updated = FriendshipBuckets(
                    accepted: buckets.accepted,
                    sent: buckets.sent,
                    received: buckets.received.filter { $0.id != friendship.id },
                    declined: buckets.declined
                )
                state = updated.isTotallyEmpty ? .empty : .loaded(updated)
                badges.receivedFriendRequests = max(0, badges.receivedFriendRequests - 1)
            }
        }
    }

    func delete(_ friendship: Friendship) async {
        guard mutatingFriendshipID == nil else { return }
        mutatingFriendshipID = friendship.id
        actionErrorMessage = nil

        let snapshot = state.loadedValue
        if case var .loaded(buckets) = state {
            buckets = remove(friendship, from: buckets)
            state = buckets.isTotallyEmpty ? .empty : .loaded(buckets)
        }

        defer { mutatingFriendshipID = nil }
        do {
            try await api.deleteFriendship(id: friendship.id)
            await fetchSilently()
        } catch let error as APIError {
            if let snapshot {
                state = snapshot.isTotallyEmpty ? .empty : .loaded(snapshot)
            }
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
        } catch {
            if let snapshot {
                state = snapshot.isTotallyEmpty ? .empty : .loaded(snapshot)
            }
            actionErrorMessage = error.localizedDescription
        }
    }

    private func transition(
        _ friendship: Friendship,
        to status: Friendship.Status,
        optimistic: () -> Void
    ) async {
        guard mutatingFriendshipID == nil else { return }
        mutatingFriendshipID = friendship.id
        actionErrorMessage = nil
        let snapshot = state.loadedValue
        optimistic()
        defer { mutatingFriendshipID = nil }
        do {
            _ = try await api.updateFriendship(id: friendship.id, status: status)
            await fetchSilently()
        } catch let error as APIError {
            if let snapshot {
                state = snapshot.isTotallyEmpty ? .empty : .loaded(snapshot)
                badges.receivedFriendRequests = snapshot.received.count
            }
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
        } catch {
            if let snapshot {
                state = snapshot.isTotallyEmpty ? .empty : .loaded(snapshot)
            }
            actionErrorMessage = error.localizedDescription
        }
    }

    private func fetch() async {
        do {
            let buckets = try await api.friendships()
            badges.receivedFriendRequests = buckets.received.count
            state = buckets.isTotallyEmpty ? .empty : .loaded(buckets)
        } catch let error as APIError {
            await session.handleAPIError(error)
            if case .cancelled = error { return }
            if !state.hasContent {
                state = .failed(error)
            } else {
                actionErrorMessage = error.localizedDescription
            }
        } catch {
            if !state.hasContent {
                state = .failed(.invalidResponse)
            }
        }
    }

    private func fetchSilently() async {
        guard let buckets = try? await api.friendships() else { return }
        badges.receivedFriendRequests = buckets.received.count
        state = buckets.isTotallyEmpty ? .empty : .loaded(buckets)
    }

    private func remove(_ friendship: Friendship, from buckets: FriendshipBuckets) -> FriendshipBuckets {
        FriendshipBuckets(
            accepted: buckets.accepted.filter { $0.id != friendship.id },
            sent: buckets.sent.filter { $0.id != friendship.id },
            received: buckets.received.filter { $0.id != friendship.id },
            declined: buckets.declined.filter { $0.id != friendship.id }
        )
    }
}

private extension FriendshipBuckets {
    var isTotallyEmpty: Bool {
        accepted.isEmpty && sent.isEmpty && received.isEmpty && declined.isEmpty
    }
}
