import Foundation
import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {

    // MARK: - State

    @Published var profile: Profile?

    @Published var stats: [UserSportStats] = []

    @Published var recentMatches: [RecentMatch] = []

    @Published var isLoading = true

    @Published var errorMessage: String?

    @Published var hasLoadedOnce = false

    @Published private(set) var isUpdatingAvatar = false

    @Published private(set) var avatarErrorMessage: String?

    // MARK: - Services

    private let service: any ProfileFetching

    private let realtime: any ProfileRealtimeSubscribing

    private let avatarStorage: any AvatarStoring

    private let avatarUpdater: any ProfileAvatarUpdating

    // MARK: - Properties

    private let minimumLoadingDuration: TimeInterval

    private var hasSubscribed = false

    // MARK: - Init

    init(
        service: any ProfileFetching = ProfileService.shared,
        realtime: any ProfileRealtimeSubscribing = SupabaseProfileRealtimeService(),
        avatarStorage: any AvatarStoring = SupabaseAvatarStorageService.shared,
        avatarUpdater: any ProfileAvatarUpdating = ProfileService.shared,
        minimumLoadingDuration: TimeInterval = 2.0
    ) {

        self.service = service
        self.realtime = realtime
        self.avatarStorage = avatarStorage
        self.avatarUpdater = avatarUpdater
        self.minimumLoadingDuration = minimumLoadingDuration
    }

    // MARK: - Avatar

    @discardableResult
    func replaceAvatar(
        with image: UIImage,
        userId: UUID
    ) async -> Bool {

        guard !isUpdatingAvatar else {
            return false
        }

        isUpdatingAvatar = true
        avatarErrorMessage = nil

        defer {
            isUpdatingAvatar = false
        }

        do {
            let url = try await avatarStorage.uploadAvatar(
                image,
                userId: userId
            )

            try await avatarUpdater.updateAvatar(
                userId: userId,
                avatarUrl: url.absoluteString
            )

            updateLocalAvatar(url.absoluteString)
            return true

        } catch {
            avatarErrorMessage =
                "Couldn’t update your photo. Please try again."

            AppLogger.error(
                "Avatar replacement failed",
                error: error
            )

            return false
        }
    }

    @discardableResult
    func removeAvatar(
        userId: UUID
    ) async -> Bool {

        guard !isUpdatingAvatar else {
            return false
        }

        isUpdatingAvatar = true
        avatarErrorMessage = nil

        defer {
            isUpdatingAvatar = false
        }

        do {
            try await avatarStorage.removeAvatar(userId: userId)

            try await avatarUpdater.updateAvatar(
                userId: userId,
                avatarUrl: nil
            )

            updateLocalAvatar(nil)
            return true

        } catch {
            avatarErrorMessage =
                "Couldn’t remove your photo. Please try again."

            AppLogger.error(
                "Avatar removal failed",
                error: error
            )

            return false
        }
    }

    func showAvatarSelectionError() {

        avatarErrorMessage = "Couldn’t load the selected photo."
    }

    private func updateLocalAvatar(
        _ avatarURL: String?
    ) {

        guard let profile else {
            return
        }

        self.profile = Profile(
            id: profile.id,
            username: profile.username,
            avatarUrl: avatarURL,
            favoriteSportId: profile.favoriteSportId,
            favoriteSport: profile.favoriteSport,
            rating: profile.rating,
            gamesPlayed: profile.gamesPlayed,
            mvpCount: profile.mvpCount,
            perfPoints: profile.perfPoints,
            isOnboarded: profile.isOnboarded,
            isProfileCompleted: profile.isProfileCompleted,
            createdAt: profile.createdAt,
            updatedAt: Date()
        )
    }

    // MARK: - Load

    func load(
        userId: UUID
    ) async {

        let startTime = Date()

        if hasLoadedOnce,
           !isLoading,
           profile?.id == userId {
            return
        }

        if !hasLoadedOnce {

            isLoading = true
        }

        errorMessage = nil

        do {

            async let profileTask =
                service.fetchProfile(
                    userId: userId
                )

            async let statsTask =
                service.fetchUserStats(
                    userId: userId
                )

            async let recentMatchesTask =
                service.getRecentMatches()

            profile = try await profileTask

            stats = try await statsTask

            recentMatches =
                try await recentMatchesTask

            try Task.checkCancellation()

            if !hasSubscribed {
                await subscribeToRealtime(
                    userId: userId
                )
            }

            try Task.checkCancellation()

            hasLoadedOnce = true

            let elapsed =
                Date().timeIntervalSince(startTime)

            if elapsed < minimumLoadingDuration {

                try? await Task.sleep(
                    for: .seconds(
                        minimumLoadingDuration - elapsed
                    )
                )
            }

            isLoading = false

            AppLogger.success(
                "ProfileViewModel loaded"
            )

        } catch {

            if !(error is CancellationError) {
                errorMessage =
                    "Couldn’t load your profile. Check your connection and try again."

                AppLogger.error(
                    "ProfileViewModel load failed",
                    error: error
                )
            }

            isLoading = false
        }
    }

    // MARK: - Realtime

    private func subscribeToRealtime(
        userId: UUID
    ) async {

        do {

            try await realtime.subscribe(
                userId: userId
            ) { [weak self] updatedProfile in

                guard let self else {
                    return
                }

                withAnimation(.spring) {
                    self.profile = updatedProfile
                }

                await self.reloadRecentMatches()

            } onStatsChange: { [weak self] in
                await self?.reloadStats(userId: userId)
            }

            hasSubscribed = true

            AppLogger.success(
                "Profile realtime connected"
            )

        } catch {

            if !(error is CancellationError) {
                AppLogger.error(
                    "Profile realtime subscribe failed",
                    error: error
                )
            }
        }
    }

    // MARK: - Reload

    private func reloadStats(
        userId: UUID
    ) async {

        do {

            let updatedStats =
                try await service
                    .fetchUserStats(
                        userId: userId
                    )

            withAnimation(.spring) {

                stats = updatedStats
            }

            await reloadRecentMatches()

            AppLogger.success(
                "Stats reloaded"
            )

        } catch {

            AppLogger.error(
                "Stats reload failed",
                error: error
            )
        }
    }

    private func reloadRecentMatches() async {

        do {

            let matches =
                try await service
                    .getRecentMatches()

            withAnimation(.spring) {

                recentMatches = matches
            }

        } catch {

            AppLogger.error(
                "Recent matches reload failed",
                error: error
            )
        }
    }

    // MARK: - Cleanup

    deinit {

        let realtime = realtime

        Task { @MainActor in

            await realtime.unsubscribe()
        }
    }
}
