import Foundation
import Combine
import SwiftUI

@MainActor
final class GamesViewModel: ObservableObject {
    
    // MARK: - State
    
    @Published var games: [Game] = []
    
    @Published var isLoading = false

    @Published private(set) var errorMessage: String?
    
    // MARK: - Services
    
    private let service: any GamesFetching
    
    // MARK: - Realtime
    
    private let realtime: any GamesRealtimeSubscribing
    
    // MARK: - Properties
    
    private var currentMode: GamesMode?
    
    private var hasSubscribed = false
    
    private var didFinishInitialLoad = false

    private let minimumLoadingDuration: TimeInterval

    // MARK: - Init

    init(
        service: any GamesFetching = GameService.shared,
        realtime: any GamesRealtimeSubscribing =
            SupabaseGamesRealtimeService(),
        minimumLoadingDuration: TimeInterval = 1.0
    ) {
        self.service = service
        self.realtime = realtime
        self.minimumLoadingDuration = minimumLoadingDuration
    }
    
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

        errorMessage = nil
        
        do {
            
            try await reloadGames()

            try Task.checkCancellation()
            
            if !hasSubscribed {
                await setupRealtimeSubscription()
            }

            try Task.checkCancellation()
            
            didFinishInitialLoad = true
            
        } catch {
            
            if !(error is CancellationError) {

                errorMessage =
                    "Couldn’t load games. Check your connection and try again."

                AppLogger.error(
                    "GamesViewModel load failed",
                    error: error
                )
            }
        }
        
        if shouldShowLoader {
            
            let elapsed =
                Date().timeIntervalSince(startTime)
            
            if elapsed < minimumLoadingDuration {
                
                let remaining =
                    minimumLoadingDuration - elapsed
                
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

    func retry() async {

        guard let currentMode else {
            return
        }

        await load(mode: currentMode)
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
        do {
            try await realtime.subscribe { [weak self] in
                AppLogger.info(
                    "Games realtime event"
                )

                await self?.handleRealtimeUpdate()
            }

            hasSubscribed = true
            
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
        let realtime = realtime

        Task { @MainActor in
            await realtime.unsubscribe()
        }
    }
}
