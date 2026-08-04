enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(APIError)

    var hasContent: Bool {
        if case .loaded = self { return true }
        return false
    }

    var loadedValue: Value? {
        if case let .loaded(value) = self { return value }
        return nil
    }
}
