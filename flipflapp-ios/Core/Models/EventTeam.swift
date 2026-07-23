import Foundation

nonisolated struct EventTeam: Codable, Hashable, Identifiable, Sendable {
    nonisolated enum Slot: String, Codable, CaseIterable, Sendable {
        case teamOne = "team_one"
        case teamTwo = "team_two"
        case bench

        var systemImage: String {
            switch self {
            case .teamOne: "shield.lefthalf.filled"
            case .teamTwo: "shield.righthalf.filled"
            case .bench: "chair.lounge.fill"
            }
        }
    }

    let id: EventTeamID
    let eventID: EventID
    let slot: Slot
    let label: String
    let createdAt: Date
    let updatedAt: Date
    let countable: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case eventID = "event_id"
        case slot
        case label
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case countable
    }
}
