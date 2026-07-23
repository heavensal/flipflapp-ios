import Foundation

nonisolated struct APIConfiguration: Sendable {
    let baseURL: URL

    init(bundle: Bundle = .main) throws {
        #if DEBUG
        let environmentValue = ProcessInfo.processInfo.environment["FLIPFLAPP_API_BASE_URL"]
        #else
        let environmentValue: String? = nil
        #endif
        let configuredValue = environmentValue
            ?? bundle.object(forInfoDictionaryKey: "FLIPFLAPP_API_BASE_URL") as? String
        let rawValue = configuredValue ?? "https://flipflapp.fr"

        guard
            let components = URLComponents(string: rawValue),
            let scheme = components.scheme?.lowercased(),
            ["https", "http"].contains(scheme),
            components.host != nil,
            let url = components.url
        else {
            throw APIConfigurationError.invalidBaseURL
        }

        #if !DEBUG
        guard scheme == "https" else {
            throw APIConfigurationError.insecureProductionURL
        }
        #endif

        baseURL = url
    }
}

nonisolated enum APIConfigurationError: LocalizedError {
    case invalidBaseURL
    case insecureProductionURL

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            String(localized: "The API address is invalid.")
        case .insecureProductionURL:
            String(localized: "The production API must use HTTPS.")
        }
    }
}
