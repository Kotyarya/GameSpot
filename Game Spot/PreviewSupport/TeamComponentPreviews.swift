#if DEBUG

import SwiftUI

#Preview("Team Section") {
    TeamSectionView(
        title: "Team Alpha",
        players: [PreviewFixtures.currentPlayer],
        team: .alpha,
        limit: 5,
        currentUserId: PreviewFixtures.userID,
        isJoined: true,
        isSubmitting: false,
        onJoin: { _ in },
        onLeave: {}
    )
    .padding()
}

#Preview("Player Slot") {
    PlayerSlotRow(
        player: PreviewFixtures.currentPlayer,
        currentUserId: PreviewFixtures.userID,
        disabled: false,
        onLeave: {}
    )
    .padding()
}

#Preview("Empty Slot") {
    EmptySlotRow(
        team: .beta,
        slotIndex: 2,
        disabled: false,
        onJoin: { _ in }
    )
    .padding()
}

#Preview("MVP Vote Row") {
    MVPVoteRow(
        player: PreviewFixtures.secondPlayer,
        isCurrentUser: false,
        disabled: false,
        isSelected: true,
        votesCount: 2,
        onVote: {}
    )
    .padding()
}

#endif
