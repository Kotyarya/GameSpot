import Foundation
import SwiftUI
import Supabase
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

    // MARK: - Services

    private let service = ProfileService.shared

    // MARK: - Realtime

    private var realtimeChannel: RealtimeChannelV2?

    private var profileSubscription:
        RealtimeSubscription?

    private var statsSubscription:
        RealtimeSubscription?

    // MARK: - Properties

    private let minimumLoadingDuration = 2.0

    private var hasSubscribed = false

    // MARK: - Load

    func load(
        userId: UUID
    ) async {

        let startTime = Date()

        if !isLoading,
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

            if !hasSubscribed {

                hasSubscribed = true

                await subscribeToRealtime(
                    userId: userId
                )
            }

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

            errorMessage =
                error.localizedDescription

            isLoading = false

            AppLogger.error(
                "ProfileViewModel load failed",
                error: error
            )
        }
    }

    // MARK: - Realtime

    private func subscribeToRealtime(
        userId: UUID
    ) async {

        await realtimeChannel?
            .unsubscribe()

        realtimeChannel = SupabaseService
            .shared
            .client
            .realtimeV2
            .channel("profile-realtime")

        setupProfileSubscription(
            userId: userId
        )

        setupStatsSubscription(
            userId: userId
        )

        do {

            try await realtimeChannel?
                .subscribeWithError()

            AppLogger.success(
                "Profile realtime connected"
            )

        } catch {

            AppLogger.error(
                "Profile realtime subscribe failed",
                error: error
            )
        }
    }

    private func setupProfileSubscription(
        userId: UUID
    ) {

        profileSubscription =
        realtimeChannel?.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table: "profiles",
            filter: "id=eq.\(userId.uuidString)"
        ) { payload in

            AppLogger.info(
                "Profile realtime event"
            )

            Task { @MainActor [weak self] in

                guard let self else {
                    return
                }

                do {

                    let updatedProfile =
                        try self.decodeRecord(
                            payload.record,
                            as: Profile.self
                        )

                    guard updatedProfile.id == userId else {
                        return
                    }

                    withAnimation(.spring) {

                        self.profile = updatedProfile
                    }

                    await self.reloadRecentMatches()

                    AppLogger.success(
                        "Profile updated"
                    )

                } catch {

                    AppLogger.error(
                        "Profile decode failed",
                        error: error
                    )
                }
            }
        }
    }

    private func setupStatsSubscription(
        userId: UUID
    ) {

        statsSubscription =
        realtimeChannel?.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table: "user_sport_stats",
            filter: "user_id=eq.\(userId.uuidString)"
        ) { _ in

            AppLogger.info(
                "Stats realtime event"
            )

            Task { @MainActor [weak self] in

                await self?.reloadStats(
                    userId: userId
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

    // MARK: - Helpers

    private func decodeRecord<T: Decodable>(
        _ record: [String: AnyJSON],
        as type: T.Type
    ) throws -> T {

        let jsonObject = record.mapValues {
            $0.value
        }

        let data = try JSONSerialization
            .data(
                withJSONObject: jsonObject
            )

        let decoder = JSONDecoder()

        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(
            T.self,
            from: data
        )
    }

    // MARK: - Cleanup

    deinit {

        let channel = realtimeChannel

        Task { @MainActor in

            await channel?.unsubscribe()
        }
    }
}
