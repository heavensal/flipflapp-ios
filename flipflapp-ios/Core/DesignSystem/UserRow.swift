import SwiftUI

struct UserRow<Trailing: View>: View {
    let user: PublicUser
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(user: user)
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.body.weight(.semibold))
                if let username = user.username {
                    Text(username)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .contentShape(.rect)
    }
}

extension UserRow where Trailing == EmptyView {
    init(user: PublicUser) {
        self.init(user: user, trailing: { EmptyView() })
    }
}
