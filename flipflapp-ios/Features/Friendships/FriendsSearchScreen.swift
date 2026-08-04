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
            Group {
                if model.query.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
                    ContentUnavailableView {
                        Label(String(localized: "Find a player"), systemImage: "person.badge.plus")
                    } description: {
                        Text(String(localized: "Search uses first name, last name and username — never email."))
                    }
                } else if model.results.isEmpty, !model.isSearching {
                    ContentUnavailableView {
                        Label(String(localized: "No matching players"), systemImage: "person.slash")
                    } description: {
                        Text(String(localized: "Try another name or username."))
                    }
                } else {
                    List(model.results) { user in
                        UserRow(user: user) {
                            Button {
                                Task {
                                    if await model.sendRequest(to: user) { onChanged() }
                                }
                            } label: {
                                if model.sendingUserID == user.id {
                                    ProgressView().controlSize(.small)
                                } else if model.sentUserIDs.contains(user.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .frame(width: 44, height: 44)
                                } else {
                                    Image(systemName: "person.badge.plus")
                                        .frame(width: 44, height: 44)
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(model.sendingUserID == user.id)
                            .accessibilityLabel(String(localized: "Send a friend request to \(user.displayName)"))
                        }
                    }
                }
            }
            .overlay(alignment: .top) {
                if model.isSearching {
                    ProgressView()
                        .padding(8)
                        .background(.bar, in: Capsule())
                        .padding(.top, 8)
                }
            }
            .navigationTitle(String(localized: "Find players"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $model.query, prompt: String(localized: "Name or username"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let errorMessage = model.errorMessage {
                    InlineErrorView(message: errorMessage)
                        .padding()
                        .background(.bar)
                }
            }
            .alert(
                String(localized: "Request not sent"),
                isPresented: Binding(
                    get: { model.errorMessage != nil && !model.results.isEmpty },
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
