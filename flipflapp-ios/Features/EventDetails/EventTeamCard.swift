import SwiftUI

struct EventTeamCard: View {
    enum Layout {
        case versus
        case full
    }

    let team: EventTeam
    let participants: [EventParticipant]
    let capacity: Int?
    let currentUserID: UserID
    let canRename: Bool
    let isMutating: Bool
    var layout: Layout = .full
    let join: () -> Void
    let rename: () -> Void

    private var tint: Color {
        switch team.slot {
        case .teamOne: .blue
        case .teamTwo: .orange
        case .bench: .secondary
        }
    }

    var body: some View {
        CardSurface(tint: team.slot == .bench ? nil : tint) {
            VStack(alignment: .leading, spacing: layout == .versus ? 10 : 14) {
                header

                if participants.isEmpty {
                    Text(String(localized: "No players yet"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    playersList
                }

                participationControl
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: team.slot.systemImage)
                .symbolRenderingMode(.palette)
                .foregroundStyle(tint, tint.opacity(0.35))
                .font(layout == .versus ? .title3 : .title2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(team.label)
                    .font(layout == .versus ? .subheadline.weight(.semibold) : .headline)
                    .lineLimit(layout == .versus ? 2 : 1)
                    .minimumScaleFactor(0.85)

                occupancyLabel
            }

            Spacer(minLength: 0)

            if canRename {
                Button(action: rename) {
                    Image(systemName: "pencil")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Rename \(team.label)"))
            }
        }
    }

    @ViewBuilder
    private var occupancyLabel: some View {
        if let capacity {
            Text("\(participants.count)/\(capacity)")
                .font(.subheadline.monospacedDigit().weight(.medium))
                .foregroundStyle(.secondary)
                .accessibilityLabel(
                    String(
                        localized: "\(participants.count) players out of \(capacity)"
                    )
                )
        } else {
            Text("\(participants.count)")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityLabel(String(localized: "\(participants.count) players"))
        }
    }

    private var playersList: some View {
        VStack(alignment: .leading, spacing: layout == .versus ? 8 : 10) {
            ForEach(participants) { participant in
                NavigationLink(value: participant.userID) {
                    if layout == .versus {
                        compactPlayerRow(participant)
                    } else {
                        UserRow(user: participant.user) {
                            if participant.userID == currentUserID {
                                youBadge
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func compactPlayerRow(_ participant: EventParticipant) -> some View {
        HStack(spacing: 8) {
            AvatarView(user: participant.user, size: 28)
            Text(participant.user.displayName)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Spacer(minLength: 0)
            if participant.userID == currentUserID {
                youBadge
            }
        }
        .contentShape(.rect)
    }

    private var youBadge: some View {
        Text(String(localized: "You"))
            .font(.caption.weight(.semibold))
            .foregroundStyle(team.slot == .bench ? Color.indigo : tint)
    }

    @ViewBuilder
    private var participationControl: some View {
        if participants.contains(where: { $0.userID == currentUserID }) {
            StatusPill(title: "Your position", systemImage: "checkmark.circle.fill", tint: .green)
        } else {
            Button(action: join) {
                Label(
                    team.slot == .bench
                        ? String(localized: "Join the bench")
                        : String(localized: "Choose this team"),
                    systemImage: "arrow.right.circle.fill"
                )
                .font(layout == .versus ? .caption.weight(.semibold) : .body)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(team.slot == .bench ? nil : tint)
            .disabled(isMutating)
        }
    }
}
