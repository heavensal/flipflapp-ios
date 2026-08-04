import Foundation

enum PushNavigationDestination: Equatable {
    case events(EventID)
    case friends
    case notifications
}

enum PushNavigationPath {
    static func destination(from path: String) -> PushNavigationDestination {
        let normalized = path.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        switch normalized {
        case "friendships":
            return .friends
        case "list", "notifications":
            return .notifications
        default:
            if let eventID = parseEventID(from: normalized) {
                return .events(eventID)
            }
            return .notifications
        }
    }

    static func destination(from userInfo: [AnyHashable: Any]) -> PushNavigationDestination? {
        if let path = userInfo["path"] as? String, !path.isEmpty {
            return destination(from: path)
        }
        if let kind = userInfo["kind"] as? String, kind == AppNotification.Kind.friendshipRequested.rawValue {
            return .friends
        }
        if let eventID = userInfo["event_id"] as? Int {
            return .events(EventID(rawValue: eventID))
        }
        if let eventIDString = userInfo["event_id"] as? String, let eventID = Int(eventIDString) {
            return .events(EventID(rawValue: eventID))
        }
        return nil
    }

    private static func parseEventID(from normalized: String) -> EventID? {
        guard normalized.hasPrefix("events/") else { return nil }
        let idPart = normalized.dropFirst("events/".count)
        guard let rawValue = Int(idPart) else { return nil }
        return EventID(rawValue: rawValue)
    }
}

@MainActor
@Observable
final class PushNavigationRouter {
    private(set) var pending: PushNavigationDestination?

    func handle(userInfo: [AnyHashable: Any]) {
        guard let destination = PushNavigationPath.destination(from: userInfo) else { return }
        pending = destination
    }

    func handle(path: String) {
        pending = PushNavigationPath.destination(from: path)
    }

    func consume() -> PushNavigationDestination? {
        defer { pending = nil }
        return pending
    }
}
