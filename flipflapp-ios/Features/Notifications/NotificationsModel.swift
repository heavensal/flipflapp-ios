import Foundation
import Observation

@MainActor
@Observable
final class NotificationsModel {
    private(set) var state: LoadState<[AppNotification]> = .idle
    private(set) var mutatingID: NotificationID?
    private(set) var isMarkingAll = false
    var actionErrorMessage: String?

    private let api: APIClient
    private let session: SessionStore
    private let badges: AppBadgeStore

    init(api: APIClient, session: SessionStore, badges: AppBadgeStore) {
        self.api = api
        self.session = session
        self.badges = badges
    }

    var unreadCount: Int {
        guard case let .loaded(notifications) = state else { return 0 }
        return notifications.filter { !$0.read }.count
    }

    func load() async {
        if case .loading = state { return }
        if case .idle = state { state = .loading }
        do {
            let notifications = try await api.notifications()
            publish(notifications)
        } catch let error as APIError {
            await session.handleAPIError(error)
            if case .cancelled = error { return }
            state = .failed(error)
        } catch {
            state = .failed(.invalidResponse)
        }
    }

    func retry() async {
        state = .idle
        await load()
    }

    func open(_ notification: AppNotification) async -> EventID? {
        if notification.read {
            return notification.linkedEventID
        }
        guard mutatingID == nil else { return nil }
        mutatingID = notification.id
        defer { mutatingID = nil }
        do {
            let updated = try await api.readNotification(id: notification.id)
            replace(updated)
            return updated.linkedEventID
        } catch let error as APIError {
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
            return nil
        } catch {
            actionErrorMessage = error.localizedDescription
            return nil
        }
    }

    func markAllRead() async {
        guard !isMarkingAll, unreadCount > 0 else { return }
        isMarkingAll = true
        actionErrorMessage = nil
        defer { isMarkingAll = false }
        do {
            try await api.readAllNotifications()
            let notifications = try await api.notifications()
            publish(notifications)
        } catch let error as APIError {
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    func delete(_ notification: AppNotification) async {
        guard mutatingID == nil else { return }
        mutatingID = notification.id
        actionErrorMessage = nil
        defer { mutatingID = nil }
        do {
            try await api.deleteNotification(id: notification.id)
            if case var .loaded(notifications) = state {
                notifications.removeAll { $0.id == notification.id }
                publish(notifications)
            }
        } catch let error as APIError {
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    private func replace(_ notification: AppNotification) {
        guard case var .loaded(notifications) = state else { return }
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = notification
        }
        publish(notifications)
    }

    private func publish(_ notifications: [AppNotification]) {
        badges.unreadNotifications = notifications.filter { !$0.read }.count
        state = notifications.isEmpty ? .empty : .loaded(notifications)
    }
}
