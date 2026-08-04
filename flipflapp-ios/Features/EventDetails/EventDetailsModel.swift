import Foundation
import Observation

struct EventDetailsSnapshot {
    var event: Event
    var teams: [EventTeam]
    var participants: [EventParticipant]
    var invitations: [Invitation]

    func participation(for userID: UserID) -> EventParticipant? {
        participants.first { $0.userID == userID }
    }

    func participants(in teamID: EventTeamID) -> [EventParticipant] {
        participants.filter { $0.eventTeamID == teamID }
    }
}

@MainActor
@Observable
final class EventDetailsModel {
    private(set) var state: LoadState<EventDetailsSnapshot> = .idle
    private(set) var isRefreshing = false
    private(set) var mutatingTeamID: EventTeamID?
    var actionErrorMessage: String?

    private let eventID: EventID
    private let api: APIClient
    private let session: SessionStore
    private let currentUserID: UserID

    init(eventID: EventID, api: APIClient, session: SessionStore, currentUserID: UserID) {
        self.eventID = eventID
        self.api = api
        self.session = session
        self.currentUserID = currentUserID
    }

    func load() async {
        guard case .idle = state else { return }
        await reload()
    }

    func reload() async {
        if state.hasContent {
            isRefreshing = true
            defer { isRefreshing = false }
        } else {
            state = .loading
        }

        do {
            async let event = api.event(id: eventID)
            async let teams = api.eventTeams(eventID: eventID)
            async let participants = api.eventParticipants(eventID: eventID)
            async let invitations = api.invitations(eventID: eventID)
            let values = try await (event, teams, participants, invitations)
            let snapshot = EventDetailsSnapshot(
                event: values.0,
                teams: values.1,
                participants: values.2,
                invitations: values.3
            )
            state = .loaded(snapshot)
        } catch let error as APIError {
            await session.handleAPIError(error)
            if case .cancelled = error { return }
            if state.hasContent {
                actionErrorMessage = error.localizedDescription
            } else {
                state = .failed(error)
            }
        } catch {
            if state.hasContent {
                actionErrorMessage = error.localizedDescription
            } else {
                state = .failed(.invalidResponse)
            }
        }
    }

    func join(teamID: EventTeamID) async {
        guard mutatingTeamID == nil, case var .loaded(snapshot) = state else { return }
        mutatingTeamID = teamID
        actionErrorMessage = nil
        let previous = snapshot
        defer { mutatingTeamID = nil }

        do {
            _ = try await api.joinEvent(eventID: eventID, teamID: teamID)
            async let refreshedEvent = api.event(id: eventID)
            async let refreshedTeam = api.eventTeamParticipants(eventID: eventID, teamID: teamID)
            let (event, participants) = try await (refreshedEvent, refreshedTeam)

            snapshot.event = event
            snapshot.participants.removeAll {
                $0.eventTeamID == teamID || $0.userID == currentUserID
            }
            snapshot.participants.append(contentsOf: participants)
            state = .loaded(snapshot)
        } catch let error as APIError {
            state = .loaded(previous)
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
        } catch {
            state = .loaded(previous)
            actionErrorMessage = error.localizedDescription
        }
    }

    func leave() async -> Bool {
        guard
            mutatingTeamID == nil,
            case let .loaded(snapshot) = state,
            let participation = snapshot.participation(for: currentUserID)
        else { return false }

        mutatingTeamID = participation.eventTeamID
        actionErrorMessage = nil
        defer { mutatingTeamID = nil }
        do {
            try await api.leaveEvent(participantID: participation.id)
            return true
        } catch let error as APIError {
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
            return false
        } catch {
            actionErrorMessage = error.localizedDescription
            return false
        }
    }

    func rename(teamID: EventTeamID, label: String) async -> Bool {
        guard mutatingTeamID == nil, case var .loaded(snapshot) = state else { return false }
        mutatingTeamID = teamID
        actionErrorMessage = nil
        defer { mutatingTeamID = nil }

        do {
            let updated = try await api.renameEventTeam(
                eventID: eventID,
                teamID: teamID,
                label: label.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            if let index = snapshot.teams.firstIndex(where: { $0.id == teamID }) {
                snapshot.teams[index] = updated
            }
            state = .loaded(snapshot)
            return true
        } catch let error as APIError {
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
            return false
        } catch {
            actionErrorMessage = error.localizedDescription
            return false
        }
    }

    func deleteEvent() async -> Bool {
        guard mutatingTeamID == nil else { return false }
        mutatingTeamID = EventTeamID(rawValue: -1)
        actionErrorMessage = nil
        defer { mutatingTeamID = nil }

        do {
            try await api.deleteEvent(id: eventID)
            return true
        } catch let error as APIError {
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
            return false
        } catch {
            actionErrorMessage = error.localizedDescription
            return false
        }
    }

    func replaceInvitations(_ invitations: [Invitation]) {
        guard case var .loaded(snapshot) = state else { return }
        snapshot.invitations = invitations
        state = .loaded(snapshot)
    }

    func clearActionError() {
        actionErrorMessage = nil
    }
}
