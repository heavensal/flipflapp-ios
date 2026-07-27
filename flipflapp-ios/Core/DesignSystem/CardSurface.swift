import SwiftUI

struct CardSurface<Content: View>: View {
    private let tint: Color?
    private let content: Content

    init(tint: Color? = nil, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.regularMaterial)
                if let tint {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(tint.opacity(0.14))
                }
            }
            .overlay {
                if let tint {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(tint.opacity(0.45), lineWidth: 0.5)
                } else {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(.separator.opacity(0.35), lineWidth: 0.5)
                }
            }
    }
}
