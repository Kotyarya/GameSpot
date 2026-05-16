import SwiftUI
import Combine

struct GameSection: Identifiable {
    
    let id = UUID()
    
    let title: String
    
    let games: [Game]
}

enum GamesMode: Equatable {
    
    case myGames
    
    case park(id: UUID)
}

struct GamesView: View {
    
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
        
        let calendar = Calendar.current
        
        let groupedGames = Dictionary(
            grouping: viewModel.games
        ) { game in
            
            calendar.startOfDay(
                for: game.startsAt
            )
        }
        
        let sortedDates =
            groupedGames.keys.sorted()
        
        return sortedDates.map { date in
            
            let games =
                groupedGames[date]?
                    .sorted {
                        $0.startsAt < $1.startsAt
                    }
                ?? []
            
            return GameSection(
                title: sectionTitle(
                    for: date
                ),
                games: games
            )
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        
        ZStack {
            
            if viewModel.isLoading {
                
                loadingView
                
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
        
        ContentUnavailableView(
            "No Games",
            systemImage: "sportscourt"
        )
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
    
    // MARK: - Helpers
    
    private func sectionTitle(
        for date: Date
    ) -> String {
        
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            
            return "Today"
            
        } else if calendar.isDateInTomorrow(date) {
            
            return "Tomorrow"
            
        } else if calendar.isDateInYesterday(date) {
            
            return "Yesterday"
            
        } else {
            
            let formatter = DateFormatter()
            
            formatter.dateFormat = "d MMMM"
            
            return formatter.string(
                from: date
            )
        }
    }
}


