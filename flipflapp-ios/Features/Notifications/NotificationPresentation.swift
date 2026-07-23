import SwiftUI

struct NotificationPresentation {
    let title: String
    let message: String
    let systemImage: String
    let tint: Color

    init(notification: AppNotification) {
        let eventTitle = notification.payload["title"]?.stringValue
            ?? String(localized: "an event")
        let actor = notification.payload["sender"]?.stringValue
            ?? notification.payload["first_name"]?.stringValue
            ?? String(localized: "A player")

        switch notification.kind {
        case .updated:
            title = String(localized: "Event updated")
            message = String(format: String(localized: "Information changed for %@."), eventTitle)
            systemImage = "pencil.circle.fill"
            tint = .blue
        case .canceled:
            title = String(localized: "Event canceled")
            message = String(format: String(localized: "%@ has been canceled."), eventTitle)
            systemImage = "xmark.circle.fill"
            tint = .red
        case .reminder:
            title = String(localized: "A spot may be available")
            message = String(format: String(localized: "Check the teams for %@."), eventTitle)
            systemImage = "clock.badge.exclamationmark.fill"
            tint = .orange
        case .joined:
            title = String(localized: "New player")
            message = String(format: String(localized: "%1$@ joined %2$@."), actor, eventTitle)
            systemImage = "person.crop.circle.badge.plus"
            tint = .green
        case .left:
            title = String(localized: "A player left")
            message = String(format: String(localized: "%1$@ left %2$@."), actor, eventTitle)
            systemImage = "person.crop.circle.badge.minus"
            tint = .orange
        case .invited:
            title = String(localized: "You are invited")
            message = String(format: String(localized: "%1$@ invited you to %2$@."), actor, eventTitle)
            systemImage = "envelope.open.fill"
            tint = .indigo
        case .friendshipRequested:
            title = String(localized: "Friend request")
            message = String(localized: "Open Friends to respond.")
            systemImage = "person.2.badge.gearshape.fill"
            tint = .indigo
        case .unknown:
            title = String(localized: "FlipFlapp update")
            message = String(localized: "Open FlipFlapp to see what changed.")
            systemImage = "bell.fill"
            tint = .secondary
        }
    }
}
