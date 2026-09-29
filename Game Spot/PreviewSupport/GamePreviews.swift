#if DEBUG

import SwiftUI

#Preview("Games · Loaded") {
    NavigationStack {
        GamesView(
            mode: .myGames,
            viewModel: PreviewFactory.games()
        )
    }
    .environmentObject(AppRouter())
}

#Preview("Games · Empty") {
    NavigationStack {
        GamesView(
            mode: .myGames,
            viewModel: PreviewFactory.games(result: .success([]))
        )
    }
    .environmentObject(AppRouter())
}

#Preview("Games · Error") {
    NavigationStack {
        GamesView(
            mode: .myGames,
            viewModel: PreviewFactory.games(
                result: .failure(PreviewFailure.offline)
            )
        )
    }
    .environmentObject(AppRouter())
}

#Preview("Create Game") {
    NavigationStack {
        CreateGameView(
            park: PreviewFixtures.park,
            sports: PreviewFixtures.sports,
            viewModel: PreviewFactory.createGame()
        )
    }
    .environmentObject(AppRouter())
}

#Preview("Game Details") {
    NavigationStack {
        GameInfoView(
            gameId: PreviewFixtures.gameID,
            viewModel: PreviewFactory.gameInfo(),
            userSafetyService: PreviewSafetyService()
        )
    }
    .environmentObject(PreviewFactory.session())
}

#Preview("Join Game") {
    JoinGameSheetView(
        details: PreviewFixtures.gameDetails,
        currentUserId: PreviewFixtures.userID,
        onJoin: { _ in },
        onLeave: {}
    )
}

#endif
