import Foundation

nonisolated struct Friendship: Codable, Hashable, Identifiable, Sendable {
    nonisolated enum Status: String, Codable, Sendable {
        case pending
        case accepted
        case declined
    }

    let id: FriendshipID
    let senderID: UserID
    let receiverID: UserID
    let status: Status
    let createdAt: Date
    let updatedAt: Date
    let sender: PublicUser
    let receiver: PublicUser

    func otherUser(relativeTo userID: UserID) -> PublicUser {
        senderID == userID ? receiver : sender
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case senderID = "sender_id"
        case receiverID = "receiver_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case sender
        case receiver
    }
}

nonisolated struct FriendshipBuckets: Codable, Hashable, Sendable {
    let accepted: [Friendship]
    let sent: [Friendship]
    let received: [Friendship]
    let declined: [Friendship]

    static let empty = FriendshipBuckets(
        accepted: [],
        sent: [],
        received: [],
        declined: []
    )
}
