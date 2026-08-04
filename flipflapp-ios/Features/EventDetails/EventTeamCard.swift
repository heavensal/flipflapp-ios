import SwiftUI

struct EventTeamCard: View {
    let team: EventTeam
    let participants: [EventParticipant]
    let currentUserID: UserID
    let event: Event
    let canRename: Bool
    let isMutatingThisTeam: Bool
    let join: () -> Void
    let rename: () -> Void

    private var isJoinDisabled: Bool {
        guard !isMutatingThisTeam else { return true }
        guard team.countable else { return false }
        let teamCapacity = team.slot == .teamOne
            ? event.numberOfParticipants / 2
            : (event.numberOfParticipants + 1) / 2
        return participants.count >= teamCapacity || event.fillLevel == .full
    }

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(team.label, systemImage: team.slot.systemImage)
                        .font(.headline)
                    Spacer()
                    Text("\(participants.count)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(String(localized: "\(participants.count) players"))
                    if canRename {
                        Button(action: rename) {
                            Image(systemName: "pencil")
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(localized: "Rename \(team.label)"))
                    }
                }

                if participants.isEmpty {
                    Text(String(localized: "No players yet"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 10) {
                        ForEach(participants) { participant in
                            NavigationLink(value: participant.userID) {
                                UserRow(user: participant.user) {
                                    if participant.userID == currentUserID {
                                        Text(String(localized: "You"))
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.indigo)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if participants.contains(where: { $0.userID == currentUserID }) {
                    StatusPill(title: "Your position", systemImage: "checkmark.circle.fill", tint: .green)
                } else {
                    Button(action: join) {
                        if isMutatingThisTeam {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label(
                                team.slot == .bench ? String(localized: "Join the bench") : String(localized: "Choose this team"),
                                systemImage: "arrow.right.circle.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isJoinDisabled)
                }
            }
        }
    }
}
