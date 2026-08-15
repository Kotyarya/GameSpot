import Foundation
import Combine
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
    
    private let gameService: any GameInfoServing

    private let weatherService: any WeatherFetching

    private let realtime: any GameInfoRealtimeSubscribing
    
    // MARK: - Properties
    
    private var subscribedGameId: UUID?

    // MARK: - Init

    init(
        gameService: any GameInfoServing = GameService.shared,
        weatherService: any WeatherFetching = WeatherService.shared,
        realtime: any GameInfoRealtimeSubscribing = SupabaseGameInfoRealtimeService()
    ) {

        self.gameService = gameService
        self.weatherService = weatherService
        self.realtime = realtime
    }
    
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

            try Task.checkCancellation()
            
            await setupRealtimeIfNeeded(
                gameId: gameId
            )

            try Task.checkCancellation()
            
        } catch {
            
            if !(error is CancellationError) {
                errorMessage =
                    error.localizedDescription

                AppLogger.error(
                    "GameInfoViewModel load failed",
                    error: error
                )
            }
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
        
        do {

            try await realtime.subscribe(
                gameId: gameId
            ) { [weak self] in
                await self?.handleRealtimeUpdate()
            }

            subscribedGameId = gameId

            AppLogger.success(
                "Game realtime connected"
            )

        } catch {

            if !(error is CancellationError) {
                AppLogger.error(
                    "Game realtime subscribe failed",
                    error: error
                )
            }
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
        
        let realtime = realtime
        
        Task { @MainActor in
            
            await realtime.unsubscribe()
        }
    }
}
