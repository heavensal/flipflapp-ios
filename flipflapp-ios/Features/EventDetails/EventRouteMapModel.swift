import CoreLocation
import Foundation
import MapKit
import Observation

@MainActor
@Observable
final class EventRouteMapModel: NSObject {
    enum LocationAccess {
        case notDetermined
        case denied
        case authorized
    }

    private(set) var locationAccess: LocationAccess
    private(set) var userCoordinate: CLLocationCoordinate2D?
    private(set) var route: MKRoute?
    private(set) var isLoadingRoute = false
    private(set) var routeErrorMessage: String?
    /// Bumped when the map camera should refit the destination or route.
    private(set) var cameraFitToken = 0

    let destinationCoordinate: CLLocationCoordinate2D
    let destinationTitle: String

    private let locationManager = CLLocationManager()
    private var routeTask: Task<Void, Never>?
    private var lastRoutedCoordinate: CLLocationCoordinate2D?

    init(latitude: Decimal, longitude: Decimal, title: String) {
        destinationCoordinate = CLLocationCoordinate2D(
            latitude: Self.degrees(from: latitude),
            longitude: Self.degrees(from: longitude)
        )
        destinationTitle = title
        locationAccess = Self.access(for: locationManager.authorizationStatus)
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 25
    }

    var canShowUserLocation: Bool {
        locationAccess == .authorized
    }

    func prepare() {
        locationAccess = Self.access(for: locationManager.authorizationStatus)
        cameraFitToken += 1
        guard locationAccess == .authorized else { return }
        locationManager.startUpdatingLocation()
    }

    func requestLocationAccess() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationAccess = .denied
        case .authorizedAlways, .authorizedWhenInUse:
            locationAccess = .authorized
            locationManager.startUpdatingLocation()
        @unknown default:
            locationAccess = .denied
        }
    }

    func openInMaps() {
        let destination = mapItem(
            coordinate: destinationCoordinate,
            name: destinationTitle
        )
        if let userCoordinate {
            let source = mapItem(coordinate: userCoordinate, name: String(localized: "My location"))
            MKMapItem.openMaps(
                with: [source, destination],
                launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
            )
        } else {
            destination.openInMaps(
                launchOptions: [
                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
                    MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: destinationCoordinate)
                ]
            )
        }
    }

    private func refreshRoute(from coordinate: CLLocationCoordinate2D) {
        if let lastRoutedCoordinate,
           hypot(
               lastRoutedCoordinate.latitude - coordinate.latitude,
               lastRoutedCoordinate.longitude - coordinate.longitude
           ) < 0.0003,
           route != nil {
            return
        }

        lastRoutedCoordinate = coordinate
        routeTask?.cancel()
        routeTask = Task {
            await calculateRoute(from: coordinate)
        }
    }

    private func calculateRoute(from coordinate: CLLocationCoordinate2D) async {
        isLoadingRoute = true
        routeErrorMessage = nil
        defer { isLoadingRoute = false }

        let request = MKDirections.Request()
        request.source = mapItem(coordinate: coordinate, name: String(localized: "My location"))
        request.destination = mapItem(coordinate: destinationCoordinate, name: destinationTitle)
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        do {
            let response = try await MKDirections(request: request).calculate()
            guard !Task.isCancelled else { return }
            guard let route = response.routes.first else {
                routeErrorMessage = String(localized: "No driving route could be calculated.")
                self.route = nil
                return
            }
            self.route = route
            cameraFitToken += 1
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            route = nil
            routeErrorMessage = String(localized: "No driving route could be calculated.")
        }
    }

    private func mapItem(coordinate: CLLocationCoordinate2D, name: String) -> MKMapItem {
        let item = MKMapItem(
            location: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude),
            address: nil
        )
        item.name = name
        return item
    }

    private static func access(for status: CLAuthorizationStatus) -> LocationAccess {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        case .denied, .restricted:
            return .denied
        @unknown default:
            return .denied
        }
    }

    private static func degrees(from value: Decimal) -> CLLocationDegrees {
        NSDecimalNumber(decimal: value).doubleValue
    }
}

extension EventRouteMapModel: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.locationAccess = Self.access(for: status)
            switch self.locationAccess {
            case .authorized:
                self.locationManager.startUpdatingLocation()
            case .denied, .notDetermined:
                self.locationManager.stopUpdatingLocation()
                self.userCoordinate = nil
                self.route = nil
                self.lastRoutedCoordinate = nil
                self.cameraFitToken += 1
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate
        Task { @MainActor in
            self.userCoordinate = coordinate
            self.refreshRoute(from: coordinate)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if self.route == nil {
                self.routeErrorMessage = String(localized: "Your location could not be determined right now.")
            }
        }
    }
}
