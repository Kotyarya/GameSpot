import Foundation


// MARK: Game
struct Game: Decodable, Identifiable, Equatable {
    
    let id: UUID
    
    let parkId: UUID
    let creatorId: UUID
    
    let sport: Sport
    
    let startsAt: Date
    let durationMinutes: Int
    let maxPlayers: Int
    
    let isFinished: Bool
    let isProcessed: Bool
    let isInProgress: Bool
    let mvpVotingOpen: Bool
    
    let joinedPlayers: Int
    
    enum CodingKeys: String, CodingKey {
        
        case id
        
        case parkId = "park_id"
        case creatorId = "creator_id"
        
        case sport
        
        case startsAt = "starts_at"
        case durationMinutes = "duration_minutes"
        case maxPlayers = "max_players"
        
        case isFinished = "is_finished"
        case isProcessed = "is_processed"
        case isInProgress = "is_in_progress"
        case mvpVotingOpen = "mvp_voting_open"
        
        case joinedPlayers = "joined_players"
    }
}

// MARK: MVP Player
struct MVPPlayer: Decodable, Equatable {

    let id: UUID

    let username: String

    let avatarUrl: String?

    let rating: Int

    let votesCount: Int
}

// MARK: Game Details
struct GameDetails: Decodable, Identifiable {
    
    let id: UUID
    let startsAt: Date
    let durationMinutes: Int
    let maxPlayers: Int
    let joinedPlayers: Int
    let isFinished: Bool
    
    let sport: Sport
    let park: ParkShort
    
    let players: [Player]
    
    let isJoined: Bool
    let mvpPlayer: MVPPlayer?
    let isInProgress: Bool
    let isProcessed: Bool
    let mvpVotingOpen: Bool
    let hasVoted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case startsAt = "starts_at"
        case durationMinutes = "duration_minutes"
        case maxPlayers = "max_players"
        case joinedPlayers = "joined_players"
        case isFinished = "is_finished"
        case sport
        case park
        case players
        case isJoined = "is_joined"
        case isInProgress = "is_in_progress"
        case isProcessed = "is_processed"
        case mvpVotingOpen = "mvp_voting_open"
        case hasVoted = "has_voted"
        case mvpPlayer = "mvp_player"
    }
}
