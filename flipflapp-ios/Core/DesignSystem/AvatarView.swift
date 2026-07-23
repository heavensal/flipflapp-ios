import SwiftUI

struct AvatarView: View {
    let user: PublicUser
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let avatarURL = user.avatarURL {
                AsyncImage(url: avatarURL) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    default:
                        initials
                    }
                }
            } else {
                initials
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .overlay {
            Circle().stroke(.separator.opacity(0.5), lineWidth: 0.5)
        }
        .accessibilityHidden(true)
    }

    private var initials: some View {
        ZStack {
            Color.indigo.opacity(0.15)
            Text(initialsText)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(.indigo)
        }
    }

    private var initialsText: String {
        let characters = [user.firstName, user.lastName]
            .compactMap { $0?.first }
            .prefix(2)
        let value = String(characters)
        return value.isEmpty ? "?" : value.uppercased()
    }
}
