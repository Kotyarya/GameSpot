import Foundation
import Supabase

@MainActor
protocol GameInfoRealtimeSubscribing: AnyObject, Sendable {

    func subscribe(
        gameId: UUID,
        onChange: @escaping @MainActor @Sendable () async -> Void
    ) async throws

    func unsubscribe() async
}

@MainActor
final class SupabaseGameInfoRealtimeService: GameInfoRealtimeSubscribing {

    private let client: SupabaseClient
    private let channelSuffix: String
    private var channel: RealtimeChannelV2?
    private var subscriptions: [RealtimeSubscription] = []

    init(
        client: SupabaseClient = SupabaseService.shared.client,
        channelSuffix: String = UUID().uuidString
    ) {

        self.client = client
        self.channelSuffix = channelSuffix
    }

    func subscribe(
        gameId: UUID,
        onChange: @escaping @MainActor @Sendable () async -> Void
    ) async throws {

        await unsubscribe()

        let channel = client.realtimeV2.channel(
            "game-info-\(gameId.uuidString)-\(channelSuffix)"
        )

        subscriptions = [
            observe(
                channel: channel,
                table: "games",
                filter: "id=eq.\(gameId.uuidString)",
                onChange: onChange
            ),
            observe(
                channel: channel,
                table: "game_members",
                filter: "game_id=eq.\(gameId.uuidString)",
                onChange: onChange
            ),
            observe(
                channel: channel,
                table: "game_mvp_votes",
                filter: "game_id=eq.\(gameId.uuidString)",
                onChange: onChange
            )
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

    private func observe(
        channel: RealtimeChannelV2,
        table: String,
        filter: String,
        onChange: @escaping @MainActor @Sendable () async -> Void
    ) -> RealtimeSubscription {

        channel.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: table,
            filter: filter
        ) { _ in
            Task { @MainActor in
                await onChange()
            }
        }
    }
}
