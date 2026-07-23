import Foundation

extension APIClient {
    func events() async throws -> [Event] {
        try await send(path: "api/v1/events", method: .get)
    }

    func event(id: EventID) async throws -> Event {
        try await send(path: "api/v1/events/\(id.rawValue)", method: .get)
    }

    func createEvent(_ input: EventInput) async throws -> Event {
        let body = try encode(EventEnvelope(event: input))
        return try await send(path: "api/v1/events", method: .post, body: body)
    }

    func updateEvent(id: EventID, input: EventInput) async throws -> Event {
        let body = try encode(EventEnvelope(event: input))
        return try await send(path: "api/v1/events/\(id.rawValue)", method: .patch, body: body)
    }

    func deleteEvent(id: EventID) async throws {
        try await sendEmpty(path: "api/v1/events/\(id.rawValue)", method: .delete)
    }

    func eventTeams(eventID: EventID) async throws -> [EventTeam] {
        try await send(path: "api/v1/events/\(eventID.rawValue)/event_teams", method: .get)
    }

    func eventTeam(eventID: EventID, teamID: EventTeamID) async throws -> EventTeam {
        try await send(
            path: "api/v1/events/\(eventID.rawValue)/event_teams/\(teamID.rawValue)",
            method: .get
        )
    }

    func renameEventTeam(eventID: EventID, teamID: EventTeamID, label: String) async throws -> EventTeam {
        let body = try encode(EventTeamUpdateEnvelope(eventTeam: .init(label: label)))
        return try await send(
            path: "api/v1/events/\(eventID.rawValue)/event_teams/\(teamID.rawValue)",
            method: .patch,
            body: body
        )
    }

    func eventParticipants(eventID: EventID) async throws -> [EventParticipant] {
        try await send(path: "api/v1/events/\(eventID.rawValue)/event_participants", method: .get)
    }

    func eventTeamParticipants(eventID: EventID, teamID: EventTeamID) async throws -> [EventParticipant] {
        try await send(
            path: "api/v1/events/\(eventID.rawValue)/event_teams/\(teamID.rawValue)/event_participants",
            method: .get
        )
    }

    func joinEvent(eventID: EventID, teamID: EventTeamID) async throws -> EventParticipant {
        let envelope = EventParticipantEnvelope(eventParticipant: .init(eventTeamID: teamID))
        let body = try encode(envelope)
        return try await send(
            path: "api/v1/events/\(eventID.rawValue)/event_participants",
            method: .post,
            body: body
        )
    }

    func leaveEvent(participantID: EventParticipantID) async throws {
        try await sendEmpty(
            path: "api/v1/event_participants/\(participantID.rawValue)",
            method: .delete
        )
    }

    func invitations(eventID: EventID) async throws -> [Invitation] {
        try await send(path: "api/v1/events/\(eventID.rawValue)/invitations", method: .get)
    }

    func createInvitations(eventID: EventID, userIDs: [UserID]) async throws -> [Invitation] {
        let body = try encode(InvitationInput(userIDs: userIDs))
        return try await send(
            path: "api/v1/events/\(eventID.rawValue)/invitations",
            method: .post,
            body: body
        )
    }
}
