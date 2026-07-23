import Observation
import OSLog

@MainActor
@Observable
final class AppBadgeStore {
    var unreadNotifications = 0
    var receivedFriendRequests = 0

    private let logger = Logger(subsystem: "fr.flipflapp.ios", category: "Badges")

    func load(api: APIClient, session: SessionStore) async {
        async let friendRequests: Void = loadFriendRequests(api: api, session: session)
        async let notifications: Void = loadNotifications(api: api, session: session)
        _ = await (friendRequests, notifications)
    }

    private func loadFriendRequests(api: APIClient, session: SessionStore) async {
        do {
            receivedFriendRequests = try await api.friendships().received.count
        } catch let error as APIError {
            await session.handleAPIError(error)
        } catch {
            logger.notice("Initial friend request badge loading failed")
        }
    }

    private func loadNotifications(api: APIClient, session: SessionStore) async {
        do {
            unreadNotifications = try await api.notifications().filter { !$0.read }.count
        } catch let error as APIError {
            await session.handleAPIError(error)
        } catch {
            logger.notice("Initial notification badge loading failed")
        }
    }
}
