import Foundation

nonisolated struct PublicUser: Codable, Hashable, Identifiable, Sendable {
    let id: UserID
    let firstName: String?
    let lastName: String?
    let username: String?
    let avatarURL: URL?

    var displayName: String {
        let name = [firstName, lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return name.isEmpty ? username ?? String(localized: "Player") : name
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case username
        case avatarURL = "avatar_url"
    }
}

nonisolated struct CurrentUser: Codable, Hashable, Identifiable, Sendable {
    nonisolated enum Role: String, Codable, Sendable {
        case player
        case admin
    }

    let id: UserID
    let email: String
    let unconfirmedEmail: String?
    let firstName: String?
    let lastName: String?
    let username: String?
    let avatarURL: URL?
    let role: Role

    var publicProfile: PublicUser {
        PublicUser(
            id: id,
            firstName: firstName,
            lastName: lastName,
            username: username,
            avatarURL: avatarURL
        )
    }

    var displayName: String {
        publicProfile.displayName
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case email
        case unconfirmedEmail = "unconfirmed_email"
        case firstName = "first_name"
        case lastName = "last_name"
        case username
        case avatarURL = "avatar_url"
        case role
    }
}
