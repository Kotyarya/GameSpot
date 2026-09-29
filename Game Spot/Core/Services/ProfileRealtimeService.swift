import Foundation
import Supabase

@MainActor
protocol ProfileRealtimeSubscribing: AnyObject, Sendable {

    func subscribe(
        userId: UUID,
        onProfileChange: @escaping @MainActor @Sendable (Profile) async -> Void,
        onStatsChange: @escaping @MainActor @Sendable () async -> Void
    ) async throws

    func unsubscribe() async
}

@MainActor
final class SupabaseProfileRealtimeService: ProfileRealtimeSubscribing {

    private let client: SupabaseClient
    private let channelName: String
    private var channel: RealtimeChannelV2?
    private var subscriptions: [RealtimeSubscription] = []

    init(
        client: SupabaseClient = SupabaseService.shared.client,
        channelName: String = "profile-realtime-\(UUID().uuidString)"
    ) {

        self.client = client
        self.channelName = channelName
    }

    func subscribe(
        userId: UUID,
        onProfileChange: @escaping @MainActor @Sendable (Profile) async -> Void,
        onStatsChange: @escaping @MainActor @Sendable () async -> Void
    ) async throws {

        await unsubscribe()

        let channel = client.realtimeV2.channel(channelName)

        let profileSubscription = channel.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table: "profiles",
            filter: "id=eq.\(userId.uuidString)"
        ) { payload in
            do {
                let profile = try Self.decodeProfile(payload.record)

                guard profile.id == userId else {
                    return
                }

                Task { @MainActor in
                    await onProfileChange(profile)
                }
            } catch {
                AppLogger.error(
                    "Profile realtime decode failed",
                    error: error
                )
            }
        }

        let statsSubscription = channel.onPostgresChange(
            UpdateAction.self,
            schema: "public",
            table: "user_sport_stats",
            filter: "user_id=eq.\(userId.uuidString)"
        ) { _ in
            Task { @MainActor in
                await onStatsChange()
            }
        }

        subscriptions = [
            profileSubscription,
            statsSubscription
        ]
        self.channel = channel

        do {
            try await channel.subscribeWithError()
        } catch {
            await unsubscribe()
            throw error
        }
    }

    func unsubscribe() async {
        subscriptions.forEach { $0.cancel() }
        subscriptions = []

        guard let channel else {
            return
        }

        self.channel = nil
        await client.removeChannel(channel)
    }

    nonisolated private static func decodeProfile(
        _ record: [String: AnyJSON]
    ) throws -> Profile {

        let data = try JSONSerialization.data(
            withJSONObject: record.mapValues(\.value)
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Profile.self, from: data)
    }
}
