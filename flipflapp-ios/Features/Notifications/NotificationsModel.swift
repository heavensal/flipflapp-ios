import Foundation
import Observation

@MainActor
@Observable
final class NotificationsModel {
    private(set) var state: LoadState<[AppNotification]> = .idle
    private(set) var isRefreshing = false
    private(set) var mutatingIDs: Set<NotificationID> = []
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
        await fetch()
    }

    func retry() async {
        actionErrorMessage = nil
        if state.hasContent {
            isRefreshing = true
            defer { isRefreshing = false }
            await fetch()
        } else {
            state = .loading
            await fetch()
        }
    }

    func open(_ notification: AppNotification) async -> EventID? {
        let eventID = notification.linkedEventID
        if notification.read {
            return eventID
        }

        markReadLocally(notification.id)
        mutatingIDs.insert(notification.id)
        defer { mutatingIDs.remove(notification.id) }

        do {
            let updated = try await api.readNotification(id: notification.id)
            replace(updated)
            return updated.linkedEventID ?? eventID
        } catch let error as APIError {
            revertRead(notification.id)
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
            return nil
        } catch {
            revertRead(notification.id)
            actionErrorMessage = error.localizedDescription
            return nil
        }
    }

    func markAllRead() async {
        guard !isMarkingAll, unreadCount > 0 else { return }
        isMarkingAll = true
        actionErrorMessage = nil
        let snapshot = state.loadedValue
        markAllReadLocally()
        defer { isMarkingAll = false }
        do {
            try await api.readAllNotifications()
            publishLocallyReadAll()
        } catch let error as APIError {
            if let snapshot {
                publish(snapshot)
            }
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
        } catch {
            if let snapshot {
                publish(snapshot)
            }
            actionErrorMessage = error.localizedDescription
        }
    }

    func delete(_ notification: AppNotification) async {
        guard !mutatingIDs.contains(notification.id) else { return }
        mutatingIDs.insert(notification.id)
        actionErrorMessage = nil

        let snapshot = state.loadedValue
        removeLocally(notification.id)
        defer { mutatingIDs.remove(notification.id) }

        do {
            try await api.deleteNotification(id: notification.id)
        } catch let error as APIError {
            if let snapshot {
                publish(snapshot)
            }
            await session.handleAPIError(error)
            actionErrorMessage = error.localizedDescription
        } catch {
            if let snapshot {
                publish(snapshot)
            }
            actionErrorMessage = error.localizedDescription
        }
    }

    private func fetch() async {
        do {
            let notifications = try await api.notifications()
            publish(notifications)
        } catch let error as APIError {
            await session.handleAPIError(error)
            if case .cancelled = error { return }
            if !state.hasContent {
                state = .failed(error)
            } else {
                actionErrorMessage = error.localizedDescription
            }
        } catch {
            if !state.hasContent {
                state = .failed(.invalidResponse)
            }
        }
    }

    private func markReadLocally(_ id: NotificationID) {
        guard case var .loaded(notifications) = state else { return }
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index] = notifications[index].markingRead()
            publish(notifications)
        }
    }

    private func revertRead(_ id: NotificationID) {
        guard case var .loaded(notifications) = state else { return }
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index] = notifications[index].markingRead(false)
            publish(notifications)
        }
    }

    private func markAllReadLocally() {
        guard case let .loaded(notifications) = state else { return }
        publish(notifications.map { $0.markingRead() })
    }

    private func publishLocallyReadAll() {
        guard case let .loaded(notifications) = state else { return }
        publish(notifications)
    }

    private func removeLocally(_ id: NotificationID) {
        guard case var .loaded(notifications) = state else { return }
        notifications.removeAll { $0.id == id }
        publish(notifications)
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
