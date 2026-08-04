import Foundation

protocol PushTokenStoring: Sendable {
    func readToken() -> String?
    func writeToken(_ token: String)
    func deleteToken()
}

struct UserDefaultsPushTokenStore: PushTokenStoring {
    private let defaults: UserDefaults
    private let key = "fr.flipflapp.ios.push-token"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func readToken() -> String? {
        defaults.string(forKey: key)
    }

    func writeToken(_ token: String) {
        defaults.set(token, forKey: key)
    }

    func deleteToken() {
        defaults.removeObject(forKey: key)
    }
}
