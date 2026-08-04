import Foundation

enum AppDeepLink: Equatable {
    case confirmAccount(token: String)
    case resetPassword(token: String)

    static func parse(url: URL) -> AppDeepLink? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        let items: [String: String] = Dictionary(
            uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
                guard let value = item.value else { return nil }
                return (item.name, value)
            }
        )

        if let token = items["confirmation_token"], !token.isEmpty {
            return .confirmAccount(token: token)
        }
        if let token = items["reset_password_token"], !token.isEmpty {
            return .resetPassword(token: token)
        }
        return nil
    }
}

@MainActor
@Observable
final class AppDeepLinkRouter {
    private(set) var pending: AppDeepLink?

    func handle(url: URL) {
        pending = AppDeepLink.parse(url: url)
    }

    func consume() -> AppDeepLink? {
        defer { pending = nil }
        return pending
    }
}
