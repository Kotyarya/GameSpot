import Foundation
import Supabase
import Combine

enum AppState {
    case auth
    case loading
    case loadError
    case onboarding
    case profileSetup
    case main
}

@MainActor
protocol SessionRefreshing: AnyObject {

    func refreshUser()
}

@MainActor
final class SessionManager: ObservableObject {

    // MARK: - State

    @Published var user: User?

    @Published var profile: Profile?

    @Published var isLoading = false

    @Published var error: String?

    @Published var didCheckSession = false

    @Published private(set) var authNotice: String?

    // MARK: - App State

    var appState: AppState {

        // MARK: Initial Launch

        if !didCheckSession {
            return .loading
        }

        // MARK: Auth

        if user == nil {
            return .auth
        }

        // MARK: Loading

        if isLoading {
            return .loading
        }

        // MARK: Error

        if error != nil {
            return .loadError
        }

        // MARK: Profile

        guard let profile else {
            return .loading
        }

        // MARK: Onboarding

        if !profile.isOnboarded {
            return .onboarding
        }

        // MARK: Profile Setup

        if !profile.isProfileCompleted {
            return .profileSetup
        }

        // MARK: Main

        return .main
    }

    // MARK: - Dependencies

    private let authService: any SessionAuthServing

    private let profileService: any ProfileFetching

    // MARK: - Init

    init(
        authService: any SessionAuthServing = AuthService.shared,
        profileService: any ProfileFetching = ProfileService.shared,
        restoreSessionOnInit: Bool = true
    ) {

        self.authService = authService
        self.profileService = profileService

        if restoreSessionOnInit {
            Task {
                await restoreSession()
            }
        }
    }

    // MARK: - Restore Session

    func restoreSession() async {

        isLoading = true

        defer {

            isLoading = false
            didCheckSession = true
        }

        user = authService.currentUser

        guard user != nil else {
            return
        }

        await loadProfile()
    }

    // MARK: - Refresh User

    func refreshUser() {

        user = authService.currentUser

        profile = nil

        error = nil

        Task {
            await loadProfile()
        }
    }

    // MARK: - Load Profile

    func loadProfile() async {

        guard let userId = user?.id else {
            return
        }

        isLoading = true

        error = nil

        defer {
            isLoading = false
        }

        do {

            let profile =
                try await profileService
                    .fetchProfile(
                        userId: userId
                    )

            self.profile = profile

        } catch {

            AppLogger.error(
                "Session profile load failed",
                error: error
            )

            self.error =
                "Couldn’t load your account. Check your connection and try again."

            self.profile = nil
        }
    }

    // MARK: - Sign Out

    func signOut() async {

        do {

            try await authService.signOut()

            self.user = nil

            self.profile = nil

        } catch {

            print(
                "❌ Sign out error:",
                error
            )
        }
    }

    // MARK: - Password Recovery

    func finishPasswordRecovery() async {
        await clearRecoverySession()
        authNotice = "Password updated. Sign in with your new password."
    }

    func cancelPasswordRecovery() async {
        await clearRecoverySession()
        authNotice = nil
    }

    func clearAuthNotice() {
        authNotice = nil
    }

    private func clearRecoverySession() async {
        do {
            try await authService.signOut()
        } catch {
            AppLogger.error(
                "Password recovery sign out failed",
                error: error
            )
        }

        user = nil
        profile = nil
        error = nil
        isLoading = false
        didCheckSession = true
    }

    // MARK: - Account Deletion

    func completeAccountDeletion() async {
        do {
            try await authService.signOut()
        } catch {
            // Supabase removes the local session before the remote logout request.
            AppLogger.error(
                "Post-deletion sign out failed",
                error: error
            )
        }

        user = nil
        profile = nil
        error = nil
        isLoading = false
        didCheckSession = true
    }
}

extension SessionManager: SessionRefreshing {}
