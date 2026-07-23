import SwiftUI

struct ProgressButtonLabel: View {
    let title: LocalizedStringResource
    let systemImage: String
    let isWorking: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isWorking {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: systemImage)
            }
            Text(title)
        }
        .frame(maxWidth: .infinity)
    }
}
