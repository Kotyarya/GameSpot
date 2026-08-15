import Foundation
import Supabase

@MainActor
protocol GamesRealtimeSubscribing: AnyObject, Sendable {

    func subscribe(
        onChange: @escaping @MainActor @Sendable () async -> Void
    ) async throws

    func unsubscribe() async
}

@MainActor
final class SupabaseGamesRealtimeService:
    GamesRealtimeSubscribing {

    private let client: SupabaseClient
    private let channelName: String

    private var channel: RealtimeChannelV2?
    private var gamesSubscription: RealtimeSubscription?
    private var membersSubscription: RealtimeSubscription?

    init(
        client: SupabaseClient = SupabaseService.shared.client,
        channelName: String = "games-list-\(UUID().uuidString)"
    ) {
        self.client = client
        self.channelName = channelName
    }

    func subscribe(
        onChange: @escaping @MainActor @Sendable () async -> Void
    ) async throws {
        await unsubscribe()

        let channel = client
            .realtimeV2
            .channel(channelName)

        gamesSubscription = channel.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "games"
        ) { _ in
            Task { @MainActor in
                await onChange()
            }
        }

        membersSubscription = channel.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "game_members"
        ) { _ in
            Task { @MainActor in
                await onChange()
            }
        }

        self.channel = channel

        do {
            try await channel.subscribeWithError()
        } catch {
            await unsubscribe()
            throw error
        }
    }

    func unsubscribe() async {
        gamesSubscription?.cancel()
        membersSubscription?.cancel()

        gamesSubscription = nil
        membersSubscription = nil

        guard let channel else {
            return
        }

        self.channel = nil
        await client.removeChannel(channel)
    }
}
