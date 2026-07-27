import Foundation
import MapKit
import Observation

struct AddressSuggestion: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String

    fileprivate let completion: MKLocalSearchCompletion

    init(completion: MKLocalSearchCompletion) {
        self.completion = completion
        title = completion.title
        subtitle = completion.subtitle
        id = "\(completion.title)|\(completion.subtitle)|\(completion.hash)"
    }

    static func == (lhs: AddressSuggestion, rhs: AddressSuggestion) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ResolvedAddress: Equatable {
    let location: String
    let latitude: Decimal
    let longitude: Decimal
}

/// MapKit place search for event location, mirroring Rails Google Places autocomplete UX.
@MainActor
@Observable
final class AddressAutocompleteModel: NSObject {
    private(set) var suggestions: [AddressSuggestion] = []
    private(set) var isResolving = false
    private(set) var resolveErrorMessage: String?

    private let completer = MKLocalSearchCompleter()
    private var activeQuery = ""

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        // Bias results toward France without requesting device location permission.
        completer.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.603_354, longitude: 1.888_334),
            span: MKCoordinateSpan(latitudeDelta: 12, longitudeDelta: 12)
        )
    }

    func updateQuery(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        activeQuery = trimmed
        resolveErrorMessage = nil

        guard trimmed.count >= 2 else {
            suggestions = []
            completer.queryFragment = ""
            return
        }

        completer.queryFragment = trimmed
    }

    func clearSuggestions() {
        suggestions = []
        completer.queryFragment = ""
    }

    func resolve(_ suggestion: AddressSuggestion) async -> ResolvedAddress? {
        isResolving = true
        resolveErrorMessage = nil
        defer { isResolving = false }

        do {
            let request = MKLocalSearch.Request(completion: suggestion.completion)
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first else {
                resolveErrorMessage = String(localized: "Could not resolve that address. Try another suggestion.")
                return nil
            }

            let coordinate = item.location.coordinate
            guard CLLocationCoordinate2DIsValid(coordinate) else {
                resolveErrorMessage = String(localized: "Could not resolve that address. Try another suggestion.")
                return nil
            }

            let location = formattedAddress(for: item, suggestion: suggestion)
            clearSuggestions()
            return ResolvedAddress(
                location: location,
                latitude: decimal(from: coordinate.latitude),
                longitude: decimal(from: coordinate.longitude)
            )
        } catch is CancellationError {
            return nil
        } catch {
            resolveErrorMessage = String(localized: "Could not resolve that address. Try another suggestion.")
            return nil
        }
    }

    private func formattedAddress(for item: MKMapItem, suggestion: AddressSuggestion) -> String {
        if let fullAddress = item.address?.fullAddress, !fullAddress.isEmpty {
            return fullAddress
        }
        if let shortAddress = item.address?.shortAddress, !shortAddress.isEmpty {
            return shortAddress
        }
        if let name = item.name, !name.isEmpty, !suggestion.subtitle.isEmpty {
            return "\(name), \(suggestion.subtitle)"
        }
        if let name = item.name, !name.isEmpty {
            return name
        }
        let parts = [suggestion.title, suggestion.subtitle].filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }

    private func decimal(from value: CLLocationDegrees) -> Decimal {
        Decimal(string: String(format: "%.6f", value), locale: Locale(identifier: "en_US_POSIX")) ?? Decimal(value)
    }
}

extension AddressAutocompleteModel: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let completions = completer.results
        let query = completer.queryFragment
        Task { @MainActor in
            guard query == self.activeQuery || query == self.completer.queryFragment else { return }
            self.suggestions = completions.map(AddressSuggestion.init)
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.suggestions = []
        }
    }
}
