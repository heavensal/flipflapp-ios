import Foundation

extension APIClient {
    func signIn(email: String, password: String) async throws -> AuthenticatedSession {
        let body = try encode(Envelope(user: UserCredentials(email: email, password: password)))
        let (user, response): (CurrentUser, HTTPURLResponse) = try await sendWithHTTPResponse(
            path: "api/v1/users/sign_in",
            method: .post,
            body: body,
            authenticated: false
        )

        guard
            let authorization = response.value(forHTTPHeaderField: "Authorization"),
            authorization.lowercased().hasPrefix("bearer ")
        else {
            throw APIError.incompatibleResponse
        }

        let token = authorization.dropFirst("Bearer ".count).trimmingCharacters(in: .whitespaces)
        guard !token.isEmpty else {
            throw APIError.incompatibleResponse
        }
        return AuthenticatedSession(user: user, token: token)
    }

    func signOut() async throws {
        try await sendEmpty(path: "api/v1/users/sign_out", method: .delete)
    }

    func register(_ input: RegistrationInput) async throws -> CurrentUser {
        let body = try encode(Envelope(user: input))
        return try await send(
            path: "api/v1/users",
            method: .post,
            body: body,
            authenticated: false
        )
    }

    func requestPasswordReset(email: String) async throws {
        let body = try encode(Envelope(user: EmailInput(email: email)))
        try await sendEmpty(
            path: "api/v1/users/password",
            method: .post,
            body: body,
            authenticated: false
        )
    }

    func resetPassword(_ input: PasswordResetInput) async throws {
        let body = try encode(Envelope(user: input))
        try await sendEmpty(
            path: "api/v1/users/password",
            method: .patch,
            body: body,
            authenticated: false
        )
    }

    func resetPasswordWithPut(_ input: PasswordResetInput) async throws {
        let body = try encode(Envelope(user: input))
        try await sendEmpty(
            path: "api/v1/users/password",
            method: .put,
            body: body,
            authenticated: false
        )
    }

    func resendConfirmation(email: String) async throws {
        let body = try encode(Envelope(user: EmailInput(email: email)))
        try await sendEmpty(
            path: "api/v1/users/confirmation",
            method: .post,
            body: body,
            authenticated: false
        )
    }

    func confirmUser(token: String) async throws -> AuthenticatedSession {
        let body = try encode(Envelope(user: ConfirmationInput(confirmationToken: token)))
        let (user, response): (CurrentUser, HTTPURLResponse) = try await sendWithHTTPResponse(
            path: "api/v1/users/confirmation",
            method: .patch,
            body: body,
            authenticated: false
        )

        guard
            let authorization = response.value(forHTTPHeaderField: "Authorization"),
            authorization.lowercased().hasPrefix("bearer ")
        else {
            throw APIError.incompatibleResponse
        }

        let jwt = authorization.dropFirst("Bearer ".count).trimmingCharacters(in: .whitespaces)
        guard !jwt.isEmpty else {
            throw APIError.incompatibleResponse
        }
        return AuthenticatedSession(user: user, token: jwt)
    }

    func currentUser() async throws -> CurrentUser {
        try await send(path: "api/v1/me", method: .get)
    }

    func updateCurrentUser(_ input: UserUpdateInput) async throws -> CurrentUser {
        let body = try encode(Envelope(user: input))
        return try await send(path: "api/v1/me", method: .patch, body: body)
    }

    func updateCurrentUserAvatar(_ avatar: AvatarUpload) async throws -> CurrentUser {
        var form = MultipartFormData()
        form.appendFile(
            name: "user[avatar]",
            filename: avatar.filename,
            mimeType: avatar.mimeType,
            data: avatar.data
        )
        form.finish()
        return try await send(
            path: "api/v1/me",
            method: .patch,
            body: form.body,
            contentType: form.contentType
        )
    }

    func removeCurrentUserAvatar() async throws -> CurrentUser {
        let body = try encode(Envelope(user: UserUpdateInput.removeAvatar))
        return try await send(path: "api/v1/me", method: .patch, body: body)
    }

    func user(id: UserID) async throws -> PublicUser {
        try await send(path: "api/v1/users/\(id.rawValue)", method: .get)
    }
}

nonisolated private struct EmailInput: Encodable, Sendable {
    let email: String
}

nonisolated private struct ConfirmationInput: Encodable, Sendable {
    let confirmationToken: String

    private enum CodingKeys: String, CodingKey {
        case confirmationToken = "confirmation_token"
    }
}
