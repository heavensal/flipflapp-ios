import Foundation

extension APIClient {
    func registerDeviceToken(token: String, platform: String = "ios") async throws {
        let body = try encode(DeviceTokenEnvelope(deviceToken: .init(token: token, platform: platform)))
        try await sendEmpty(
            path: "api/v1/device_token",
            method: .post,
            body: body
        )
    }

    func unregisterDeviceToken(token: String) async throws {
        let body = try encode(DeviceTokenEnvelope(deviceToken: .init(token: token, platform: nil)))
        try await sendEmpty(
            path: "api/v1/device_token",
            method: .delete,
            body: body
        )
    }
}

nonisolated private struct DeviceTokenEnvelope: Encodable, Sendable {
    let deviceToken: DeviceTokenInput

    private enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
    }
}

nonisolated private struct DeviceTokenInput: Encodable, Sendable {
    let token: String
    let platform: String?
}
