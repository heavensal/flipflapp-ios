import SwiftUI

struct NotificationsScreen: View {
    let api: APIClient
    let session: SessionStore
    let currentUser: CurrentUser

    @State private var model: NotificationsModel
    @State private var path: [EventID] = []

    init(
        api: APIClient,
        session: SessionStore,
        currentUser: CurrentUser,
        badges: AppBadgeStore
    ) {
        self.api = api
        self.session = session
        self.currentUser = currentUser
        _model = State(initialValue: NotificationsModel(api: api, session: session, badges: badges))
    }

    var body: some View {
        NavigationStack(path: $path) {
            LoadStateView(
                state: model.state,
                emptyTitle: "No notifications",
                emptyDescription: "Event updates and invitations will appear here.",
                retry: { Task { await model.retry() } }
            ) { notifications in
                List {
                    ForEach(notifications) { notification in
                        Button {
                            Task {
                                if let eventID = await model.open(notification) {
                                    path.append(eventID)
                                }
                            }
                        } label: {
                            NotificationRow(notification: notification)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(String(localized: "Delete"), role: .destructive) {
                                Task { await model.delete(notification) }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await model.retry() }
            }
            .navigationTitle(String(localized: "Notifications"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(String(localized: "Mark all read")) {
                        Task { await model.markAllRead() }
                    }
                    .disabled(model.unreadCount == 0 || model.isMarkingAll)
                }
            }
            .navigationDestination(for: EventID.self) { eventID in
                EventDetailsScreen(
                    eventID: eventID,
                    api: api,
                    session: session,
                    currentUser: currentUser,
                    onChanged: {}
                )
            }
            .navigationDestination(for: UserID.self) { userID in
                UserProfileScreen(userID: userID, api: api, session: session)
            }
            .task { await model.load() }
            .alert(
                String(localized: "Action failed"),
                isPresented: Binding(
                    get: { model.actionErrorMessage != nil },
                    set: { if !$0 { model.actionErrorMessage = nil } }
                )
            ) {
                Button(String(localized: "OK"), role: .cancel) { model.actionErrorMessage = nil }
            } message: {
                Text(model.actionErrorMessage ?? "")
            }
        }
    }
}
