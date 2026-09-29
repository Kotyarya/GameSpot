import Foundation
import Combine

@MainActor
final class PublicProfileViewModel: ObservableObject {

    @Published private(set) var profile: Profile?
    @Published private(set) var stats: [UserSportStats] = []
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    private let service: any ProfileFetching
    private var hasStartedLoading = false

    init(
        service: any ProfileFetching = ProfileService.shared
    ) {
        self.service = service
    }

    func load(
        userId: UUID
    ) async {

        if profile != nil {
            return
        }

        if hasStartedLoading,
           isLoading {
            return
        }

        hasStartedLoading = true
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            async let profileTask =
                service.fetchProfile(userId: userId)

            async let statsTask =
                service.fetchUserStats(userId: userId)

            let loadedProfile = try await profileTask
            let loadedStats = try await statsTask

            profile = loadedProfile
            stats = loadedStats

        } catch {
            AppLogger.error(
                "PublicProfileViewModel load failed",
                error: error
            )

            errorMessage =
                "Couldn’t load this player’s profile. Please try again."
        }
    }
}
