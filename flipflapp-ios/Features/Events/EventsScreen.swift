import SwiftUI

struct EventsScreen: View {
    let api: APIClient
    let session: SessionStore
    let currentUser: CurrentUser
    @Binding var pendingEventID: EventID?

    @State private var model: EventsListModel
    @State private var isPresentingEditor = false
    @State private var navigationPath: [EventID] = []

    init(
        api: APIClient,
        session: SessionStore,
        currentUser: CurrentUser,
        pendingEventID: Binding<EventID?>
    ) {
        self.api = api
        self.session = session
        self.currentUser = currentUser
        _pendingEventID = pendingEventID
        _model = State(initialValue: EventsListModel(api: api, session: session))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            LoadStateView(
                state: model.state,
                isRefreshing: model.isRefreshing,
                emptyTitle: "No upcoming events",
                emptyDescription: "Create an event and invite your friends to play.",
                retry: { Task { await model.retry() } }
            ) { events in
                ScrollView {
                    LazyVStack(spacing: 14) {
                        if let message = model.refreshErrorMessage {
                            InlineErrorView(message: message)
                                .padding(.horizontal)
                        }

                        ForEach(events) { event in
                            NavigationLink(value: event.id) {
                                EventCard(event: event)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(String(localized: "Opens event details"))
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
                .refreshable { await model.refresh() }
            } emptyActions: {
                Button(String(localized: "Create an event")) {
                    isPresentingEditor = true
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle(String(localized: "Events"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingEditor = true
                    } label: {
                        Label(String(localized: "Create an event"), systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: EventID.self) { eventID in
                EventDetailsScreen(
                    eventID: eventID,
                    api: api,
                    session: session,
                    currentUser: currentUser,
                    onChanged: { Task { await model.refresh() } }
                )
            }
            .navigationDestination(for: UserID.self) { userID in
                UserProfileScreen(
                    userID: userID,
                    api: api,
                    session: session,
                    currentUserID: currentUser.id
                )
            }
            .sheet(isPresented: $isPresentingEditor) {
                EventEditorScreen(api: api, session: session, event: nil) {
                    Task { await model.refresh() }
                }
            }
            .task { await model.load() }
            .onChange(of: pendingEventID) { _, newValue in
                guard let eventID = newValue else { return }
                navigationPath.append(eventID)
                pendingEventID = nil
            }
        }
    }
}
