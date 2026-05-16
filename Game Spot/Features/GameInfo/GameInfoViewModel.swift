import Foundation
import Combine
import Supabase
import SwiftUI

@MainActor
final class GameInfoViewModel: ObservableObject {
    
    // MARK: - State
    
    @Published var details: GameDetails?
    
    @Published var weather: Weather?
    
    @Published var isLoading = false
    
    @Published var errorMessage: String?
    
    @Published var isSubmittingVote = false
    
    // MARK: - Services
    
    private let gameService =
        GameService.shared
    
    private let weatherService =
        WeatherService.shared
    
    // MARK: - Realtime
    
    private var realtimeChannel:
        RealtimeChannelV2?
    
    private var gamesSubscription:
        RealtimeSubscription?
    
    private var membersSubscription:
        RealtimeSubscription?
    
    private var votesSubscription:
        RealtimeSubscription?
    
    // MARK: - Properties
    
    private var subscribedGameId: UUID?
    
    // MARK: - Load
    
    func load(
        gameId: UUID
    ) async {
        
        isLoading = true
        
        errorMessage = nil
        
        do {
            
            try await loadGameDetails(
                gameId: gameId
            )
            
            try await loadWeather()
            
            await setupRealtimeIfNeeded(
                gameId: gameId
            )
            
        } catch {
            
            if error is CancellationError {
                return
            }
            
            errorMessage =
                error.localizedDescription
            
            AppLogger.error(
                "GameInfoViewModel load failed",
                error: error
            )
        }
        
        isLoading = false
    }
    
    // MARK: - Load Details
    
    private func loadGameDetails(
        gameId: UUID
    ) async throws {
        
        details =
            try await gameService
                .fetchGameDetails(
                    gameId: gameId
                )
    }
    
    // MARK: - Load Weather
    
    private func loadWeather() async throws {
        
        guard let park = details?.park,
              let startsAt = details?.startsAt else {
            return
        }
        
        weather =
            try await weatherService
                .fetchWeather(
                    latitude: park.latitude,
                    longitude: park.longitude,
                    date: startsAt
                )
    }
    
    // MARK: - Realtime Setup
    
    private func setupRealtimeIfNeeded(
        gameId: UUID
    ) async {
        
        guard subscribedGameId != gameId else {
            return
        }
        
        subscribedGameId = gameId
        
        await setupRealtimeSubscription(
            gameId: gameId
        )
    }
    
    // MARK: - Realtime
    
    private func setupRealtimeSubscription(
        gameId: UUID
    ) async {
        
        await realtimeChannel?
            .unsubscribe()
        
        realtimeChannel = SupabaseService
            .shared
            .client
            .realtimeV2
            .channel("game-info-\(gameId)")
        
        observeRealtime(
            table: "games",
            filter: "id=eq.\(gameId.uuidString)",
            eventName: "Games"
        )
        
        observeRealtime(
            table: "game_members",
            filter: "game_id=eq.\(gameId.uuidString)",
            eventName: "Members"
        )
        
        observeRealtime(
            table: "game_mvp_votes",
            filter: "game_id=eq.\(gameId.uuidString)",
            eventName: "Votes"
        )
        
        do {
            
            try await realtimeChannel?
                .subscribeWithError()
            
            AppLogger.success(
                "Game realtime connected"
            )
            
        } catch {
            
            if error is CancellationError {
                return
            }
            
            AppLogger.error(
                "Game realtime subscribe failed",
                error: error
            )
        }
    }
    
    // MARK: - Observe Realtime
    
    private func observeRealtime(
        table: String,
        filter: String,
        eventName: String
    ) {
        
        let subscription =
            realtimeChannel?.onPostgresChange(
                AnyAction.self,
                schema: "public",
                table: table,
                filter: filter
            ) { [weak self] _ in
                
                AppLogger.info(
                    "\(eventName) realtime event"
                )
                
                Task { @MainActor in
                    
                    await self?
                        .handleRealtimeUpdate()
                }
            }
        
        switch table {
            
        case "games":
            gamesSubscription = subscription
            
        case "game_members":
            membersSubscription = subscription
            
        case "game_mvp_votes":
            votesSubscription = subscription
            
        default:
            break
        }
    }
    
    // MARK: - Realtime Update
    
    private func handleRealtimeUpdate() async {
        
        guard let gameId = subscribedGameId else {
            return
        }
        
        do {
            
            let updatedDetails =
                try await gameService
                    .fetchGameDetails(
                        gameId: gameId
                    )
            
            withAnimation(.spring) {
                
                details = updatedDetails
            }
            
            AppLogger.success(
                "Game reloaded"
            )
            
        } catch {
            
            AppLogger.error(
                "Game realtime reload failed",
                error: error
            )
        }
    }
    
    // MARK: - Join Game
    
    func joinGame(
        gameId: UUID,
        team: Team
    ) async {
        
        do {
            
            try await gameService
                .joinGame(
                    gameId: gameId,
                    team: team
                )
            
        } catch {
            
            errorMessage =
                error.localizedDescription
            
            AppLogger.error(
                "Join game failed",
                error: error
            )
        }
    }
    
    // MARK: - Leave Game
    
    func leaveGame(
        gameId: UUID
    ) async {
        
        do {
            
            try await gameService
                .leaveGame(
                    gameId: gameId
                )
            
        } catch {
            
            errorMessage =
                error.localizedDescription
            
            AppLogger.error(
                "Leave game failed",
                error: error
            )
        }
    }
    
    // MARK: - MVP Voting
    
    func submitVote(
        playerId: UUID
    ) async {
        
        guard let details else {
            return
        }
        
        isSubmittingVote = true
        
        defer {
            
            isSubmittingVote = false
        }
        
        do {
            
            try await gameService
                .voteMVP(
                    gameId: details.id,
                    votedUserId: playerId
                )
            
        } catch {
            
            errorMessage =
                error.localizedDescription
            
            AppLogger.error(
                "Submit MVP vote failed",
                error: error
            )
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        
        let channel = realtimeChannel
        
        Task { @MainActor in
            
            await channel?.unsubscribe()
        }
    }
}
