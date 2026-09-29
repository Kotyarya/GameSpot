#if DEBUG

import SwiftUI

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

#endif
