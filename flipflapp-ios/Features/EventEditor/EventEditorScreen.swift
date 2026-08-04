import SwiftUI

struct EventEditorScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: EventEditorModel

    let event: Event?
    let onSaved: () -> Void

    init(
        api: APIClient,
        session: SessionStore,
        event: Event?,
        onSaved: @escaping () -> Void
    ) {
        self.event = event
        self.onSaved = onSaved
        _model = State(initialValue: EventEditorModel(api: api, session: session, event: event))
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            Form {
                Section(String(localized: "Event")) {
                    TextField(String(localized: "Title"), text: $model.draft.title)
                    TextField(String(localized: "Description (optional)"), text: $model.draft.description, axis: .vertical)
                        .lineLimit(3...7)
                    LocationSearchField(
                        location: $model.draft.location,
                        latitude: $model.draft.latitude,
                        longitude: $model.draft.longitude
                    )
                }

                Section(String(localized: "Schedule")) {
                    DatePicker(
                        String(localized: "Kick-off"),
                        selection: $model.draft.startTime,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section(String(localized: "Players and price")) {
                    Stepper(value: $model.draft.numberOfParticipants, in: 1...100) {
                        LabeledContent(
                            String(localized: "Official capacity"),
                            value: "\(model.draft.numberOfParticipants)"
                        )
                    }
                    TextField(String(localized: "Price in euros"), text: $model.draft.price)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Toggle(String(localized: "Private event"), isOn: $model.draft.isPrivate)
                } footer: {
                    Text(String(localized: "The server decides who can view private events based on friendships, participation and invitations."))
                }

                if let errorMessage = model.errorMessage {
                    Section { InlineErrorView(message: errorMessage) }
                }
            }
            .navigationTitle(event == nil ? String(localized: "New event") : String(localized: "Edit event"))
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(model.isSubmitting)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                        .disabled(model.isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        Task {
                            guard await model.submit() != nil else { return }
                            onSaved()
                            dismiss()
                        }
                    }
                    .disabled(model.isSubmitting)
                }
            }
        }
    }
}
