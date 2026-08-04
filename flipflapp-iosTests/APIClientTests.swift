import XCTest
@testable import flipflapp_ios

final class APIClientTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testSendEmptyAccepts204NoContent() async throws {
        let client = try makeClient { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 204,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        try await client.registerDeviceToken(token: "apns-token")
    }

    func testSendEmptyAccepts200WithEmptyBody() async throws {
        let client = try makeClient { request in
            XCTAssertEqual(request.httpMethod, "DELETE")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        try await client.unregisterDeviceToken(token: "apns-token")
    }

    func testUnauthorizedSurfacesServerMessage() async {
        let client = try? makeClient { request in
            let body = """
            {"error":{"message":"Invalid email or password.","details":{}}}
            """.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, body)
        }
        guard let client else {
            XCTFail("Client setup failed")
            return
        }

        do {
            let _: CurrentUser = try await client.send(path: "api/v1/me", method: .get)
            XCTFail("Expected unauthorized error")
        } catch let error as APIError {
            XCTAssertEqual(error, .unauthorized(message: "Invalid email or password."))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testValidationErrorDecodesFieldDetails() async {
        let client = try? makeClient { request in
            let body = """
            {"error":{"message":"Validation failed","details":{"email":["is invalid"]}}}
            """.data(using: .utf8)!
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 422,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, body)
        }
        guard let client else {
            XCTFail("Client setup failed")
            return
        }

        do {
            let _: CurrentUser = try await client.send(
                path: "api/v1/me",
                method: .patch,
                body: Data("{}".utf8)
            )
            XCTFail("Expected validation error")
        } catch let error as APIError {
            XCTAssertEqual(error.validationDetails["email"], ["is invalid"])
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeClient(
        handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
    ) throws -> APIClient {
        MockURLProtocol.requestHandler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let apiConfiguration = APIConfiguration(baseURL: URL(string: "https://flipflapp.test")!)
        return APIClient(
            configuration: apiConfiguration,
            session: session,
            tokenStore: StubTokenStore(token: "test-token")
        )
    }
}

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if !data.isEmpty {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private actor StubTokenStore: TokenStoring {
    private let token: String?

    init(token: String?) {
        self.token = token
    }

    func readToken() async throws -> String? { token }
    func writeToken(_ token: String) async throws {}
    func deleteToken() async throws {}
}
