import Foundation
import OSLog

actor APIClient {
    private let configuration: APIConfiguration
    private let session: URLSession
    private let tokenStore: any TokenStoring
    private let logger = Logger(subsystem: "fr.flipflapp.ios", category: "API")

    init(
        configuration: APIConfiguration,
        session: URLSession = .shared,
        tokenStore: any TokenStoring
    ) {
        self.configuration = configuration
        self.session = session
        self.tokenStore = tokenStore
    }

    func encode<Body: Encodable & Sendable>(_ body: Body) throws -> Data {
        do {
            return try makeEncoder().encode(body)
        } catch {
            throw APIError.requestEncoding
        }
    }

    func send<Response: Decodable & Sendable>(
        path: String,
        method: HTTPMethod,
        body: Data? = nil,
        queryItems: [URLQueryItem] = [],
        authenticated: Bool = true,
        contentType: String? = nil
    ) async throws -> Response {
        let (data, response) = try await perform(
            path: path,
            method: method,
            body: body,
            queryItems: queryItems,
            authenticated: authenticated,
            contentType: contentType
        )
        try validateJSON(response: response, data: data)

        do {
            return try makeDecoder().decode(Response.self, from: data)
        } catch {
            logger.error("Response decoding failed for \(method.rawValue, privacy: .public) \(path, privacy: .public)")
            throw APIError.incompatibleResponse
        }
    }

    func sendEmpty(
        path: String,
        method: HTTPMethod,
        body: Data? = nil,
        authenticated: Bool = true,
        contentType: String? = nil
    ) async throws {
        _ = try await perform(
            path: path,
            method: method,
            body: body,
            authenticated: authenticated,
            contentType: contentType
        )
    }

    func sendWithHTTPResponse<Response: Decodable & Sendable>(
        path: String,
        method: HTTPMethod,
        body: Data? = nil,
        authenticated: Bool = true,
        contentType: String? = nil
    ) async throws -> (Response, HTTPURLResponse) {
        let (data, response) = try await perform(
            path: path,
            method: method,
            body: body,
            authenticated: authenticated,
            contentType: contentType
        )
        try validateJSON(response: response, data: data)

        do {
            return (try makeDecoder().decode(Response.self, from: data), response)
        } catch {
            throw APIError.incompatibleResponse
        }
    }

    private func perform(
        path: String,
        method: HTTPMethod,
        body: Data? = nil,
        queryItems: [URLQueryItem] = [],
        authenticated: Bool,
        contentType: String? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        var components = URLComponents(
            url: configuration.baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        )
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.setValue(contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
        }
        if authenticated {
            guard let token = try await tokenStore.readToken() else {
                throw APIError.unauthorized()
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let clock = ContinuousClock()
        let start = clock.now
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            let duration = start.duration(to: clock.now)
            logger.debug(
                "\(method.rawValue, privacy: .public) \(path, privacy: .public) -> \(httpResponse.statusCode, privacy: .public) in \(String(describing: duration), privacy: .public)"
            )

            guard (200..<300).contains(httpResponse.statusCode) else {
                throw mapError(statusCode: httpResponse.statusCode, data: data)
            }
            return (data, httpResponse)
        } catch is CancellationError {
            throw APIError.cancelled
        } catch let error as APIError {
            throw error
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost:
                throw APIError.offline
            case .timedOut:
                throw APIError.timedOut
            case .cancelled:
                throw APIError.cancelled
            default:
                throw APIError.invalidResponse
            }
        } catch {
            throw APIError.invalidResponse
        }
    }

    private func mapError(statusCode: Int, data: Data) -> APIError {
        switch statusCode {
        case 401:
            .unauthorized(message: decodeErrorMessage(from: data))
        case 403:
            .forbidden
        case 404:
            .notFound
        case 422:
            .validation(details: decodeErrorDetails(from: data))
        default:
            .server(statusCode: statusCode)
        }
    }

    private func decodeErrorMessage(from data: Data) -> String? {
        if let envelope = try? makeDecoder().decode(APIErrorEnvelope.self, from: data) {
            return envelope.error.message
        }
        if let legacy = try? makeDecoder().decode(AuthenticationErrorEnvelope.self, from: data) {
            return legacy.error
        }
        return nil
    }

    private func decodeErrorDetails(from data: Data) -> [String: [String]] {
        (try? makeDecoder().decode(APIErrorEnvelope.self, from: data).error.details) ?? [:]
    }

    private func validateJSON(response: HTTPURLResponse, data: Data) throws {
        guard !data.isEmpty else { return }
        guard
            let contentType = response.value(forHTTPHeaderField: "Content-Type")?.lowercased(),
            contentType.contains("application/json")
        else {
            throw APIError.incompatibleResponse
        }
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(value) {
                return date
            }
            if let date = try? Date.ISO8601FormatStyle().parse(value) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected an ISO 8601 timestamp."
            )
        }
        return decoder
    }
}
