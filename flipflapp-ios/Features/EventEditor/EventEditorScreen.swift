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
                }

                Section {
                    TextField(
                        String(localized: "Location"),
                        text: Binding(
                            get: { model.draft.location },
                            set: { model.locationTextChanged($0) }
                        ),
                        axis: .vertical
                    )
                    .textContentType(.fullStreetAddress)
                    .lineLimit(2...4)
                    .disabled(model.addressAutocomplete.isResolving)

                    if model.addressAutocomplete.isResolving {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(String(localized: "Looking up address…"))
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }

                    ForEach(model.addressAutocomplete.suggestions) { suggestion in
                        Button {
                            model.selectSuggestion(suggestion)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title)
                                    .foregroundStyle(.primary)
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(accessibilityLabel(for: suggestion))
                    }

                    if model.draft.hasResolvedCoordinates {
                        Label(String(localized: "Address selected"), systemImage: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(String(localized: "Address selected"))

                        if let latitude = parseDraftCoordinate(model.draft.latitude),
                           let longitude = parseDraftCoordinate(model.draft.longitude) {
                            EventLocationPreviewMap(
                                latitude: latitude,
                                longitude: longitude,
                                title: model.draft.location
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 4, trailing: 0))
                        }
                    }
                } header: {
                    Text(String(localized: "Location"))
                } footer: {
                    Text(locationFooterText)
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

                if let errorMessage = model.errorMessage ?? model.addressAutocomplete.resolveErrorMessage {
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
                    .disabled(model.isSubmitting || model.addressAutocomplete.isResolving)
                }
            }
        }
    }

    private var locationFooterText: String {
        if model.draft.hasResolvedCoordinates {
            String(localized: "Coordinates are filled automatically from the selected address.")
        } else {
            String(localized: "Start typing, then choose an address from the suggestions.")
        }
    }

    private func accessibilityLabel(for suggestion: AddressSuggestion) -> String {
        if suggestion.subtitle.isEmpty {
            return suggestion.title
        }
        return "\(suggestion.title), \(suggestion.subtitle)"
    }

    private func parseDraftCoordinate(_ value: String) -> Decimal? {
        Decimal(string: value, locale: .current)
            ?? Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))
    }
}
