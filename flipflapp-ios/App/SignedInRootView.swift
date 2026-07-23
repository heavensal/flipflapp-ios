import SwiftUI

struct SignedInRootView: View {
    let environment: AppEnvironment
    let session: SessionStore
    let currentUser: CurrentUser

    @State private var badges = AppBadgeStore()

    var body: some View {
        TabView {
            Tab(String(localized: "Events"), systemImage: "sportscourt.fill") {
                EventsScreen(
                    api: environment.api,
                    session: session,
                    currentUser: currentUser
                )
            }

            Tab(String(localized: "Friends"), systemImage: "person.2.fill") {
                FriendsScreen(
                    api: environment.api,
                    session: session,
                    currentUser: currentUser,
                    badges: badges
                )
            }
            .badge(badges.receivedFriendRequests)

            Tab(String(localized: "Notifications"), systemImage: "bell.fill") {
                NotificationsScreen(
                    api: environment.api,
                    session: session,
                    currentUser: currentUser,
                    badges: badges
                )
            }
            .badge(badges.unreadNotifications)

            Tab(String(localized: "Profile"), systemImage: "person.crop.circle.fill") {
                ProfileScreen(api: environment.api, session: session, currentUser: currentUser)
            }
        }
        .tint(.indigo)
    }
}
