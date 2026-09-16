#if DEBUG

import SwiftUI

@MainActor
private struct ParkInfoPreviewHost: View {
    @State private var selectedPark: Park? = PreviewFixtures.park
    @State private var detent: PresentationDetent = .height(350)
    @StateObject private var viewModel = PreviewFactory.parkDetails()

    var body: some View {
        ParkInfoView(
            selectedPark: $selectedPark,
            selectedDetent: $detent,
            viewModel: viewModel
        )
        .environmentObject(PreviewFactory.session())
        .environmentObject(AppRouter())
        .frame(height: 700)
    }
}

#Preview("Root · Signed Out") {
    RootView()
        .environmentObject(PreviewFactory.session(signedIn: false))
        .environmentObject(AuthLinkCoordinator())
}

#Preview("Authentication") {
    AuthView(
        viewModel: AuthViewModel(service: PreviewAuthService())
    )
    .environmentObject(PreviewFactory.session(signedIn: false))
    .environmentObject(AuthLinkCoordinator())
}

#Preview("Password Reset Request") {
    PasswordResetRequestView(
        initialEmail: "preview@gamespot.local",
        service: PreviewAuthService()
    )
}

#Preview("Password Recovery") {
    PasswordRecoveryView(service: PreviewAuthService())
        .environmentObject(PreviewFactory.session())
        .environmentObject(
            AuthLinkCoordinator(initialState: .passwordRecovery)
        )
}

#Preview("Onboarding") {
    OnBoardingView()
}

#Preview("Profile Setup") {
    ProfileSetupView(viewModel: PreviewFactory.profileSetup())
        .environmentObject(PreviewFactory.session(profile: nil))
}

#Preview("Main Tabs") {
    MainTabView(
        mapViewModel: PreviewFactory.map(),
        parkViewModel: PreviewFactory.parkDetails(),
        gamesViewModel: PreviewFactory.games(),
        profileViewModel: PreviewFactory.profile()
    )
    .environmentObject(AppRouter())
    .environmentObject(PreviewFactory.session())
}

#Preview("Map · Loaded") {
    MapView(
        viewModel: PreviewFactory.map(),
        parkViewModel: PreviewFactory.parkDetails()
    )
    .environmentObject(AppRouter())
    .environmentObject(PreviewFactory.session())
}

#Preview("Map · Empty") {
    MapView(
        viewModel: PreviewFactory.map(parks: .success([])),
        parkViewModel: PreviewFactory.parkDetails()
    )
    .environmentObject(AppRouter())
    .environmentObject(PreviewFactory.session())
}

#Preview("Map · Error") {
    MapView(
        viewModel: PreviewFactory.map(parks: .failure(PreviewFailure.offline)),
        parkViewModel: PreviewFactory.parkDetails()
    )
    .environmentObject(AppRouter())
    .environmentObject(PreviewFactory.session())
}

#Preview("Park Details") {
    ParkInfoPreviewHost()
}

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

#Preview("Profile · Loaded") {
    NavigationStack {
        ProfileView(viewModel: PreviewFactory.profile())
    }
    .environmentObject(PreviewFactory.session())
}

#Preview("Profile · Error") {
    NavigationStack {
        ProfileView(
            viewModel: PreviewFactory.profile(
                service: PreviewProfileService(
                    profileResult: .failure(PreviewFailure.offline),
                    statsResult: .failure(PreviewFailure.offline),
                    recentMatchesResult: .failure(PreviewFailure.offline)
                )
            )
        )
    }
    .environmentObject(PreviewFactory.session())
}

#Preview("Public Profile") {
    NavigationStack {
        PublicProfileView(
            profile: PreviewFixtures.publicSummary,
            profileViewModel: PreviewFactory.publicProfile(),
            safetyViewModel: UserSafetyViewModel(
                service: PreviewSafetyService()
            )
        )
    }
}

#Preview("Settings") {
    NavigationStack {
        SettingsView(
            accountDeletionViewModel: AccountDeletionViewModel(
                service: PreviewAccountDeletionService()
            )
        )
    }
    .environmentObject(PreviewFactory.session())
}

#Preview("Blocked Users · Loaded") {
    NavigationStack {
        BlockedUsersView(viewModel: PreviewFactory.blockedUsers())
    }
}

#Preview("Blocked Users · Empty") {
    NavigationStack {
        BlockedUsersView(
            viewModel: PreviewFactory.blockedUsers(result: .success([]))
        )
    }
}

#Preview("Privacy Policy") {
    NavigationStack {
        PrivacyPolicyView()
    }
}

#Preview("State · Error") {
    ContentStateView(
        title: "Couldn’t Load Games",
        message: "Check your connection and try again.",
        systemImage: "wifi.exclamationmark",
        accessibilityIdentifier: "preview.error",
        actionTitle: "Try Again"
    ) {}
}

#Preview("State · Empty") {
    ContentStateView(
        title: "No Games Yet",
        message: "Games you join or create will appear here.",
        systemImage: "sportscourt",
        accessibilityIdentifier: "preview.empty"
    )
}

#Preview("Loading · Branded") {
    LoadingView()
}

#Preview("Loading · Native") {
    NativeLoadingView(title: "Loading Profile")
}

#endif
