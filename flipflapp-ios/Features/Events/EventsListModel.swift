import Foundation
import Observation

@MainActor
@Observable
final class EventsListModel {
    private(set) var state: LoadState<[Event]> = .idle
    private(set) var isRefreshing = false
    var refreshErrorMessage: String?

    private let api: APIClient
    private let session: SessionStore

    init(api: APIClient, session: SessionStore) {
        self.api = api
        self.session = session
    }

    func load() async {
        guard case .idle = state else { return }
        state = .loading
        await fetch(replacingContent: true)
    }

    func retry() async {
        refreshErrorMessage = nil
        if state.hasContent {
            isRefreshing = true
            defer { isRefreshing = false }
            await fetch(replacingContent: false)
        } else {
            state = .loading
            await fetch(replacingContent: true)
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        refreshErrorMessage = nil
        defer { isRefreshing = false }
        await fetch(replacingContent: false)
    }

    private func fetch(replacingContent: Bool) async {
        do {
            let events = try await api.events()
            state = events.isEmpty ? .empty : .loaded(events)
        } catch let error as APIError {
            await session.handleAPIError(error)
            if case .cancelled = error { return }
            if replacingContent {
                state = .failed(error)
            } else {
                refreshErrorMessage = error.localizedDescription
            }
        } catch {
            let apiError = APIError.invalidResponse
            if replacingContent {
                state = .failed(apiError)
            } else {
                refreshErrorMessage = apiError.localizedDescription
            }
        }
    }
}
