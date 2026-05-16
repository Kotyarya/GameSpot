import SwiftUI
import Foundation
import Combine

enum Route: Hashable {
    case myGames
    case parkGames(id: UUID, name: String)
    case game(UUID)
    case createGame(
            park: Park,
            sports: [Sport]
        )
}

final class AppRouter: ObservableObject {
    
    // MARK: - Active Tab
    
    enum Tab {
        case map
        case games
        case profile
    }
    
    @Published var selectedTab: Tab = .map
    
    // MARK: - Paths (по одному на таб)
    
    @Published var mapPath = NavigationPath()
    @Published var gamesPath = NavigationPath()
    
    // MARK: - Push
    
    func push(_ route: Route, on tab: Tab? = nil) {
        
        let targetTab = tab ?? selectedTab
        
        // если нужно — переключаем таб
        if let tab {
            selectedTab = tab
        }
        
        switch targetTab {
        case .map:
            mapPath.append(route)
            
        case .games:
            gamesPath.append(route)
            
        case .profile:
            break
        }
    }
    
    // MARK: - Pop
    
    func pop() {
        switch selectedTab {
        case .map:
            if !mapPath.isEmpty { mapPath.removeLast() }
        case .games:
            if !gamesPath.isEmpty { gamesPath.removeLast() }
        case .profile:
            break
        }
    }
    
    // MARK: - Pop to root
    
    func popToRoot() {
        switch selectedTab {
        case .map:
            mapPath = NavigationPath()
        case .games:
            gamesPath = NavigationPath()
        case .profile:
            break
        }
    }
}


@MainActor @ViewBuilder
func destination(_ route: Route) -> some View {
    switch route {
        
    case .myGames:
        GamesView(mode: .myGames)
        
    case .parkGames(let id, let name):
        GamesView(mode: .park(id: id), parkName: name)
        
    case .game(let id):
        GameInfoView(gameId: id)
        
    case .createGame(let park, let sports):
        
        CreateGameView(
            park: park,
            sports: sports
        )
    }
}
