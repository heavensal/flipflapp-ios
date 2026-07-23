import Foundation
import Observation

@MainActor
@Observable
final class AppContainer {
    enum State {
        case idle
        case ready(AppEnvironment, SessionStore)
        case failed(String)
    }

    private(set) var state: State = .idle

    func start() async {
        guard case .idle = state else { return }

        do {
            let configuration = try APIConfiguration()
            let tokenStore = KeychainTokenStore()
            let api = APIClient(configuration: configuration, tokenStore: tokenStore)
            let environment = AppEnvironment(api: api, tokenStore: tokenStore)
            let session = SessionStore(api: api, tokenStore: tokenStore)
            state = .ready(environment, session)
            await session.restore()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
