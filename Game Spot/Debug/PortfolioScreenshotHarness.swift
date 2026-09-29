#if DEBUG

import SwiftUI

enum PortfolioScreenshotScreen: String {
    case games
    case game
    case profile
    case settings

    static var current: PortfolioScreenshotScreen? {
        let prefix = "--portfolio-screen="

        guard let argument = ProcessInfo.processInfo.arguments.first(
            where: { $0.hasPrefix(prefix) }
        ) else {
            return nil
        }

        return PortfolioScreenshotScreen(
            rawValue: String(argument.dropFirst(prefix.count))
        )
    }
}

@MainActor
struct PortfolioScreenshotHarness: View {
    let screen: PortfolioScreenshotScreen

    var body: some View {
        switch screen {
        case .games:
            NavigationStack {
                GamesView(
                    mode: .myGames,
                    viewModel: PreviewFactory.games()
                )
            }
            .environmentObject(AppRouter())

        case .game:
            NavigationStack {
                GameInfoView(
                    gameId: PreviewFixtures.gameID,
                    viewModel: PreviewFactory.gameInfo(),
                    userSafetyService: PreviewSafetyService()
                )
            }
            .environmentObject(PreviewFactory.session())

        case .profile:
            NavigationStack {
                ProfileView(viewModel: PreviewFactory.profile())
            }
            .environmentObject(PreviewFactory.session())

        case .settings:
            NavigationStack {
                SettingsView(
                    accountDeletionViewModel: AccountDeletionViewModel(
                        service: PreviewAccountDeletionService()
                    )
                )
            }
            .environmentObject(PreviewFactory.session())
        }
    }
}

#endif
