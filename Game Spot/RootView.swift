import SwiftUI
internal import Auth

struct RootView: View {
    
    @EnvironmentObject var session: SessionManager

    @EnvironmentObject var authLinks: AuthLinkCoordinator
    
    @State private var isCompleting = false
    
    // MARK: - Complete Onboarding
    
    func completeOnboarding() {
        
        guard !isCompleting else {
            return
        }
        
        guard let userId = session.user?.id else {
            return
        }
        
        isCompleting = true
        
        Task {
            
            let startTime = Date()
            
            try? await ProfileService.shared
                .markOnboardingComplete(
                    userId: userId
                )
            
            // MARK: - Minimum Loader Time
            
            let elapsed =
                Date().timeIntervalSince(startTime)
            
            let minimumDuration = 2.0
            
            if elapsed < minimumDuration {
                
                let remaining =
                    minimumDuration - elapsed
                
                try? await Task.sleep(
                    for: .seconds(remaining)
                )
            }
            
            await session.loadProfile()
            
            isCompleting = false
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        
        ZStack {

            if authLinks.isProcessing {

                LoadingView()
                    .transition(.opacity)

            } else if authLinks.showsPasswordRecovery {

                PasswordRecoveryView()
                    .transition(.opacity)

            } else {

                switch session.appState {

                case .auth:

                    AuthView()
                        .transition(.opacity)

                case .loading:

                    LoadingView()
                        .transition(.opacity)

                case .onboarding:

                    OnBoardingView {
                        completeOnboarding()
                    }
                    .transition(.opacity)

                case .profileSetup:

                    ProfileSetupView()
                        .transition(.opacity)

                case .main:

                    MainTabView()
                        .transition(.opacity)
                }
            }
        }
        .animation(
            .easeInOut(duration: 0.35),
            value: session.appState
        )
        .animation(
            .easeInOut(duration: 0.25),
            value: authLinks.state
        )
    }
}

#Preview {
    RootView()
        .environmentObject(
            SessionManager(restoreSessionOnInit: false)
        )
        .environmentObject(AuthLinkCoordinator())
}
