import Foundation

nonisolated struct ResourceID<Resource>: Codable, Hashable, RawRepresentable, Sendable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(Int.self)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

nonisolated enum UserResource: Sendable {}
nonisolated enum EventResource: Sendable {}
nonisolated enum EventTeamResource: Sendable {}
nonisolated enum EventParticipantResource: Sendable {}
nonisolated enum InvitationResource: Sendable {}
nonisolated enum FriendshipResource: Sendable {}
nonisolated enum NotificationResource: Sendable {}

typealias UserID = ResourceID<UserResource>
typealias EventID = ResourceID<EventResource>
typealias EventTeamID = ResourceID<EventTeamResource>
typealias EventParticipantID = ResourceID<EventParticipantResource>
typealias InvitationID = ResourceID<InvitationResource>
typealias FriendshipID = ResourceID<FriendshipResource>
typealias NotificationID = ResourceID<NotificationResource>
