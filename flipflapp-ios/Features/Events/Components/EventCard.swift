import SwiftUI

struct EventCard: View {
    let event: Event

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(event.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Label {
                            Text(event.startTime, format: .dateTime.weekday(.wide).day().month().hour().minute())
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    privacyPill
                }

                Label(event.location, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Divider()

                HStack {
                    Label(
                        "\(event.participantsCount)/\(event.numberOfParticipants)",
                        systemImage: "person.3.fill"
                    )
                    .accessibilityLabel(
                        String(localized: "\(event.participantsCount) players out of \(event.numberOfParticipants)")
                    )
                    Spacer()
                    Text(event.price, format: .currency(code: "EUR"))
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .font(.subheadline)
            }
        }
    }

    @ViewBuilder
    private var privacyPill: some View {
        if event.isPrivate {
            StatusPill(title: "Private", systemImage: "lock.fill", tint: .orange)
        } else {
            StatusPill(title: "Public", systemImage: "globe.europe.africa.fill", tint: .green)
        }
    }
}
