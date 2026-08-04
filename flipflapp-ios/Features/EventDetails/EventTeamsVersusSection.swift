import SwiftUI

struct EventTeamsVersusSection: View {
    let event: Event
    let teams: [EventTeam]
    let participants: (EventTeamID) -> [EventParticipant]
    let currentUserID: UserID
    let canRenameCountableTeams: Bool
    let mutatingTeamID: EventTeamID?
    let join: (EventTeamID) -> Void
    let rename: (EventTeam) -> Void

    private var playingTeams: [EventTeam] {
        teams.filter { $0.slot == .teamOne || $0.slot == .teamTwo }
            .sorted { lhs, rhs in
                slotOrder(lhs.slot) < slotOrder(rhs.slot)
            }
    }

    private var benchTeam: EventTeam? {
        teams.first { $0.slot == .bench }
    }

    var body: some View {
        VStack(spacing: 12) {
            if playingTeams.count == 2 {
                versusGrid(teamOne: playingTeams[0], teamTwo: playingTeams[1])
            } else {
                ForEach(playingTeams) { team in
                    teamCard(for: team, layout: .full)
                }
            }

            if let benchTeam {
                teamCard(for: benchTeam, layout: .full)
            }
        }
    }

    private func versusGrid(teamOne: EventTeam, teamTwo: EventTeam) -> some View {
        HStack(alignment: .top, spacing: 8) {
            teamCard(for: teamOne, layout: .versus)
                .frame(maxWidth: .infinity)

            Text(String(localized: "VS"))
                .font(.caption.weight(.heavy))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())
                .accessibilityLabel(String(localized: "Versus"))
                .padding(.top, 28)

            teamCard(for: teamTwo, layout: .versus)
                .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .contain)
    }

    private func teamCard(for team: EventTeam, layout: EventTeamCard.Layout) -> some View {
        EventTeamCard(
            team: team,
            participants: participants(team.id),
            capacity: event.officialCapacity(for: team.slot),
            currentUserID: currentUserID,
            event: event,
            canRename: team.countable && canRenameCountableTeams,
            isMutating: mutatingTeamID == team.id,
            layout: layout,
            join: { join(team.id) },
            rename: { rename(team) }
        )
    }

    private func slotOrder(_ slot: EventTeam.Slot) -> Int {
        switch slot {
        case .teamOne: 0
        case .teamTwo: 1
        case .bench: 2
        }
    }
}
