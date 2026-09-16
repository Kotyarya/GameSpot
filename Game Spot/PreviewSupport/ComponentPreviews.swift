#if DEBUG

import SwiftUI

#Preview("Game Card · Upcoming") {
    GameCard(game: PreviewFixtures.upcomingGame)
        .environmentObject(AppRouter())
        .padding()
}

#Preview("Game Card · Finished") {
    GameCard(game: PreviewFixtures.finishedGame)
        .environmentObject(AppRouter())
        .padding()
}

#Preview("Sport Pin") {
    SportGlassPin(
        sport: PreviewFixtures.football,
        tint: Color("AccentColor")
    )
    .padding(40)
}

#Preview("Rank Badges") {
    RankBadgesShowcaseView()
}

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

#Preview("Profile Avatar") {
    ProfileAvatarView(
        username: PreviewFixtures.profile.username ?? "Player",
        avatarURL: nil,
        rank: RankHelper.getRank(rating: PreviewFixtures.profile.rating)
    )
    .padding()
}

#Preview("Profile Hero") {
    ProfileHeroView(
        username: PreviewFixtures.profile.username ?? "Player",
        rating: PreviewFixtures.profile.rating,
        favoriteSportIcon: PreviewFixtures.football.type?.iconName ?? "sportscourt"
    ) {
        ProfileAvatarView(
            username: PreviewFixtures.profile.username ?? "Player",
            avatarURL: nil,
            rank: RankHelper.getRank(rating: PreviewFixtures.profile.rating)
        )
    }
    .padding()
}

#Preview("Profile Summary") {
    ProfileSummaryCard(
        rating: PreviewFixtures.profile.rating,
        gamesPlayed: PreviewFixtures.profile.gamesPlayed,
        mvpCount: PreviewFixtures.profile.mvpCount,
        perfPoints: PreviewFixtures.profile.perfPoints
    )
    .padding()
}

#Preview("Sport Stats") {
    ScrollView {
        ProfileSportStatsSection(stats: PreviewFixtures.stats)
            .padding()
    }
}

#Preview("Pattern Background") {
    PatternBackground(
        symbol: "soccerball",
        color: .purple,
        opacity: 0.18
    )
}

#Preview("Recent Match") {
    RecentMatchCard(match: PreviewFixtures.recentMatches[0])
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
