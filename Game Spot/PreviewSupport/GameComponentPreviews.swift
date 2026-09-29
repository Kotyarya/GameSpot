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

#endif
