import Foundation
import Observation

@MainActor
@Observable
final class InvitationPickerModel {
    private(set) var state: LoadState<[PublicUser]> = .idle
    private(set) var isSubmitting = false
    var selection: Set<UserID> = []
    var errorMessage: String?

    private let eventID: EventID
    private let api: APIClient
    private let session: SessionStore
    private let currentUserID: UserID
    private let participantIDs: Set<UserID>
    private let invitedIDs: Set<UserID>

    init(
        eventID: EventID,
        api: APIClient,
        session: SessionStore,
        currentUserID: UserID,
        participants: [EventParticipant],
        invitations: [Invitation]
    ) {
        self.eventID = eventID
        self.api = api
        self.session = session
        self.currentUserID = currentUserID
        participantIDs = Set(participants.map(\.userID))
        invitedIDs = Set(invitations.map(\.userID))
    }

    func load() async {
        if case .loading = state { return }
        state = .loading
        do {
            let buckets = try await api.friendships()
            let friends = buckets.accepted
                .map { $0.otherUser(relativeTo: currentUserID) }
                .filter { !participantIDs.contains($0.id) && !invitedIDs.contains($0.id) }
            state = friends.isEmpty ? .empty : .loaded(friends)
        } catch let error as APIError {
            await session.handleAPIError(error)
            state = .failed(error)
        } catch {
            state = .failed(.invalidResponse)
        }
    }

    func submit() async -> [Invitation]? {
        guard !isSubmitting, !selection.isEmpty else { return nil }
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }
        do {
            _ = try await api.createInvitations(eventID: eventID, userIDs: Array(selection))
            return try await api.invitations(eventID: eventID)
        } catch let error as APIError {
            await session.handleAPIError(error)
            errorMessage = error.localizedDescription
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
