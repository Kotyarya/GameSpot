import SwiftUI
import Combine

enum GamesMode: Equatable {
    
    case myGames
    
    case park(id: UUID)
}

struct GamesView: View {

    @EnvironmentObject private var router:
        AppRouter
    
    // MARK: - Properties
    
    let mode: GamesMode
    
    let parkName: String?
    
    // MARK: - State
    
    @StateObject private var viewModel =
        GamesViewModel()
    
    // MARK: - Init
    
    init(
        mode: GamesMode,
        parkName: String? = nil
    ) {
        
        self.mode = mode
        self.parkName = parkName
    }
    
    // MARK: - Navigation Title
    
    private var navigationTitle: String {
        
        switch mode {
            
        case .myGames:
            return "My Games"
            
        case .park:
            return parkName ?? "Park"
        }
    }
    
    // MARK: - Sections
    
    private var sections: [GameSection] {

        GameSectionBuilder.sections(
            for: viewModel.games
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        
        ZStack {
            
            if viewModel.isLoading {
                
                loadingView
                
            } else if let error = viewModel.errorMessage,
                      viewModel.games.isEmpty {

                errorView(error)

            } else if viewModel.games.isEmpty {
                
                emptyView
                
            } else {
                
                contentView
            }
        }
        .animation(
            .easeInOut(duration: 0.3),
            value: viewModel.isLoading
        )
        .navigationTitle(
            viewModel.isLoading
            ? ""
            : navigationTitle
        )
        .navigationBarTitleDisplayMode(.large)
        .task {
            
            await viewModel.load(
                mode: mode
            )
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        LoadingView()
            .transition(
                .opacity.combined(
                    with: .scale(scale: 0.98)
                )
            )
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {

        switch mode {

        case .myGames:

            ContentStateView(
                title: "No Games Yet",
                message: "Games you join or create will appear here. Explore a park to find your first game.",
                systemImage: "sportscourt",
                accessibilityIdentifier: "games.empty",
                actionTitle: "Explore Parks"
            ) {
                router.selectedTab = .map
            }

        case .park:

            ContentStateView(
                title: "No Games at This Park",
                message: "There are no upcoming games here yet. Go back to the park and create one.",
                systemImage: "sportscourt",
                accessibilityIdentifier: "games.empty",
                actionTitle: "Refresh"
            ) {
                retryLoad()
            }
        }
    }

    private func errorView(
        _ message: String
    ) -> some View {

        ContentStateView(
            title: "Couldn’t Load Games",
            message: message,
            systemImage: "wifi.exclamationmark",
            accessibilityIdentifier: "games.error",
            actionTitle: "Try Again"
        ) {
            retryLoad()
        }
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        
        ScrollView {
            
            LazyVStack(
                alignment: .leading,
                spacing: 20
            ) {
                
                ForEach(sections) { section in
                    
                    sectionView(section)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .refreshable {
            await viewModel.load(mode: mode)
        }
    }

    private func retryLoad() {
        Task {
            await viewModel.retry()
        }
    }
    
    // MARK: - Section View
    
    @ViewBuilder
    private func sectionView(
        _ section: GameSection
    ) -> some View {
        
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            
            sectionHeader(section)
            
            sectionGames(section)
            
            Divider()
                .padding(.top, 12)
        }
    }
    
    // MARK: - Section Header
    
    @ViewBuilder
    private func sectionHeader(
        _ section: GameSection
    ) -> some View {
        
        Text(section.title)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
    
    // MARK: - Section Games
    
    @ViewBuilder
    private func sectionGames(
        _ section: GameSection
    ) -> some View {
        
        VStack(spacing: 12) {
            
            ForEach(section.games) { game in
                
                GameCard(game: game)
            }
        }
    }
    
}
