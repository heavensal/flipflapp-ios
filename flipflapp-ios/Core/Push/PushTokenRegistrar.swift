import Foundation
import OSLog
import UIKit
import UserNotifications

@MainActor
final class PushTokenRegistrar {
    static let shared = PushTokenRegistrar()

    private let logger = Logger(subsystem: "fr.flipflapp.ios", category: "Push")
    private let tokenStore: any PushTokenStoring
    private var api: APIClient?

    init(tokenStore: any PushTokenStoring = UserDefaultsPushTokenStore()) {
        self.tokenStore = tokenStore
    }

    func configure(api: APIClient) {
        self.api = api
    }

    func storeDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        tokenStore.writeToken(token)
        Task { await registerStoredTokenIfPossible() }
    }

    func syncRegistration() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            guard granted else { return }
            await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
        case .authorized, .provisional, .ephemeral:
            await MainActor.run { UIApplication.shared.registerForRemoteNotifications() }
        default:
            break
        }
        await registerStoredTokenIfPossible()
    }

    func registerStoredTokenIfPossible() async {
        guard let api, let token = tokenStore.readToken(), !token.isEmpty else { return }
        do {
            try await api.registerDeviceToken(token: token, platform: "ios")
        } catch {
            logger.notice("Unable to register push token with API")
        }
    }

    func unregister() async {
        guard let api, let token = tokenStore.readToken(), !token.isEmpty else {
            tokenStore.deleteToken()
            return
        }
        do {
            try await api.unregisterDeviceToken(token: token)
        } catch {
            logger.notice("Remote push token deletion failed during sign-out")
        }
        tokenStore.deleteToken()
    }
}
