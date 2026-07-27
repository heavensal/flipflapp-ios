import MapKit
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

                if let description = event.description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Label {
                        Text(event.startTime, format: .dateTime.weekday(.wide).day().month(.wide).hour().minute())
                    } icon: {
                        Image(systemName: "calendar.badge.clock")
                    }

                    Button(action: openInMaps) {
                        Label {
                            Text(event.location)
                                .multilineTextAlignment(.leading)
                        } icon: {
                            Image(systemName: "mappin.and.ellipse")
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                    .accessibilityHint(String(localized: "Opens this address in Maps"))

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
                .tint(event.fillLevel == .full ? .orange : .indigo)
            }
        }
    }

    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: NSDecimalNumber(decimal: event.latitude).doubleValue,
            longitude: NSDecimalNumber(decimal: event.longitude).doubleValue
        )
        let item = MKMapItem(
            location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
            address: nil
        )
        item.name = event.location
        item.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate)
            ]
        )
    }
}
