import Foundation

nonisolated struct EventParticipant: Codable, Hashable, Identifiable, Sendable {
    let id: EventParticipantID
    let eventID: EventID
    let eventTeamID: EventTeamID
    let userID: UserID
    let createdAt: Date
    let updatedAt: Date
    let user: PublicUser

    private enum CodingKeys: String, CodingKey {
        case id
        case eventID = "event_id"
        case eventTeamID = "event_team_id"
        case userID = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
    }
}
