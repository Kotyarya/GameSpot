import Foundation

// MARK: - Profile

struct Profile: Decodable, Identifiable {

    let id: UUID

    let username: String?

    let avatarUrl: String?

    let favoriteSportId: UUID?
    let favoriteSport: Sport?

    let rating: Int
    let gamesPlayed: Int
    let mvpCount: Int
    let perfPoints: Int

    let isOnboarded: Bool
    let isProfileCompleted: Bool

    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {

        case id

        case username

        case avatarUrl = "avatar_url"

        case favoriteSportId = "favorite_sport_id"
        case favoriteSport = "sports"

        case rating

        case gamesPlayed = "games_played"
        case mvpCount = "mvp_count"
        case perfPoints = "perf_points"

        case isOnboarded = "is_onboarded"
        case isProfileCompleted = "is_profile_completed"

        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Team

enum Team: String, Decodable, Encodable {

    case alpha = "Team Alpha"
    case beta = "Team Beta"
}

// MARK: - Player

struct Player: Decodable, Identifiable {

    let id: UUID

    let username: String

    let avatarUrl: String?

    let team: Team

    let rating: Int
    let gamesPlayed: Int

    let createdAt: Date

    let isTopRated: Bool
    let isMostActive: Bool
    let isNewest: Bool

    let mvpVotesCount: Int

    let isVotedByCurrentUser: Bool

}

// MARK: - Highlight Player

struct HighlightPlayer: Decodable {

    let id: UUID

    let username: String

    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {

        case id

        case username

        case avatarUrl = "avatar_url"
    }
}

// MARK: - Recent Match

struct RecentMatch: Identifiable, Decodable {

    let id: UUID

    let startsAt: Date

    let sport: Sport

    let ratingChange: Int

    let perfPointsEarned: Int

    let wasMVP: Bool

    enum CodingKeys: String, CodingKey {

        case id

        case startsAt = "starts_at"

        case sport

        case ratingChange = "rating_change"

        case perfPointsEarned = "perf_points_earned"

        case wasMVP = "was_mvp"
    }
}
