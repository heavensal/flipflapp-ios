import SwiftUI

struct FriendsSearchScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: FriendsSearchModel

    let onChanged: () -> Void

    init(api: APIClient, session: SessionStore, onChanged: @escaping () -> Void) {
        _model = State(initialValue: FriendsSearchModel(api: api, session: session))
        self.onChanged = onChanged
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            LoadStateView(
                state: model.state,
                emptyTitle: model.query.isEmpty ? "Find a player" : "No matching players",
                emptyDescription: "Search uses first name, last name and username — never email.",
                retry: { Task { await model.search() } }
            ) { users in
                List(users) { user in
                    UserRow(user: user) {
                        Button {
                            Task {
                                if await model.sendRequest(to: user) { onChanged() }
                            }
                        } label: {
                            if model.sendingUserID == user.id {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "person.badge.plus")
                                    .frame(width: 44, height: 44)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(model.sendingUserID != nil)
                        .accessibilityLabel(String(localized: "Send a friend request to \(user.displayName)"))
                    }
                }
            }
            .navigationTitle(String(localized: "Find players"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $model.query, prompt: String(localized: "Name or username"))
            .task(id: model.query) { await model.search() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
            .alert(
                String(localized: "Request not sent"),
                isPresented: Binding(
                    get: { model.errorMessage != nil },
                    set: { if !$0 { model.errorMessage = nil } }
                )
            ) {
                Button(String(localized: "OK"), role: .cancel) { model.errorMessage = nil }
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }
}
