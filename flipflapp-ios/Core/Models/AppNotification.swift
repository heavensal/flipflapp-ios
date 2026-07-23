import Foundation

nonisolated struct AppNotification: Codable, Hashable, Identifiable, Sendable {
    nonisolated enum Kind: String, Codable, Sendable {
        case updated
        case canceled
        case reminder
        case joined
        case left
        case invited
        case friendshipRequested = "friendship_requested"
        case unknown

        init(from decoder: any Decoder) throws {
            let value = try decoder.singleValueContainer().decode(String.self)
            self = Kind(rawValue: value) ?? .unknown
        }
    }

    let id: NotificationID
    let userID: UserID
    let kind: Kind
    let read: Bool
    let payload: [String: JSONValue]
    let notifiableType: String?
    let notifiableID: Int?
    let createdAt: Date
    let updatedAt: Date

    var linkedEventID: EventID? {
        guard notifiableType == "Event", let notifiableID else { return nil }
        return EventID(rawValue: notifiableID)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case kind
        case read
        case payload
        case notifiableType = "notifiable_type"
        case notifiableID = "notifiable_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
