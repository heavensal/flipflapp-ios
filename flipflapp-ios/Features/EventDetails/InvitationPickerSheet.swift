import SwiftUI

struct InvitationPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: InvitationPickerModel

    let onInvited: ([Invitation]) -> Void

    init(
        eventID: EventID,
        api: APIClient,
        session: SessionStore,
        currentUserID: UserID,
        participants: [EventParticipant],
        invitations: [Invitation],
        onInvited: @escaping ([Invitation]) -> Void
    ) {
        _model = State(
            initialValue: InvitationPickerModel(
                eventID: eventID,
                api: api,
                session: session,
                currentUserID: currentUserID,
                participants: participants,
                invitations: invitations
            )
        )
        self.onInvited = onInvited
    }

    var body: some View {
        NavigationStack {
            LoadStateView(
                state: model.state,
                emptyTitle: "Nobody to invite",
                emptyDescription: "All eligible friends are already participating or invited.",
                retry: { Task { await model.load() } }
            ) { users in
                List(users) { user in
                    Button {
                        if model.selection.contains(user.id) {
                            model.selection.remove(user.id)
                        } else {
                            model.selection.insert(user.id)
                        }
                    } label: {
                        UserRow(user: user) {
                            Image(systemName: model.selection.contains(user.id) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(model.selection.contains(user.id) ? .indigo : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(model.selection.contains(user.id) ? String(localized: "Selected") : String(localized: "Not selected"))
                }
            }
            .navigationTitle(String(localized: "Invite friends"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Invite")) {
                        Task {
                            guard let invitations = await model.submit() else { return }
                            onInvited(invitations)
                            dismiss()
                        }
                    }
                    .disabled(model.selection.isEmpty || model.isSubmitting)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let errorMessage = model.errorMessage {
                    InlineErrorView(message: errorMessage)
                        .padding()
                        .background(.bar)
                }
            }
            .task { await model.load() }
        }
    }
}
