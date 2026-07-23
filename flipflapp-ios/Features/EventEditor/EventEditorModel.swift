import Foundation
import Observation

struct EventDraft {
    var title = ""
    var description = ""
    var location = ""
    var startTime = Date().addingTimeInterval(86_400)
    var numberOfParticipants = 10
    var price = "0"
    var isPrivate = true
    var latitude = ""
    var longitude = ""

    init(event: Event? = nil) {
        guard let event else { return }
        title = event.title
        description = event.description ?? ""
        location = event.location
        startTime = event.startTime
        numberOfParticipants = event.numberOfParticipants
        price = NSDecimalNumber(decimal: event.price).stringValue
        isPrivate = event.isPrivate
        latitude = NSDecimalNumber(decimal: event.latitude).stringValue
        longitude = NSDecimalNumber(decimal: event.longitude).stringValue
    }

    func makeInput() -> EventInput? {
        guard
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            startTime > Date(),
            numberOfParticipants > 0,
            let priceValue = parseDecimal(price),
            priceValue >= 0,
            isWhole(priceValue),
            let latitudeValue = parseDecimal(latitude),
            let longitudeValue = parseDecimal(longitude)
        else {
            return nil
        }

        return EventInput(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            location: location.trimmingCharacters(in: .whitespacesAndNewlines),
            startTime: startTime,
            numberOfParticipants: numberOfParticipants,
            price: priceValue,
            isPrivate: isPrivate,
            latitude: latitudeValue,
            longitude: longitudeValue
        )
    }

    private func parseDecimal(_ value: String) -> Decimal? {
        Decimal(string: value, locale: .current)
            ?? Decimal(string: value, locale: Locale(identifier: "en_US_POSIX"))
    }

    private func isWhole(_ value: Decimal) -> Bool {
        var source = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &source, 0, .plain)
        return rounded == value
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

@MainActor
@Observable
final class EventEditorModel {
    var draft: EventDraft
    private(set) var isSubmitting = false
    var errorMessage: String?

    private let api: APIClient
    private let session: SessionStore
    private let eventID: EventID?

    init(api: APIClient, session: SessionStore, event: Event?) {
        self.api = api
        self.session = session
        eventID = event?.id
        draft = EventDraft(event: event)
    }

    func submit() async -> Event? {
        guard !isSubmitting else { return nil }
        guard let input = draft.makeInput() else {
            errorMessage = String(localized: "Complete every required field. The date must be in the future and the price must be a whole euro amount.")
            return nil
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            if let eventID {
                return try await api.updateEvent(id: eventID, input: input)
            }
            return try await api.createEvent(input)
        } catch let error as APIError {
            await session.handleAPIError(error)
            errorMessage = error.localizedDescription
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
