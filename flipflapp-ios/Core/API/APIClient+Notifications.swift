import Foundation

extension APIClient {
    func notifications() async throws -> [AppNotification] {
        try await send(path: "api/v1/notifications", method: .get)
    }

    func readNotification(id: NotificationID) async throws -> AppNotification {
        try await send(path: "api/v1/notifications/\(id.rawValue)/read", method: .patch)
    }

    func readAllNotifications() async throws {
        try await sendEmpty(path: "api/v1/notifications/read_all", method: .patch)
    }

    func deleteNotification(id: NotificationID) async throws {
        try await sendEmpty(path: "api/v1/notifications/\(id.rawValue)", method: .delete)
    }
}
