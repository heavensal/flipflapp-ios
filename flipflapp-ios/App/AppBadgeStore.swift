import Observation

@MainActor
@Observable
final class AppBadgeStore {
    var unreadNotifications = 0
    var receivedFriendRequests = 0
}
