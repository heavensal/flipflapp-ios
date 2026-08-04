import SwiftUI

struct EventDetailsScreen: View {
    @Environment(\.dismiss) private var dismiss

    let eventID: EventID
    let api: APIClient
    let session: SessionStore
    let currentUser: CurrentUser
    let onChanged: () -> Void

    @State private var model: EventDetailsModel
    @State private var eventToEdit: Event?
    @State private var teamToRename: EventTeam?
    @State private var isPresentingInvitations = false
    @State private var isConfirmingLeave = false
    @State private var isConfirmingDelete = false

    init(
        eventID: EventID,
        api: APIClient,
        session: SessionStore,
        currentUser: CurrentUser,
        onChanged: @escaping () -> Void
    ) {
        self.eventID = eventID
        self.api = api
        self.session = session
        self.currentUser = currentUser
        self.onChanged = onChanged
        _model = State(
            initialValue: EventDetailsModel(
                eventID: eventID,
                api: api,
                session: session,
                currentUserID: currentUser.id
            )
        )
    }

    var body: some View {
        LoadStateView(
            state: model.state,
            isRefreshing: model.isRefreshing,
            emptyTitle: "Event unavailable",
            emptyDescription: "This event has no content to display.",
            retry: { Task { await model.reload() } }
        ) { snapshot in
            detailsList(snapshot)
        }
        .navigationTitle(String(localized: "Event details"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .task { await model.load() }
        .refreshable { await model.reload() }
        .sheet(item: $eventToEdit) { event in
            EventEditorScreen(api: api, session: session, event: event) {
                onChanged()
                Task { await model.reload() }
            }
        }
        .sheet(item: $teamToRename) { team in
            RenameTeamSheet(team: team) { label in
                let renamed = await model.rename(teamID: team.id, label: label)
                if renamed { onChanged() }
                return renamed
            }
        }
        .sheet(isPresented: $isPresentingInvitations) {
            if case let .loaded(snapshot) = model.state {
                InvitationPickerSheet(
                    eventID: eventID,
                    api: api,
                    session: session,
                    currentUserID: currentUser.id,
                    participants: snapshot.participants,
                    invitations: snapshot.invitations
                ) { invitations in
                    model.replaceInvitations(invitations)
                }
            }
        }
        .confirmationDialog(
            String(localized: "Leave this event?"),
            isPresented: $isConfirmingLeave,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Leave event"), role: .destructive) {
                Task {
                    if await model.leave() {
                        onChanged()
                        dismiss()
                    }
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "Your participation will be removed. You may lose access to a private event."))
        }
        .confirmationDialog(
            String(localized: "Delete this event?"),
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete event"), role: .destructive) {
                Task {
                    if await model.deleteEvent() {
                        onChanged()
                        dismiss()
                    }
                }
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "The event, its participation and pending invitations will be permanently removed."))
        }
        .alert(
            String(localized: "Action failed"),
            isPresented: Binding(
                get: { model.actionErrorMessage != nil },
                set: { if !$0 { model.clearActionError() } }
            )
        ) {
            Button(String(localized: "OK"), role: .cancel) { model.clearActionError() }
        } message: {
            Text(model.actionErrorMessage ?? String(localized: "Try again."))
        }
    }

    private func detailsList(_ snapshot: EventDetailsSnapshot) -> some View {
        List {
            Section {
                EventHeroCard(event: snapshot.event)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            Section {
                EventRouteMapView(
                    latitude: snapshot.event.latitude,
                    longitude: snapshot.event.longitude,
                    title: snapshot.event.location
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            } header: {
                Text(String(localized: "Getting there"))
            } footer: {
                Text(snapshot.event.location)
            }

            Section(String(localized: "Teams")) {
                EventTeamsVersusSection(
                    event: snapshot.event,
                    teams: snapshot.teams,
                    participants: snapshot.participants(in:),
                    currentUserID: currentUser.id,
                    canRenameCountableTeams: snapshot.event.currentUser?.participant == true,
                    isMutating: model.isMutating,
                    join: { teamID in
                        Task { await model.join(teamID: teamID); onChanged() }
                    },
                    rename: { team in teamToRename = team }
                )
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if !snapshot.invitations.isEmpty {
                Section(String(localized: "Invited")) {
                    ForEach(snapshot.invitations) { invitation in
                        NavigationLink(value: invitation.userID) {
                            UserRow(user: invitation.user)
                        }
                    }
                }
            }

            if snapshot.event.currentUser?.participant == true {
                Section {
                    if snapshot.event.currentUser?.canInvite == true {
                        Button {
                            isPresentingInvitations = true
                        } label: {
                            Label(String(localized: "Invite friends"), systemImage: "person.crop.circle.badge.plus")
                        }
                    }

                    Button(role: .destructive) {
                        isConfirmingLeave = true
                    } label: {
                        Label(String(localized: "Leave event"), systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } header: {
                    Text(String(localized: "Participation"))
                }
            }

            if snapshot.event.currentUser?.author == true {
                Section(String(localized: "Organizer controls")) {
                    Button {
                        eventToEdit = snapshot.event
                    } label: {
                        Label(String(localized: "Edit event"), systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label(String(localized: "Delete event"), systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if case let .loaded(snapshot) = model.state, snapshot.event.currentUser?.author == true {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    eventToEdit = snapshot.event
                } label: {
                    Label(String(localized: "Edit event"), systemImage: "pencil")
                }
            }
        }
    }
}
