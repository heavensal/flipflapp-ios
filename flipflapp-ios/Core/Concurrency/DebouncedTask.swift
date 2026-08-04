import Foundation

@MainActor
final class DebouncedTask {
    private var task: Task<Void, Never>?

    func schedule(delay: Duration = .milliseconds(300), operation: @escaping @Sendable () async -> Void) {
        task?.cancel()
        task = Task {
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await operation()
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
