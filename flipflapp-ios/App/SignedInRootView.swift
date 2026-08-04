import SwiftUI

struct SignedInRootView: View {
    let environment: AppEnvironment
    let session: SessionStore
    let currentUser: CurrentUser
    let deepLinkRouter: AppDeepLinkRouter
    let pushNavigationRouter: PushNavigationRouter

    @State private var badges = AppBadgeStore()
    @State private var selectedTab = 0
    @State private var pendingEventID: EventID?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(String(localized: "Events"), systemImage: "sportscourt.fill", value: 0) {
                EventsScreen(
                    api: environment.api,
                    session: session,
                    currentUser: session.currentUser ?? currentUser,
                    pendingEventID: $pendingEventID
                )
            }

            Tab(String(localized: "Friends"), systemImage: "person.2.fill", value: 1) {
                FriendsScreen(
                    api: environment.api,
                    session: session,
                    currentUser: session.currentUser ?? currentUser,
                    badges: badges
                )
            }
            .badge(badges.receivedFriendRequests)

            Tab(String(localized: "Notifications"), systemImage: "bell.fill", value: 2) {
                NotificationsScreen(
                    api: environment.api,
                    session: session,
                    currentUser: session.currentUser ?? currentUser,
                    badges: badges,
                    onOpenEvent: { eventID in
                        pendingEventID = eventID
                        selectedTab = 0
                    },
                    onOpenFriends: {
                        selectedTab = 1
                    }
                )
            }
            .badge(badges.unreadNotifications)

            Tab(String(localized: "Profile"), systemImage: "person.crop.circle.fill", value: 3) {
                if let user = session.currentUser {
                    ProfileScreen(api: environment.api, session: session, currentUser: user)
                }
            }
        }
        .tint(.indigo)
        .onChange(of: deepLinkRouter.pending) { _, newValue in
            guard let link = newValue else { return }
            handleSignedInDeepLink(link)
        }
        .task {
            if let link = deepLinkRouter.consume() {
                handleSignedInDeepLink(link)
            }
            if let destination = pushNavigationRouter.consume() {
                handlePushNavigation(destination)
            }
        }
        .onChange(of: pushNavigationRouter.pending) { _, newValue in
            guard let destination = newValue else { return }
            handlePushNavigation(destination)
        }
    }

    private func handlePushNavigation(_ destination: PushNavigationDestination) {
        switch destination {
        case let .events(eventID):
            pendingEventID = eventID
            selectedTab = 0
        case .friends:
            selectedTab = 1
        case .notifications:
            selectedTab = 2
        }
    }

    private func handleSignedInDeepLink(_ link: AppDeepLink) {
        switch link {
        case let .confirmAccount(token):
            Task { try? await session.confirmUser(token: token) }
        case .resetPassword:
            break
        }
    }
}
