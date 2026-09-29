#if DEBUG

import SwiftUI

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

#endif
