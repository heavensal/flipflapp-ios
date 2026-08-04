import MapKit
import SwiftUI
import UIKit

struct EventRouteMapView: View {
    @State private var model: EventRouteMapModel
    @State private var cameraPosition: MapCameraPosition

    init(latitude: Decimal, longitude: Decimal, title: String) {
        let model = EventRouteMapModel(
            latitude: latitude,
            longitude: longitude,
            title: title
        )
        _model = State(initialValue: model)
        _cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: model.destinationCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Map(position: $cameraPosition) {
                Annotation(model.destinationTitle, coordinate: model.destinationCoordinate) {
                    Image(systemName: "mappin.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                        .font(.title)
                        .shadow(radius: 2, y: 1)
                }

                if model.canShowUserLocation {
                    UserAnnotation()
                }

                if let route = model.route {
                    MapPolyline(route.polyline)
                        .stroke(.indigo, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
                if model.canShowUserLocation {
                    MapUserLocationButton()
                }
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.separator.opacity(0.35), lineWidth: 0.5)
            }
            .accessibilityLabel(String(localized: "Map of the event location"))

            statusRow

            Button {
                model.openInMaps()
            } label: {
                Label(String(localized: "Open in Maps"), systemImage: "arrow.triangle.turn.up.right.diamond")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .accessibilityHint(String(localized: "Opens Apple Maps with directions to the event"))
        }
        .onAppear { model.prepare() }
        .onChange(of: model.cameraFitToken) { _, _ in
            fitCamera()
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        switch model.locationAccess {
        case .notDetermined:
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Allow location access to draw the driving route from where you are to the pitch."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(String(localized: "Use my location for directions")) {
                    model.requestLocationAccess()
                }
                .buttonStyle(.bordered)
            }
        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "Location access is off. The pin still shows the pitch; enable location in Settings to see your route."))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link(String(localized: "Open Settings"), destination: url)
                        .font(.footnote.weight(.semibold))
                }
            }
        case .authorized:
            if model.isLoadingRoute && model.route == nil {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(String(localized: "Calculating route…"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            } else if let route = model.route {
                Label {
                    Text(routeSummary(route))
                } icon: {
                    Image(systemName: "car.fill")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityLabel(routeSummary(route))
            } else if let routeErrorMessage = model.routeErrorMessage {
                Text(routeErrorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func fitCamera() {
        if let route = model.route {
            cameraPosition = .rect(route.polyline.boundingMapRect.insetBy(dx: -800, dy: -800))
        } else {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: model.destinationCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            )
        }
    }

    private func routeSummary(_ route: MKRoute) -> String {
        let distance = Measurement(value: route.distance, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
        let travelTime = Duration.seconds(route.expectedTravelTime)
            .formatted(.units(width: .abbreviated, maximumUnitCount: 2))
        return String(format: String(localized: "%@ · %@"), distance, travelTime)
    }
}

/// Compact pin preview used while creating or editing an event location.
struct EventLocationPreviewMap: View {
    let latitude: Decimal
    let longitude: Decimal
    let title: String

    private var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: NSDecimalNumber(decimal: latitude).doubleValue,
            longitude: NSDecimalNumber(decimal: longitude).doubleValue
        )
    }

    var body: some View {
        Map(initialPosition: .region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )) {
            Annotation(title, coordinate: coordinate) {
                Image(systemName: "mappin.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .red)
                    .font(.title2)
            }
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .disabled(true)
        .accessibilityLabel(String(localized: "Map preview of the selected address"))
    }
}
