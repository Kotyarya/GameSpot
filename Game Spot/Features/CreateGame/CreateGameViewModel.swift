import Foundation
import Combine

@MainActor
final class CreateGameViewModel: ObservableObject {
    
    // MARK: - State
    
    @Published var selectedSport: Sport?
    
    @Published var startsAt: Date =
        Calendar.current.date(
            byAdding: .hour,
            value: 1,
            to: Date()
        ) ?? Date()
    
    @Published var isLoading = false
    
    @Published var errorMessage: String?
    
    // MARK: - Services
    
    private let service: any GameCreating

    private let loadingDelay: Duration

    // MARK: - Init

    init(
        service: any GameCreating = GameService.shared,
        loadingDelay: Duration = .milliseconds(700)
    ) {

        self.service = service
        self.loadingDelay = loadingDelay
    }
    
    // MARK: - Actions
    
    func createGame(
        parkId: UUID
    ) async -> UUID? {
        
        guard let sport = selectedSport else {
            
            errorMessage = "Select sport"
            
            return nil
        }
        
        isLoading = true
        
        errorMessage = nil
        
        do {
            
            let gameId = try await service.createGame(
                parkId: parkId,
                sportId: sport.id,
                startsAt: startsAt
            )
            
            await stopLoadingWithDelay()
            
            return gameId
            
        } catch {
            
            await stopLoadingWithDelay()
            
            errorMessage =
                "Couldn’t create the game. Check your connection and try again."
            
            AppLogger.error(
                "CreateGameViewModel create game failed",
                error: error
            )
            
            return nil
        }
    }
    
    // MARK: - Helpers
    
    private func stopLoadingWithDelay() async {
        
        try? await Task.sleep(
            for: loadingDelay
        )
        
        isLoading = false
    }
}
