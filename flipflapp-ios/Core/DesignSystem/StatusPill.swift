import SwiftUI

struct StatusPill: View {
    let title: LocalizedStringResource
    let systemImage: String
    var tint: Color = .indigo

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: .capsule)
    }
}
