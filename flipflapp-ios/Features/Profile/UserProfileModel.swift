import Foundation
import Observation

enum UserProfileFriendshipState: Equatable {
    case loading
    case canSend
    case pendingSent
    case pendingReceived
    case friends
    case unavailable
}

@MainActor
@Observable
final class UserProfileModel {
    private(set) var state: LoadState<PublicUser> = .idle
    private(set) var friendshipState: UserProfileFriendshipState = .loading
    private(set) var isSending = false
    var actionErrorMessage: String?

    private let userID: UserID
    private let currentUserID: UserID
    private let api: APIClient
    private let session: SessionStore

    init(userID: UserID, api: APIClient, session: SessionStore, currentUserID: UserID) {
        self.userID = userID
        self.currentUserID = currentUserID
        self.api = api
        self.session = session
    }

    func load() async {
        guard case .idle = state else { return }
        state = .loading
        await fetchProfile()
    }

    func retry() async {
        if state.hasContent {
            await fetchProfile()
        } else {
            state = .loading
            await fetchProfile()
        }
    }

    func sendFriendRequest() async -> Bool {
        guard friendshipState == .canSend, !isSending else { return false }
        isSending = true
        actionErrorMessage = nil
        defer { isSending = false }
        do {
            _ = try await api.createFriendship(userID: userID)
            friendshipState = .pendingSent
            return true
        } catch let error as APIError {
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
            return false
        } catch {
            actionErrorMessage = error.localizedDescription
            return false
        }
    }

    private func fetchProfile() async {
        do {
            async let user = api.user(id: userID)
            async let buckets = api.friendships()
            let values = try await (user, buckets)
            state = .loaded(values.0)
            friendshipState = resolveFriendshipState(buckets: values.1)
        } catch let error as APIError {
            await session.handleAPIError(error)
            state = .failed(error)
        } catch {
            state = .failed(.invalidResponse)
        }
    }

    private func resolveFriendshipState(buckets: FriendshipBuckets) -> UserProfileFriendshipState {
        if userID == currentUserID { return .unavailable }
        let all = buckets.accepted + buckets.sent + buckets.received + buckets.declined
        guard let friendship = all.first(where: {
            $0.senderID == userID || $0.receiverID == userID
        }) else {
            return .canSend
        }
        switch friendship.status {
        case .accepted:
            return .friends
        case .pending:
            return friendship.senderID == currentUserID ? .pendingSent : .pendingReceived
        case .declined:
            return friendship.receiverID == currentUserID ? .canSend : .unavailable
        }
    }
}
