import XCTest
@testable import flipflapp_ios

final class APIDecodingTests: XCTestCase {
    func testDecodesCurrentUserWithUnconfirmedEmail() throws {
        let json = """
        {
          "id": 1,
          "email": "ada@example.com",
          "unconfirmed_email": "new@example.com",
          "first_name": "Ada",
          "last_name": "Lovelace",
          "username": "ada#0001",
          "role": "player",
          "avatar_url": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let user = try decoder.decode(CurrentUser.self, from: json)

        XCTAssertEqual(user.email, "ada@example.com")
        XCTAssertEqual(user.unconfirmedEmail, "new@example.com")
    }

    func testValidationSummaryJoinsFieldMessages() {
        let error = APIError.validation(details: [
            "email": ["is invalid"],
            "password": ["is too short"]
        ])
        XCTAssertTrue(error.validationSummary?.contains("is invalid") == true)
    }

    func testDecodesEventWithStringEncodedDecimals() throws {
        let json = """
        {
          "id": 42,
          "title": "Beach volleyball",
          "description": null,
          "location": "Paris",
          "start_time": "2026-08-10T18:00:00Z",
          "number_of_participants": 12,
          "price": "15",
          "is_private": false,
          "latitude": "48.8566",
          "longitude": "2.3522",
          "user_id": 7,
          "created_at": "2026-08-01T10:00:00Z",
          "updated_at": "2026-08-01T10:00:00Z",
          "participants_count": 8,
          "spots_remaining": 4,
          "fill_level": "tight",
          "user": {
            "id": 7,
            "first_name": "Ada",
            "last_name": "Lovelace",
            "username": "ada#0001",
            "avatar_url": null
          },
          "current_user": {
            "participant": false,
            "can_invite": true,
            "author": true,
            "invited": false
          }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let event = try decoder.decode(Event.self, from: json)

        XCTAssertEqual(event.id.rawValue, 42)
        XCTAssertEqual(event.fillLevel, .tight)
        XCTAssertEqual(event.price, 15)
        XCTAssertEqual(event.currentUser?.canInvite, true)
    }
}

final class AppDeepLinkTests: XCTestCase {
    func testParsesConfirmationToken() {
        let url = URL(string: "https://flipflapp.fr/confirmation?confirmation_token=abc123")!
        XCTAssertEqual(AppDeepLink.parse(url: url), .confirmAccount(token: "abc123"))
    }

    func testParsesResetPasswordToken() {
        let url = URL(string: "flipflapp://reset?reset_password_token=reset-1")!
        XCTAssertEqual(AppDeepLink.parse(url: url), .resetPassword(token: "reset-1"))
    }
}
