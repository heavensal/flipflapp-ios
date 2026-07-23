import SwiftUI

struct FriendshipRow: View {
    let friendship: Friendship
    let currentUserID: UserID
    let isWorking: Bool
    let primaryAction: (() -> Void)?
    let secondaryAction: (() -> Void)?
    let primaryTitle: LocalizedStringResource?
    let secondaryTitle: LocalizedStringResource?

    private var user: PublicUser {
        friendship.otherUser(relativeTo: currentUserID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: user.id) {
                UserRow(user: user) {
                    if isWorking { ProgressView().controlSize(.small) }
                }
            }
            .buttonStyle(.plain)

            if primaryAction != nil || secondaryAction != nil {
                HStack {
                    if let secondaryAction, let secondaryTitle {
                        Button(secondaryTitle, action: secondaryAction)
                            .buttonStyle(.bordered)
                    }
                    if let primaryAction, let primaryTitle {
                        Button(primaryTitle, action: primaryAction)
                            .buttonStyle(.borderedProminent)
                    }
                }
                .disabled(isWorking)
            }
        }
        .padding(.vertical, 4)
    }
}
