import Foundation

nonisolated struct EventViewerContext: Codable, Hashable, Sendable {
    let participant: Bool
    let canInvite: Bool
    let author: Bool
    let invited: Bool

    private enum CodingKeys: String, CodingKey {
        case participant
        case canInvite = "can_invite"
        case author
        case invited
    }
}

nonisolated struct Event: Codable, Hashable, Identifiable, Sendable {
    nonisolated enum FillLevel: String, Codable, Sendable {
        case open
        case tight
        case full
    }

    let id: EventID
    let title: String
    let description: String?
    let location: String
    let startTime: Date
    let numberOfParticipants: Int
    @StringEncodedDecimal var price: Decimal
    let isPrivate: Bool
    @StringEncodedDecimal var latitude: Decimal
    @StringEncodedDecimal var longitude: Decimal
    let userID: UserID
    let createdAt: Date
    let updatedAt: Date
    let participantsCount: Int
    let spotsRemaining: Int
    let fillLevel: FillLevel
    let user: PublicUser
    let currentUser: EventViewerContext?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case location
        case startTime = "start_time"
        case numberOfParticipants = "number_of_participants"
        case price
        case isPrivate = "is_private"
        case latitude
        case longitude
        case userID = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case participantsCount = "participants_count"
        case spotsRemaining = "spots_remaining"
        case fillLevel = "fill_level"
        case user
        case currentUser = "current_user"
    }

    /// Official per-team capacity for countable slots, matching Rails `countable_slots_for`.
    func officialCapacity(for slot: EventTeam.Slot) -> Int? {
        switch slot {
        case .teamOne:
            numberOfParticipants / 2
        case .teamTwo:
            (numberOfParticipants + 1) / 2
        case .bench:
            nil
        }
    }
}

nonisolated struct EventInput: Encodable, Sendable {
    let title: String
    let description: String?
    let location: String
    let startTime: Date
    let numberOfParticipants: Int
    let price: Decimal
    let isPrivate: Bool
    let latitude: Decimal
    let longitude: Decimal

    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case location
        case startTime = "start_time"
        case numberOfParticipants = "number_of_participants"
        case price
        case isPrivate = "is_private"
        case latitude
        case longitude
    }
}
