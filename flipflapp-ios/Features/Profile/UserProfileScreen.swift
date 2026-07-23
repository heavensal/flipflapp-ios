import SwiftUI

struct UserProfileScreen: View {
    @State private var model: UserProfileModel

    init(userID: UserID, api: APIClient, session: SessionStore) {
        _model = State(initialValue: UserProfileModel(userID: userID, api: api, session: session))
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
    }
}
