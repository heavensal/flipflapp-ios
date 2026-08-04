import SwiftUI

struct EventHeroCard: View {
    let event: Event

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.title)
                            .font(.title2.bold())
                        Text(String(format: String(localized: "Organized by %@"), event.user.displayName))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    if event.currentUser?.author == true {
                        StatusPill(title: "Organizer", systemImage: "star.fill", tint: .indigo)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label {
                        Text(event.startTime, format: .dateTime.weekday(.wide).day().month(.wide).hour().minute())
                    } icon: {
                        Image(systemName: "calendar.badge.clock")
                    }
                    Label(event.location, systemImage: "mappin.and.ellipse")
                    Label {
                        Text(event.price, format: .currency(code: "EUR"))
                    } icon: {
                        Image(systemName: "eurosign.circle")
                    }
                }
                .font(.body)

                ProgressView(
                    value: Double(event.participantsCount),
                    total: Double(max(event.numberOfParticipants, 1))
                ) {
                    Text(String(localized: "Official players"))
                } currentValueLabel: {
                    Text("\(event.participantsCount)/\(event.numberOfParticipants)")
                }
                .tint(event.fillLevel == .full ? .orange : event.fillLevel == .tight ? .yellow : .indigo)
            }
        }
    }
}
