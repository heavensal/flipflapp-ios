import Foundation

extension APIClient {
    func friendships() async throws -> FriendshipBuckets {
        try await send(path: "api/v1/friendships", method: .get)
    }

    func createFriendship(userID: UserID) async throws -> Friendship {
        let body = try encode(FriendshipCreateInput(userID: userID))
        return try await send(path: "api/v1/friendships", method: .post, body: body)
    }

    func searchFriendshipCandidates(query: String) async throws -> [PublicUser] {
        let item = URLQueryItem(
            name: "q[first_name_or_last_name_or_username_cont]",
            value: query
        )
        return try await send(
            path: "api/v1/friendships/search",
            method: .get,
            queryItems: [item]
        )
    }

    func updateFriendship(id: FriendshipID, status: Friendship.Status) async throws -> Friendship {
        let body = try encode(FriendshipUpdateInput(status: status))
        return try await send(
            path: "api/v1/friendships/\(id.rawValue)",
            method: .patch,
            body: body
        )
    }

    func deleteFriendship(id: FriendshipID) async throws {
        try await sendEmpty(path: "api/v1/friendships/\(id.rawValue)", method: .delete)
    }
}
