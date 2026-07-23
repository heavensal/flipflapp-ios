import SwiftUI

struct NotificationRow: View {
    let notification: AppNotification

    private var presentation: NotificationPresentation {
        NotificationPresentation(notification: notification)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: presentation.systemImage)
                .font(.title3)
                .foregroundStyle(presentation.tint)
                .frame(width: 40, height: 40)
                .background(presentation.tint.opacity(0.12), in: .circle)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(presentation.title)
                        .font(.body.weight(notification.read ? .regular : .bold))
                    Spacer()
                    if !notification.read {
                        Text(String(localized: "New"))
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.indigo)
                            .accessibilityLabel(String(localized: "Unread notification"))
                    }
                }
                Text(presentation.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(notification.createdAt, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if notification.linkedEventID != nil {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 6)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
