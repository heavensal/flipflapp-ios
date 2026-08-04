import Foundation

extension APIError {
    var validationDetails: [String: [String]] {
        if case let .validation(details) = self { return details }
        return [:]
    }

    func fieldMessages(for fields: [String]) -> [String] {
        let details = validationDetails
        return fields.compactMap { field in
            guard let messages = details[field], let first = messages.first else { return nil }
            return first
        }
    }

    var validationSummary: String? {
        let messages = validationDetails.values.flatMap { $0 }
        guard !messages.isEmpty else { return nil }
        return messages.joined(separator: "\n")
    }
}
