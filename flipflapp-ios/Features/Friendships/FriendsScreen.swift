import SwiftUI

struct FriendsScreen: View {
    let api: APIClient
    let session: SessionStore
    let currentUser: CurrentUser

    @State private var model: FriendsModel
    @State private var isPresentingSearch = false

    init(
        api: APIClient,
        session: SessionStore,
        currentUser: CurrentUser,
        badges: AppBadgeStore
    ) {
        self.api = api
        self.session = session
        self.currentUser = currentUser
        _model = State(initialValue: FriendsModel(api: api, session: session, badges: badges))
    }

    var body: some View {
        NavigationStack {
            LoadStateView(
                state: model.state,
                isRefreshing: model.isRefreshing,
                emptyTitle: "No friendships yet",
                emptyDescription: "Search by first name, last name or username to connect with players.",
                retry: { Task { await model.retry() } }
            ) { buckets in
                friendshipList(buckets)
            } emptyActions: {
                Button(String(localized: "Find players")) { isPresentingSearch = true }
                    .buttonStyle(.borderedProminent)
            }
            .navigationTitle(String(localized: "Friends"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingSearch = true
                    } label: {
                        Label(String(localized: "Find players"), systemImage: "person.badge.plus")
                    }
                }
            }
            .navigationDestination(for: UserID.self) { userID in
                UserProfileScreen(
                    userID: userID,
                    api: api,
                    session: session,
                    currentUserID: currentUser.id
                )
            }
            .sheet(isPresented: $isPresentingSearch) {
                FriendsSearchScreen(api: api, session: session) {
                    Task { await model.retry() }
                }
            }
            .task { await model.load() }
            .refreshable { await model.retry() }
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

    private func friendshipList(_ buckets: FriendshipBuckets) -> some View {
        List {
            if !buckets.received.isEmpty {
                Section(String(localized: "Requests received")) {
                    ForEach(buckets.received) { friendship in
                        FriendshipRow(
                            friendship: friendship,
                            currentUserID: currentUser.id,
                            isWorking: model.mutatingFriendshipID == friendship.id,
                            primaryAction: { Task { await model.accept(friendship) } },
                            secondaryAction: { Task { await model.decline(friendship) } },
                            primaryTitle: "Accept",
                            secondaryTitle: "Decline"
                        )
                    }
                }
            }

            if !buckets.accepted.isEmpty {
                Section(String(localized: "Friends")) {
                    ForEach(buckets.accepted) { friendship in
                        FriendshipRow(
                            friendship: friendship,
                            currentUserID: currentUser.id,
                            isWorking: model.mutatingFriendshipID == friendship.id,
                            primaryAction: nil,
                            secondaryAction: nil,
                            primaryTitle: nil,
                            secondaryTitle: nil
                        )
                        .swipeActions {
                            Button(String(localized: "Unfriend"), role: .destructive) {
                                Task { await model.delete(friendship) }
                            }
                        }
                    }
                }
            }

            if !buckets.sent.isEmpty {
                Section(String(localized: "Requests sent")) {
                    ForEach(buckets.sent) { friendship in
                        FriendshipRow(
                            friendship: friendship,
                            currentUserID: currentUser.id,
                            isWorking: model.mutatingFriendshipID == friendship.id,
                            primaryAction: nil,
                            secondaryAction: { Task { await model.delete(friendship) } },
                            primaryTitle: nil,
                            secondaryTitle: "Cancel request"
                        )
                    }
                }
            }

            if !buckets.declined.isEmpty {
                Section {
                    ForEach(buckets.declined) { friendship in
                        FriendshipRow(
                            friendship: friendship,
                            currentUserID: currentUser.id,
                            isWorking: model.mutatingFriendshipID == friendship.id,
                            primaryAction: nil,
                            secondaryAction: { Task { await model.delete(friendship) } },
                            primaryTitle: nil,
                            secondaryTitle: "Remove"
                        )
                    }
                } header: {
                    Text(String(localized: "Declined requests"))
                } footer: {
                    Text(String(localized: "Removing a declined request lets either player send a new request later."))
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
