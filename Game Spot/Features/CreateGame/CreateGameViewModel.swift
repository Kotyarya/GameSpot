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
    
    private let service = GameService.shared
    
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
            
            errorMessage = error.localizedDescription
            
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
            for: .milliseconds(700)
        )
        
        isLoading = false
    }
}
