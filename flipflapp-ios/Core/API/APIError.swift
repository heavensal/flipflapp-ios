import Foundation

nonisolated enum APIError: LocalizedError, Sendable, Equatable {
    case unauthorized(message: String? = nil)
    case forbidden
    case notFound
    case validation(details: [String: [String]])
    case offline
    case timedOut
    case cancelled
    case invalidResponse
    case incompatibleResponse
    case server(statusCode: Int)
    case requestEncoding

    var isUnauthorized: Bool {
        if case .unauthorized = self { return true }
        return false
    }

    var errorDescription: String? {
        switch self {
        case let .unauthorized(message):
            if let message, !message.isEmpty {
                return message
            }
            return String(localized: "Your session has expired. Sign in again.")
        case .forbidden:
            return String(localized: "You are not allowed to perform this action.")
        case .notFound:
            return String(localized: "This content is no longer available.")
        case .validation:
            return validationSummary ?? String(localized: "Some information needs to be corrected.")
        case .offline:
            return String(localized: "No network connection. Check your connection and try again.")
        case .timedOut:
            return String(localized: "The server took too long to respond. Try again.")
        case .cancelled:
            return nil
        case .invalidResponse, .incompatibleResponse:
            return String(localized: "The app could not read the server response. Please update the app or try again later.")
        case let .server(statusCode):
            return String(format: String(localized: "The server returned an error (%lld). Try again later."), Int64(statusCode))
        case .requestEncoding:
            return String(localized: "The request could not be prepared.")
        }
    }
}

nonisolated struct APIErrorEnvelope: Decodable, Sendable {
    nonisolated struct Detail: Decodable, Sendable {
        let message: String
        let details: [String: [String]]?
    }

    let error: Detail
}

nonisolated struct AuthenticationErrorEnvelope: Decodable, Sendable {
    let error: String
}
