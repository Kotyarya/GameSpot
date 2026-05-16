import Foundation

struct UserSportStats: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let sportId: UUID
    
    let rating: Int
    let gamesPlayed: Int
    let mvpCount: Int
    let perfPoints: Int
    
    let sport: Sport
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case sportId = "sport_id"
        case rating
        case gamesPlayed = "games_played"
        case mvpCount = "mvp_count"
        case perfPoints = "perf_points"
        case sport = "sports"
    }
}
