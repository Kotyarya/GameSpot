#if DEBUG

import SwiftUI

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

#Preview("Recent Match") {
    RecentMatchCard(match: PreviewFixtures.recentMatches[0])
        .padding()
}

#endif
