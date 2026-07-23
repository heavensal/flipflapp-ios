import Foundation

nonisolated struct Invitation: Codable, Hashable, Identifiable, Sendable {
    let id: InvitationID
    let eventID: EventID
    let userID: UserID
    let createdAt: Date
    let updatedAt: Date
    let user: PublicUser

    private enum CodingKeys: String, CodingKey {
        case id
        case eventID = "event_id"
        case userID = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
    }
}
