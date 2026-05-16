import Foundation
import Supabase
import Combine

enum AppState {
    case auth
    case loading
    case onboarding
    case profileSetup
    case main
}

@MainActor
final class SessionManager: ObservableObject {

    // MARK: - State

    @Published var user: User?

    @Published var profile: Profile?

    @Published var isLoading = false

    @Published var error: String?

    @Published var didCheckSession = false

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
            return .auth
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

    private let client =
        SupabaseService.shared.client

    // MARK: - Init

    init() {

        Task {
            await restoreSession()
        }
    }

    // MARK: - Restore Session

    func restoreSession() async {

        isLoading = true

        defer {

            isLoading = false
            didCheckSession = true
        }

        user = client.auth.currentUser

        guard user != nil else {
            return
        }

        await loadProfile()
    }

    // MARK: - Refresh User

    func refreshUser() {

        user = client.auth.currentUser

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
                try await ProfileService.shared
                    .fetchProfile(
                        userId: userId
                    )

            self.profile = profile

        } catch {

            print(
                "❌ Failed to load profile:",
                error
            )

            self.error =
                error.localizedDescription

            self.profile = nil
        }
    }

    // MARK: - Sign Out

    func signOut() async {

        do {

            try await AuthService.shared
                .signOut()

            self.user = nil

            self.profile = nil

        } catch {

            print(
                "❌ Sign out error:",
                error
            )
        }
    }
}
