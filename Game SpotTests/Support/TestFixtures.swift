//
//  TestFixtures.swift
//  Game SpotTests
//
//  Shared JSON fixtures and factory helpers for unit and ViewModel tests.
//

import Foundation
@testable import Game_Spot

enum TestFixtures {

    // MARK: - Identifiers

    static let userId = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    static let gameId = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
    static let parkId = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!
    static let sportFootballId = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
    static let sportBasketballId = UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!

    // MARK: - Sports

    static func sport(
        id: UUID = sportFootballId,
        name: String = "football"
    ) -> Sport {
        decode(Sport.self, from: """
        {
            "id": "\(id.uuidString)",
            "name": "\(name)"
        }
        """)
    }

    // MARK: - Game

    static func game(
        id: UUID = gameId,
        startsAt: Date,
        durationMinutes: Int = 60,
        maxPlayers: Int = 10,
        joinedPlayers: Int = 4,
        isFinished: Bool = false,
        isInProgress: Bool = false
    ) -> Game {
        decode(Game.self, from: """
        {
            "id": "\(id.uuidString)",
            "park_id": "\(parkId.uuidString)",
            "creator_id": "\(userId.uuidString)",
            "sport": {
                "id": "\(sportFootballId.uuidString)",
                "name": "football"
            },
            "starts_at": "\(iso8601(startsAt))",
            "duration_minutes": \(durationMinutes),
            "max_players": \(maxPlayers),
            "is_finished": \(isFinished),
            "is_processed": false,
            "is_in_progress": \(isInProgress),
            "mvp_voting_open": false,
            "joined_players": \(joinedPlayers)
        }
        """)
    }

    // MARK: - Profile

    static func profile(
        isOnboarded: Bool = true,
        isProfileCompleted: Bool = true,
        rating: Int = 500
    ) -> Profile {
        let now = iso8601(Date())
        return decode(Profile.self, from: """
        {
            "id": "\(userId.uuidString)",
            "username": "testuser",
            "avatar_url": null,
            "favorite_sport_id": "\(sportFootballId.uuidString)",
            "sports": {
                "id": "\(sportFootballId.uuidString)",
                "name": "football"
            },
            "rating": \(rating),
            "games_played": 10,
            "mvp_count": 2,
            "perf_points": 100,
            "is_onboarded": \(isOnboarded),
            "is_profile_completed": \(isProfileCompleted),
            "created_at": "\(now)",
            "updated_at": "\(now)"
        }
        """)
    }

    // MARK: - Player

    static func player(
        id: UUID = userId,
        username: String = "player1",
        team: Team = .alpha,
        rating: Int = 400
    ) -> Player {
        let now = iso8601(Date())
        return decode(Player.self, from: """
        {
            "id": "\(id.uuidString)",
            "username": "\(username)",
            "avatarUrl": null,
            "team": "\(team.rawValue)",
            "rating": \(rating),
            "gamesPlayed": 5,
            "createdAt": "\(now)",
            "isTopRated": false,
            "isMostActive": false,
            "isNewest": false,
            "mvpVotesCount": 0,
            "isVotedByCurrentUser": false
        }
        """)
    }

    // MARK: - Game Details

    static func gameDetails(
        startsAt: Date,
        durationMinutes: Int = 60,
        maxPlayers: Int = 10,
        joinedPlayers: Int = 4,
        isFinished: Bool = false,
        players: [Player]? = nil
    ) -> GameDetails {
        let roster = players ?? [
            player(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, team: .alpha),
            player(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, team: .beta)
        ]

        let playersJSON = roster.map { playerJSON($0) }.joined(separator: ",")

        return decode(GameDetails.self, from: """
        {
            "id": "\(gameId.uuidString)",
            "starts_at": "\(iso8601(startsAt))",
            "duration_minutes": \(durationMinutes),
            "max_players": \(maxPlayers),
            "joined_players": \(joinedPlayers),
            "is_finished": \(isFinished),
            "sport": {
                "id": "\(sportFootballId.uuidString)",
                "name": "football"
            },
            "park": {
                "id": "\(parkId.uuidString)",
                "name": "Central Park",
                "latitude": 50.45,
                "longitude": 30.52,
                "hasLighting": true,
                "overallAvg": 4.5
            },
            "players": [\(playersJSON)],
            "is_joined": false,
            "mvp_player": null,
            "is_in_progress": false,
            "is_processed": false,
            "mvp_voting_open": false,
            "has_voted": false
        }
        """)
    }

    // MARK: - Park Hours

    static func parkHour(
        dayOfWeek: Int,
        openHour: String? = "09:00:00",
        closeTime: String? = "22:00:00",
        isClosed: Bool = false
    ) -> ParkHour {
        decode(ParkHour.self, from: """
        {
            "id": \(dayOfWeek),
            "day_of_week": \(dayOfWeek),
            "open_hour": \(openHour.map { "\"\($0)\"" } ?? "null"),
            "close_time": \(closeTime.map { "\"\($0)\"" } ?? "null"),
            "is_closed": \(isClosed)
        }
        """)
    }

    // MARK: - Private Helpers

    private static func decode<T: Decodable>(
        _ type: T.Type,
        from json: String
    ) -> T {
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(type, from: data)
        } catch {
            print(json)
            print(error)
            fatalError("TestFixtures decode failed for \(T.self): \(error)")
        }
    }

    private static func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private static func playerJSON(_ player: Player) -> String {
        let now = iso8601(Date())
        return """
        {
            "id": "\(player.id.uuidString)",
            "username": "\(player.username)",
            "avatar_url": null,
            "team": "\(player.team.rawValue)",
            "rating": \(player.rating),
            "gamesPlayed": \(player.gamesPlayed),
            "createdAt": "\(now)",
            "isTopRated": \(player.isTopRated),
            "isMostActive": \(player.isMostActive),
            "isNewest": \(player.isNewest),
            "mvpVotesCount": \(player.mvpVotesCount),
            "isVotedByCurrentUser": \(player.isVotedByCurrentUser)
        }
        """
    }
}
