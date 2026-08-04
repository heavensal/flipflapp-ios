import SwiftUI

struct LoadStateView<Value, Content: View, EmptyActions: View>: View {
    let state: LoadState<Value>
    let isRefreshing: Bool
    let emptyTitle: LocalizedStringResource
    let emptyDescription: LocalizedStringResource
    let retry: () -> Void
    @ViewBuilder let content: (Value) -> Content
    @ViewBuilder let emptyActions: () -> EmptyActions

    init(
        state: LoadState<Value>,
        isRefreshing: Bool = false,
        emptyTitle: LocalizedStringResource,
        emptyDescription: LocalizedStringResource,
        retry: @escaping () -> Void,
        @ViewBuilder content: @escaping (Value) -> Content,
        @ViewBuilder emptyActions: @escaping () -> EmptyActions
    ) {
        self.state = state
        self.isRefreshing = isRefreshing
        self.emptyTitle = emptyTitle
        self.emptyDescription = emptyDescription
        self.retry = retry
        self.content = content
        self.emptyActions = emptyActions
    }

    var body: some View {
        if let value = state.loadedValue {
            refreshingContent(value)
        } else {
            switch state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(String(localized: "Loading"))
            case .empty:
                ContentUnavailableView {
                    Label(emptyTitle, systemImage: "sparkles")
                } description: {
                    Text(emptyDescription)
                } actions: {
                    emptyActions()
                }
            case let .failed(error):
                ContentUnavailableView {
                    Label(String(localized: "Unable to load"), systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button(String(localized: "Try again"), action: retry)
                        .buttonStyle(.borderedProminent)
                }
            case .loaded:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private func refreshingContent(_ value: Value) -> some View {
        content(value)
            .overlay(alignment: .top) {
                if isRefreshing {
                    ProgressView()
                        .padding(8)
                        .background(.bar, in: Capsule())
                        .padding(.top, 8)
                }
            }
    }
}

extension LoadStateView where EmptyActions == EmptyView {
    init(
        state: LoadState<Value>,
        isRefreshing: Bool = false,
        emptyTitle: LocalizedStringResource,
        emptyDescription: LocalizedStringResource,
        retry: @escaping () -> Void,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.init(
            state: state,
            isRefreshing: isRefreshing,
            emptyTitle: emptyTitle,
            emptyDescription: emptyDescription,
            retry: retry,
            content: content,
            emptyActions: { EmptyView() }
        )
    }
}
