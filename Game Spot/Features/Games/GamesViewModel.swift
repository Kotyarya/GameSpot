import Foundation
import Combine
import Supabase
import SwiftUI

@MainActor
final class GamesViewModel: ObservableObject {
    
    // MARK: - State
    
    @Published var games: [Game] = []
    
    @Published var isLoading = false
    
    // MARK: - Services
    
    private let service = GameService.shared
    
    // MARK: - Realtime
    
    private var realtimeChannel:
        RealtimeChannelV2?
    
    private var gamesSubscription:
        RealtimeSubscription?
    
    private var membersSubscription:
        RealtimeSubscription?
    
    // MARK: - Properties
    
    private var currentMode: GamesMode?
    
    private var hasSubscribed = false
    
    private var didFinishInitialLoad = false
    
    // MARK: - Load
    
    func load(
        mode: GamesMode
    ) async {
        
        currentMode = mode
        
        let shouldShowLoader =
            !didFinishInitialLoad
        
        let startTime = Date()
        
        if shouldShowLoader {
            
            withAnimation(
                .easeInOut(duration: 0.2)
            ) {
                
                isLoading = true
            }
        }
        
        do {
            
            try await reloadGames()
            
            if !hasSubscribed {
                
                hasSubscribed = true
                
                await setupRealtimeSubscription()
            }
            
            didFinishInitialLoad = true
            
        } catch {
            
            if error is CancellationError {
                return
            }
            
            AppLogger.error(
                "GamesViewModel load failed",
                error: error
            )
        }
        
        if shouldShowLoader {
            
            let elapsed =
                Date().timeIntervalSince(startTime)
            
            let minimumDuration = 1.0
            
            if elapsed < minimumDuration {
                
                let remaining =
                    minimumDuration - elapsed
                
                try? await Task.sleep(
                    for: .seconds(remaining)
                )
            }
            
            withAnimation(
                .easeInOut(duration: 0.25)
            ) {
                
                isLoading = false
            }
        }
    }
    
    // MARK: - Reload
    
    private func reloadGames() async throws {
        
        guard let currentMode else {
            return
        }
        
        let updatedGames: [Game]
        
        switch currentMode {
            
        case .myGames:
            
            updatedGames =
                try await service
                    .fetchUserGames()
            
        case .park(let parkId):
            
            updatedGames =
                try await service
                    .fetchGamesByPark(
                        parkId: parkId
                    )
        }
        
        withAnimation(.spring) {
            
            games = updatedGames
        }
        
        AppLogger.success(
            "GamesViewModel reloaded"
        )
    }
    
    // MARK: - Realtime
    
    private func setupRealtimeSubscription() async {
        
        await realtimeChannel?
            .unsubscribe()
        
        realtimeChannel = SupabaseService
            .shared
            .client
            .realtimeV2
            .channel("games-list")
        
        gamesSubscription =
        realtimeChannel?.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "games"
        ) { _ in
            
            AppLogger.info(
                "Games realtime event"
            )
            
            Task { @MainActor [weak self] in
                
                await self?
                    .handleRealtimeUpdate()
            }
        }
        
        membersSubscription =
        realtimeChannel?.onPostgresChange(
            AnyAction.self,
            schema: "public",
            table: "game_members"
        ) { _ in
            
            AppLogger.info(
                "Members realtime event"
            )
            
            Task { @MainActor [weak self] in
                
                await self?
                    .handleRealtimeUpdate()
            }
        }
        
        do {
            
            try await realtimeChannel?
                .subscribeWithError()
            
            AppLogger.success(
                "Games realtime connected"
            )
            
        } catch {
            
            if error is CancellationError {
                return
            }
            
            AppLogger.error(
                "Games realtime subscribe failed",
                error: error
            )
        }
    }
    
    private func handleRealtimeUpdate() async {
        
        do {
            
            try await reloadGames()
            
        } catch {
            
            AppLogger.error(
                "Games realtime reload failed",
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
