import SwiftUI

struct LoadStateView<Value, Content: View, EmptyActions: View>: View {
    let state: LoadState<Value>
    let emptyTitle: LocalizedStringResource
    let emptyDescription: LocalizedStringResource
    let retry: () -> Void
    @ViewBuilder let content: (Value) -> Content
    @ViewBuilder let emptyActions: () -> EmptyActions

    var body: some View {
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
        case let .loaded(value):
            content(value)
        }
    }
}

extension LoadStateView where EmptyActions == EmptyView {
    init(
        state: LoadState<Value>,
        emptyTitle: LocalizedStringResource,
        emptyDescription: LocalizedStringResource,
        retry: @escaping () -> Void,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.init(
            state: state,
            emptyTitle: emptyTitle,
            emptyDescription: emptyDescription,
            retry: retry,
            content: content,
            emptyActions: { EmptyView() }
        )
    }
}
