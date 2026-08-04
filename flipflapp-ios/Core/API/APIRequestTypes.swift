import Foundation

nonisolated enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case put = "PUT"
    case delete = "DELETE"
}

nonisolated struct EmptyRequestBody: Encodable, Sendable {}

nonisolated struct AuthenticatedSession: Sendable {
    let user: CurrentUser
    let token: String
}

nonisolated struct UserCredentials: Encodable, Sendable {
    let email: String
    let password: String
}

nonisolated struct RegistrationInput: Encodable, Sendable {
    let email: String
    let password: String
    let passwordConfirmation: String
    let firstName: String
    let lastName: String

    private enum CodingKeys: String, CodingKey {
        case email
        case password
        case passwordConfirmation = "password_confirmation"
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

nonisolated struct PasswordResetInput: Encodable, Sendable {
    let resetPasswordToken: String
    let password: String
    let passwordConfirmation: String

    private enum CodingKeys: String, CodingKey {
        case resetPasswordToken = "reset_password_token"
        case password
        case passwordConfirmation = "password_confirmation"
    }
}

nonisolated struct UserUpdateInput: Encodable, Sendable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let password: String?
    let passwordConfirmation: String?
    let removeAvatar: Bool?

    init(
        firstName: String? = nil,
        lastName: String? = nil,
        email: String? = nil,
        password: String? = nil,
        passwordConfirmation: String? = nil,
        removeAvatar: Bool? = nil
    ) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.password = password
        self.passwordConfirmation = passwordConfirmation
        self.removeAvatar = removeAvatar
    }

    static let removeAvatar = UserUpdateInput(removeAvatar: true)

    private enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case password
        case passwordConfirmation = "password_confirmation"
        case removeAvatar = "remove_avatar"
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(password, forKey: .password)
        try container.encodeIfPresent(passwordConfirmation, forKey: .passwordConfirmation)
        if removeAvatar == true {
            try container.encode(true, forKey: .removeAvatar)
        }
    }
}

nonisolated struct Envelope<Value: Encodable & Sendable>: Encodable, Sendable {
    let user: Value
}

nonisolated struct EventEnvelope: Encodable, Sendable {
    let event: EventInput
}

nonisolated struct EventTeamUpdateEnvelope: Encodable, Sendable {
    nonisolated struct Update: Encodable, Sendable {
        let label: String
    }

    let eventTeam: Update

    private enum CodingKeys: String, CodingKey {
        case eventTeam = "event_team"
    }
}

nonisolated struct EventParticipantEnvelope: Encodable, Sendable {
    nonisolated struct Input: Encodable, Sendable {
        let eventTeamID: EventTeamID

        private enum CodingKeys: String, CodingKey {
            case eventTeamID = "event_team_id"
        }
    }

    let eventParticipant: Input

    private enum CodingKeys: String, CodingKey {
        case eventParticipant = "event_participant"
    }
}

nonisolated struct InvitationInput: Encodable, Sendable {
    let userIDs: [UserID]

    private enum CodingKeys: String, CodingKey {
        case userIDs = "user_ids"
    }
}

nonisolated struct FriendshipCreateInput: Encodable, Sendable {
    let userID: UserID

    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
    }
}

nonisolated struct FriendshipUpdateInput: Encodable, Sendable {
    let status: Friendship.Status
}
