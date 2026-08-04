import MapKit
import SwiftUI

struct LocationSearchField: View {
    @Binding var location: String
    @Binding var latitude: String
    @Binding var longitude: String

    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var isSearching = false
    private let debouncer = DebouncedTask()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(String(localized: "Search for a place"), text: $query)
                .textInputAutocapitalization(.words)
                .onChange(of: query) { _, newValue in
                    location = newValue
                    scheduleSearch(newValue)
                }

            if isSearching {
                ProgressView()
                    .controlSize(.small)
            }

            ForEach(results, id: \.self) { item in
                Button {
                    select(item)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name ?? String(localized: "Unknown place"))
                            .font(.body)
                        if let subtitle = item.placemark.title {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            query = location
        }
    }

    private func scheduleSearch(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            debouncer.cancel()
            results = []
            isSearching = false
            return
        }
        isSearching = true
        debouncer.schedule { await search(trimmed) }
    }

    private func search(_ value: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = value
        do {
            let response = try await MKLocalSearch(request: request).start()
            guard value == query.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            results = Array(response.mapItems.prefix(5))
            isSearching = false
        } catch {
            isSearching = false
        }
    }

    private func select(_ item: MKMapItem) {
        let placemark = item.placemark
        location = [item.name, placemark.title].compactMap { $0 }.first ?? location
        query = location
        latitude = String(placemark.coordinate.latitude)
        longitude = String(placemark.coordinate.longitude)
        results = []
    }
}
