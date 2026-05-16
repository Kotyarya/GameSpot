import Foundation
import Supabase

final class GameService: @unchecked Sendable {

    // MARK: - Shared

    static let shared = GameService()

    // MARK: - Properties

    private let client = SupabaseService.shared.client

    // MARK: - Games

    func fetchGamesByPark(
        parkId: UUID
    ) async throws -> [Game] {

        let params = FetchGamesByParkParams(
            p_park_id: parkId
        )

        return try await client
            .rpc(
                "get_games_by_park",
                params: params
            )
            .execute()
            .value
    }

    func fetchUserGames() async throws -> [Game] {

        return try await client
            .rpc("get_user_games")
            .execute()
            .value
    }

    func fetchGameDetails(
        gameId: UUID
    ) async throws -> GameDetails {

        let params = FetchGameDetailsParams(
            p_game_id: gameId
        )

        return try await client
            .rpc(
                "get_game_details",
                params: params
            )
            .single()
            .execute()
            .value
    }

    // MARK: - Create Game

    func createGame(
        parkId: UUID,
        sportId: UUID,
        startsAt: Date
    ) async throws -> UUID {

        let formatter = ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        let params = CreateGameParams(
            p_park_id: parkId,
            p_sport_id: sportId,
            p_starts_at: formatter.string(from: startsAt)
        )

        return try await client
            .rpc(
                "create_game",
                params: params
            )
            .execute()
            .value
    }

    // MARK: - Join Game

    func joinGame(
        gameId: UUID,
        team: Team
    ) async throws {

        let params = JoinGameParams(
            p_game_id: gameId,
            p_team: team
        )

        try await client
            .rpc(
                "join_game",
                params: params
            )
            .execute()
    }

    // MARK: - Leave Game

    func leaveGame(
        gameId: UUID
    ) async throws {

        let params = LeaveGameParams(
            p_game_id: gameId
        )

        try await client
            .rpc(
                "leave_game",
                params: params
            )
            .execute()
    }

    // MARK: - MVP Voting

    func voteMVP(
        gameId: UUID,
        votedUserId: UUID
    ) async throws {

        let params = VoteMVPParams(
            p_game_id: gameId,
            p_voted_user_id: votedUserId
        )

        try await client
            .rpc(
                "vote_mvp",
                params: params
            )
            .execute()
    }
}

// MARK: - DTOs

private extension GameService {

    struct FetchGamesByParkParams: Encodable {

        let p_park_id: UUID
    }

    struct FetchGameDetailsParams: Encodable {

        let p_game_id: UUID
    }

    struct CreateGameParams: Encodable {

        let p_park_id: UUID
        let p_sport_id: UUID
        let p_starts_at: String
    }

    struct JoinGameParams: Encodable {

        let p_game_id: UUID
        let p_team: Team
    }

    struct LeaveGameParams: Encodable {

        let p_game_id: UUID
    }

    struct VoteMVPParams: Encodable {

        let p_game_id: UUID
        let p_voted_user_id: UUID
    }
}
