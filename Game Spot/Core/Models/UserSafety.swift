import Foundation

// MARK: - Report Reason

enum ReportReason: String, CaseIterable, Identifiable, Encodable, Hashable {

    case offensiveUsername = "offensive_username"
    case offensiveAvatar = "offensive_avatar"
    case abusiveBehavior = "abusive_behavior"
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .offensiveUsername:
            return "Offensive username"
        case .offensiveAvatar:
            return "Offensive avatar"
        case .abusiveBehavior:
            return "Abusive behavior"
        case .other:
            return "Other"
        }
    }
}


// MARK: - Blocked User

struct BlockedUser:
    Decodable,
    Identifiable,
    Equatable {

    let blockedId: UUID
    let blockedUsername: String
    let blockedAvatarUrl: String?
    let createdAt: Date

    var id: UUID {
        blockedId
    }

    enum CodingKeys: String, CodingKey {

        case blockedId = "blocked_id"
        case blockedUsername = "blocked_username"
        case blockedAvatarUrl = "blocked_avatar_url"
        case createdAt = "created_at"
    }
}

// MARK: - Public Profile Summary

struct PublicProfileSummary:
    Identifiable,
    Equatable {

    let id: UUID
    let username: String
    let avatarUrl: String?
    let rating: Int
    let gamesPlayed: Int?

    init(player: Player) {

        id = player.id
        username = player.username
        avatarUrl = player.avatarUrl
        rating = player.rating
        gamesPlayed = player.gamesPlayed
    }

    init(mvpPlayer: MVPPlayer) {

        id = mvpPlayer.id
        username = mvpPlayer.username
        avatarUrl = mvpPlayer.avatarUrl
        rating = mvpPlayer.rating
        gamesPlayed = nil
    }
}
