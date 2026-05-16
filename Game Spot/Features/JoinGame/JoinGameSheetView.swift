import SwiftUI

struct JoinGameSheetView: View {
    
    // MARK: - Properties
    
    let details: GameDetails
    let currentUserId: UUID
    
    let onJoin: (Team) -> Void
    let onLeave: () -> Void
    
    // MARK: - Environment
    
    @Environment(\.dismiss)
    private var dismiss
    
    // MARK: - Computed Properties
    
    private var teamLimit: Int {
        details.maxPlayers / 2
    }
    
    private var alphaPlayers: [Player] {
        details.players.filter {
            $0.team == .alpha
        }
    }
    
    private var betaPlayers: [Player] {
        details.players.filter {
            $0.team == .beta
        }
    }
    
    private var isJoined: Bool {
        details.players.contains {
            $0.id == currentUserId
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        
        NavigationStack {
            
            content
                .navigationTitle("Join Game")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    closeToolbar
                }
        }
    }
    
    // MARK: - Content
    
    private var content: some View {
        
        ScrollView {
            
            VStack(spacing: 32) {
                
                teamSection(
                    title: "Team Alpha",
                    players: alphaPlayers,
                    team: .alpha
                )
                
                versusSection
                
                teamSection(
                    title: "Team Beta",
                    players: betaPlayers,
                    team: .beta
                )
            }
            .padding(20)
            .padding(.bottom, 40)
        }
    }
    
    private func teamSection(
        title: String,
        players: [Player],
        team: Team
    ) -> some View {
        
        TeamSectionView(
            title: title,
            players: players,
            team: team,
            limit: teamLimit,
            currentUserId: currentUserId,
            isJoined: isJoined,
            onJoin: onJoin,
            onLeave: onLeave
        )
    }
    
    private var versusSection: some View {
        
        ZStack {
            
            Text("VS")
                .font(
                    .system(
                        size: 50,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundStyle(.white)
        }
        .frame(width: 100, height: 100)
        .glassEffect(
            .regular
                .tint(Color("AccentColor"))
                .interactive(true),
            in: .circle
        )
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var closeToolbar: some ToolbarContent {
        
        ToolbarItem(
            placement: .topBarTrailing
        ) {
            
            Button {
                
                dismiss()
                
            } label: {
                
                Image(systemName: "xmark")
            }
        }
    }
}

// MARK: - Team Section

struct TeamSectionView: View {
    
    // MARK: - Properties
    
    let title: String
    
    let players: [Player]
    
    let team: Team
    
    let limit: Int
    
    let currentUserId: UUID
    
    let isJoined: Bool
    
    let onJoin: (Team) -> Void
    
    let onLeave: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            
            Text(title)
                .font(.largeTitle)
                .bold()
            
            playersList
        }
    }
    
    // MARK: - Players List
    
    private var playersList: some View {
        
        VStack(spacing: 0) {
            
            ForEach(0..<limit, id: \.self) { index in
                
                slotRow(at: index)
                
                if index != limit - 1 {
                    
                    Divider()
                        .padding(.leading, 72)
                }
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28
            )
        )
    }
    
    @ViewBuilder
    private func slotRow(
        at index: Int
    ) -> some View {
        
        if index < players.count {
            
            PlayerSlotRow(
                player: players[index],
                currentUserId: currentUserId,
                onLeave: onLeave
            )
            
        } else {
            
            EmptySlotRow(
                team: team,
                disabled: isJoined,
                onJoin: onJoin
            )
        }
    }
}

// MARK: - Player Slot Row

struct PlayerSlotRow: View {
    
    // MARK: - Properties
    
    let player: Player
    
    let currentUserId: UUID
    
    let onLeave: () -> Void
    
    // MARK: - Computed Properties
    
    private var isCurrentUser: Bool {
        player.id == currentUserId
    }
    
    private var rank: Rank {
        RankHelper.getRank(
            rating: player.rating
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        
        HStack(spacing: 14) {
            
            avatar
            
            playerInfo
            
            Spacer()
            
            if isCurrentUser {
                leaveButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            isCurrentUser
            ? Color("AccentColor")
            : .clear
        )
    }
    
    // MARK: - Avatar
    
    private var avatar: some View {
        
        AsyncImage(
            url: URL(
                string: player.avatarUrl ?? ""
            )
        ) { phase in
            
            switch phase {
                
            case .success(let image):
                
                image
                    .resizable()
                    .scaledToFill()
                
            default:
                
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .foregroundStyle(.white)
                    .background(Color("AccentColor"))
            }
            
        }
        .frame(width: 52, height: 52)
        .background(Color("AccentColor"))
        .clipShape(Circle())
    }
    
    // MARK: - Player Info
    
    private var playerInfo: some View {
        
        VStack(
            alignment: .leading,
            spacing: 2
        ) {
            
            Text(player.username)
                .font(.headline)
                .bold()
            
            rankBadge
        }
    }
    
    private var rankBadge: some View {
        
        ZStack {
            
            Text(rank.title)
                .font(.title3)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(rank.textColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .background(rank.borderColor)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 8
            )
        )
    }
    
    // MARK: - Leave Button
    
    private var leaveButton: some View {
        
        Button {
            
            onLeave()
            
        } label: {
            
            Image(
                systemName:
                    "rectangle.portrait.and.arrow.right"
            )
            .font(.title3)
            .bold()
        }
        .foregroundStyle(.white)
    }
}

// MARK: - Empty Slot Row

struct EmptySlotRow: View {
    
    // MARK: - Properties
    
    let team: Team
    
    let disabled: Bool
    
    let onJoin: (Team) -> Void
    
    // MARK: - Body
    
    var body: some View {
        
        Button {
            
            onJoin(team)
            
        } label: {
            
            HStack(spacing: 14) {
                
                slotAvatar
                
                slotInfo
                
                Spacer()
                
                joinIcon
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.45 : 1)
    }
    
    // MARK: - Slot Avatar
    
    private var slotAvatar: some View {
        
        ZStack {
            
            Circle()
                .fill(Color("AccentColor").opacity(0.15))
            
            Image(systemName: "person.fill")
                .foregroundStyle(Color("AccentColor"))
        }
        .frame(width: 52, height: 52)
    }
    
    // MARK: - Slot Info
    
    private var slotInfo: some View {
        
        VStack(
            alignment: .leading,
            spacing: 2
        ) {
            
            Text("Empty Slot")
                .font(.headline)
                .bold()
            
            Text("Tap to join")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Join Icon
    
    private var joinIcon: some View {
        
        Image(systemName: "plus")
            .font(.title3)
            .bold()
            .foregroundStyle(Color("AccentColor"))
    }
}
