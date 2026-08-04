import SwiftUI

struct UserProfileScreen: View {
    @State private var model: UserProfileModel

    init(userID: UserID, api: APIClient, session: SessionStore, currentUserID: UserID) {
        _model = State(
            initialValue: UserProfileModel(
                userID: userID,
                api: api,
                session: session,
                currentUserID: currentUserID
            )
        )
    }

    var body: some View {
        LoadStateView(
            state: model.state,
            emptyTitle: "Player unavailable",
            emptyDescription: "This profile cannot be displayed.",
            retry: { Task { await model.retry() } }
        ) { user in
            ScrollView {
                CardSurface {
                    VStack(spacing: 16) {
                        AvatarView(user: user, size: 88)
                        Text(user.displayName)
                            .font(.title2.bold())
                        if let username = user.username {
                            Text(username)
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }

                        friendshipAction
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle(String(localized: "Player profile"))
        .navigationBarTitleDisplayMode(.inline)
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

    @ViewBuilder
    private var friendshipAction: some View {
        switch model.friendshipState {
        case .loading:
            ProgressView()
        case .canSend:
            Button {
                Task { _ = await model.sendFriendRequest() }
            } label: {
                if model.isSending {
                    ProgressView()
                } else {
                    Label(String(localized: "Add friend"), systemImage: "person.badge.plus")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isSending)
        case .pendingSent:
            StatusPill(title: "Request sent", systemImage: "paperplane.fill", tint: .orange)
        case .pendingReceived:
            StatusPill(title: "Respond in Friends", systemImage: "person.2.fill", tint: .indigo)
        case .friends:
            StatusPill(title: "Friends", systemImage: "checkmark.circle.fill", tint: .green)
        case .unavailable:
            EmptyView()
        }
    }
}
