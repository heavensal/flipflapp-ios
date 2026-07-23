import SwiftUI

struct RenameTeamSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var label: String

    let team: EventTeam
    let submit: (String) async -> Bool

    init(team: EventTeam, submit: @escaping (String) async -> Bool) {
        self.team = team
        self.submit = submit
        _label = State(initialValue: team.label)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(String(localized: "Team name"), text: $label)
                        .textInputAutocapitalization(.words)
                } footer: {
                    Text(String(localized: "Use a short name of 24 characters or fewer."))
                }
            }
            .navigationTitle(String(localized: "Rename team"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        Task {
                            if await submit(label) { dismiss() }
                        }
                    }
                    .disabled(label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || label.count > 24)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
