import Foundation
import Combine
import SwiftUI

@MainActor
final class GameInfoViewModel: ObservableObject {
    
    // MARK: - State
    
    @Published var details: GameDetails?

    @Published private(set) var gameMembers: [GameMember] = []
    
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

        guard !isLoading else {
            return
        }
        
        isLoading = true

        defer {
            isLoading = false
        }
        
        errorMessage = nil
        
        do {
            
            try await loadGameDetails(
                gameId: gameId
            )
            
            do {

                try await loadWeather()

            } catch {

                if error is CancellationError {
                    throw error
                }

                weather = nil

                AppLogger.warning(
                    "Weather unavailable for game details"
                )
            }

            try Task.checkCancellation()
            
            await setupRealtimeIfNeeded(
                gameId: gameId
            )

            try Task.checkCancellation()
            
        } catch {
            
            if !(error is CancellationError) {
                errorMessage =
                    "Couldn’t load this game. Check your connection and try again."

                AppLogger.error(
                    "GameInfoViewModel load failed",
                    error: error
                )
            }
        }
        
    }
    
    // MARK: - Load Details
    
    private func loadGameDetails(
        gameId: UUID
    ) async throws {

        let loadedDetails = try await gameService
            .fetchGameDetails(
                gameId: gameId
            )
        let loadedMembers = try await gameService
            .fetchGameMembers(
                gameId: gameId
            )

        details = loadedDetails
        gameMembers = loadedMembers
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
            
            let updatedDetails = try await gameService
                .fetchGameDetails(
                    gameId: gameId
                )
            let updatedMembers = try await gameService
                .fetchGameMembers(
                    gameId: gameId
                )
            
            withAnimation(.spring) {
                
                details = updatedDetails
                gameMembers = updatedMembers
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

    // MARK: - Manual Refresh

    func refreshDetails(
        gameId: UUID
    ) async {

        do {

            let updatedDetails = try await gameService
                .fetchGameDetails(
                    gameId: gameId
                )
            let updatedMembers = try await gameService
                .fetchGameMembers(
                    gameId: gameId
                )

            withAnimation(.spring) {
                details = updatedDetails
                gameMembers = updatedMembers
            }

        } catch {

            if !(error is CancellationError) {
                AppLogger.error(
                    "Game details refresh failed",
                    error: error
                )
            }
        }
    }
    
    // MARK: - Join Game
    
    func joinGame(
        gameId: UUID,
        team: Team
    ) async throws {

        errorMessage = nil
        
        do {
            
            try await gameService
                .joinGame(
                    gameId: gameId,
                    team: team
                )

            await refreshDetailsAfterTeamChange(
                gameId: gameId
            )
            
        } catch {
            
            errorMessage =
                "Couldn’t join this game. Check your connection and try again."
            
            AppLogger.error(
                "Join game failed",
                error: error
            )

            throw error
        }
    }
    
    // MARK: - Leave Game
    
    func leaveGame(
        gameId: UUID
    ) async throws {

        errorMessage = nil
        
        do {
            
            try await gameService
                .leaveGame(
                    gameId: gameId
                )

            await refreshDetailsAfterTeamChange(
                gameId: gameId
            )
            
        } catch {
            
            errorMessage =
                "Couldn’t leave this game. Check your connection and try again."
            
            AppLogger.error(
                "Leave game failed",
                error: error
            )

            throw error
        }
    }

    private func refreshDetailsAfterTeamChange(
        gameId: UUID
    ) async {

        do {

            let updatedDetails = try await gameService
                .fetchGameDetails(gameId: gameId)
            let updatedMembers = try await gameService
                .fetchGameMembers(gameId: gameId)

            withAnimation(.spring) {
                details = updatedDetails
                gameMembers = updatedMembers
            }

        } catch {

            AppLogger.error(
                "Team changed, but game reload failed",
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

        errorMessage = nil
        
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
                "Couldn’t submit your vote. Check your connection and try again."
            
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
