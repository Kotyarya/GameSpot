#if DEBUG

import Foundation
import SwiftUI
import UIKit
internal import Auth

enum PreviewFailure: Error {
    case offline
}

enum PreviewFixtures {

    static let userID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
    static let secondUserID = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
    static let gameID = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!
    static let parkID = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!
    static let footballID = UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!
    static let basketballID = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!

    static let date = Date(timeIntervalSince1970: 1_893_456_000)

    static let football = Sport(id: footballID, name: "football")
    static let basketball = Sport(id: basketballID, name: "basketball")
    static let sports = [football, basketball]

    static let park = Park(
        id: parkID,
        name: "Riverside Sports Park",
        latitude: 52.2297,
        longitude: 21.0122,
        address: "12 River Street",
        isActive: true,
        hasLighting: true
    )

    static let parkDetails = ParkDetails(
        park: park,
        sports: sports,
        hours: (1...7).map {
            ParkHour(
                id: $0,
                dayOfWeek: $0,
                openHour: "08:00:00",
                closeTime: "22:00:00",
                isClosed: false
            )
        },
        images: [],
        rating: ParkRating(
            qualityAvg: 4.7,
            qualityCount: 38,
            facilitiesAvg: 4.3,
            facilitiesCount: 31,
            activityAvg: 4.8,
            activityCount: 42,
            overallAvg: 4.6
        )
    )

    static let profile = Profile(
        id: userID,
        username: "alex.player",
        avatarUrl: nil,
        favoriteSportId: footballID,
        favoriteSport: football,
        rating: 2_480,
        gamesPlayed: 46,
        mvpCount: 9,
        perfPoints: 3_720,
        isOnboarded: true,
        isProfileCompleted: true,
        createdAt: date,
        updatedAt: date
    )

    static let publicProfile = Profile(
        id: secondUserID,
        username: "sam.striker",
        avatarUrl: nil,
        favoriteSportId: basketballID,
        favoriteSport: basketball,
        rating: 1_760,
        gamesPlayed: 28,
        mvpCount: 4,
        perfPoints: 1_940,
        isOnboarded: true,
        isProfileCompleted: true,
        createdAt: date,
        updatedAt: date
    )

    static let stats = [
        UserSportStats(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
            userId: userID,
            sportId: footballID,
            rating: 2_480,
            gamesPlayed: 32,
            mvpCount: 7,
            perfPoints: 2_860,
            sport: football
        ),
        UserSportStats(
            id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
            userId: userID,
            sportId: basketballID,
            rating: 1_120,
            gamesPlayed: 14,
            mvpCount: 2,
            perfPoints: 860,
            sport: basketball
        )
    ]

    static let recentMatches = [
        RecentMatch(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!,
            startsAt: date,
            sport: football,
            ratingChange: 42,
            perfPointsEarned: 110,
            wasMVP: true
        ),
        RecentMatch(
            id: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!,
            startsAt: date.addingTimeInterval(-86_400),
            sport: basketball,
            ratingChange: -12,
            perfPointsEarned: 45,
            wasMVP: false
        )
    ]

    static let currentPlayer = Player(
        id: userID,
        username: "alex.player",
        avatarUrl: nil,
        team: .alpha,
        rating: 2_480,
        gamesPlayed: 46,
        createdAt: date,
        isTopRated: true,
        isMostActive: false,
        isNewest: false,
        mvpVotesCount: 4,
        isVotedByCurrentUser: false
    )

    static let secondPlayer = Player(
        id: secondUserID,
        username: "sam.striker",
        avatarUrl: nil,
        team: .beta,
        rating: 1_760,
        gamesPlayed: 28,
        createdAt: date,
        isTopRated: false,
        isMostActive: true,
        isNewest: false,
        mvpVotesCount: 2,
        isVotedByCurrentUser: true
    )

    static let players = [currentPlayer, secondPlayer]

    static let upcomingGame = Game(
        id: gameID,
        parkId: parkID,
        creatorId: userID,
        sport: football,
        startsAt: date.addingTimeInterval(86_400),
        durationMinutes: 90,
        maxPlayers: 10,
        isFinished: false,
        isProcessed: false,
        isInProgress: false,
        mvpVotingOpen: false,
        joinedPlayers: 4
    )

    static let finishedGame = Game(
        id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!,
        parkId: parkID,
        creatorId: secondUserID,
        sport: basketball,
        startsAt: date.addingTimeInterval(-172_800),
        durationMinutes: 60,
        maxPlayers: 10,
        isFinished: true,
        isProcessed: true,
        isInProgress: false,
        mvpVotingOpen: false,
        joinedPlayers: 10
    )

    static let games = [upcomingGame, finishedGame]

    static let gameDetails = GameDetails(
        id: gameID,
        startsAt: date.addingTimeInterval(86_400),
        durationMinutes: 90,
        maxPlayers: 10,
        joinedPlayers: players.count,
        isFinished: false,
        sport: football,
        park: ParkShort(
            id: parkID,
            name: park.name,
            latitude: park.latitude,
            longitude: park.longitude,
            hasLighting: true,
            overallAvg: 4.6
        ),
        players: players,
        isJoined: true,
        mvpPlayer: nil,
        isInProgress: false,
        isProcessed: false,
        mvpVotingOpen: false,
        hasVoted: false
    )

    static let members = players.map {
        GameMember(userId: $0.id, team: $0.team)
    }

    static let blockedUsers = [
        BlockedUser(
            blockedId: secondUserID,
            blockedUsername: secondPlayer.username,
            blockedAvatarUrl: nil,
            createdAt: date
        )
    ]

    static let weather = Weather(
        temperature: 18,
        windSpeed: 8,
        rainChance: 15
    )

    static let publicSummary = PublicProfileSummary(
        player: secondPlayer
    )

    static let user = User(
        id: userID,
        appMetadata: [:],
        userMetadata: [:],
        aud: "authenticated",
        email: "preview@gamespot.local",
        createdAt: date,
        updatedAt: date
    )
}

@MainActor
final class PreviewAuthService:
    AuthServing,
    PasswordRecoveryServing,
    SessionAuthServing {

    var currentUser: User?

    init(currentUser: User? = PreviewFixtures.user) {
        self.currentUser = currentUser
    }

    func signUp(email: String, password: String) async throws -> AuthSignUpResult {
        .confirmationRequired(email: email)
    }

    func signIn(email: String, password: String) async throws {}
    func resendSignUpConfirmation(email: String) async throws {}
    func requestPasswordReset(email: String) async throws {}
    func updatePassword(_ password: String) async throws {}
    func signOut() async throws { currentUser = nil }
}

@MainActor
final class PreviewProfileService:
    ProfileFetching,
    ProfileSetupServing,
    ProfileAvatarUpdating,
    @unchecked Sendable {

    let profileResult: Result<Profile, Error>
    let statsResult: Result<[UserSportStats], Error>
    let recentMatchesResult: Result<[RecentMatch], Error>

    init(
        profileResult: Result<Profile, Error> = .success(PreviewFixtures.profile),
        statsResult: Result<[UserSportStats], Error> = .success(PreviewFixtures.stats),
        recentMatchesResult: Result<[RecentMatch], Error> = .success(PreviewFixtures.recentMatches)
    ) {
        self.profileResult = profileResult
        self.statsResult = statsResult
        self.recentMatchesResult = recentMatchesResult
    }

    func fetchProfile(userId: UUID) async throws -> Profile {
        try profileResult.get()
    }

    func fetchUserStats(userId: UUID) async throws -> [UserSportStats] {
        try statsResult.get()
    }

    func getRecentMatches() async throws -> [RecentMatch] {
        try recentMatchesResult.get()
    }

    func isUsernameAvailable(_ username: String) async throws -> Bool { true }

    func completeProfile(
        userId: UUID,
        username: String,
        avatarUrl: String?,
        sportId: UUID
    ) async throws {}

    func updateAvatar(userId: UUID, avatarUrl: String?) async throws {}
}

@MainActor
final class PreviewParkService: ParksFetching, ParkDetailsServing {

    let parksResult: Result<[Park], Error>
    let detailsResult: Result<ParkDetails, Error>

    init(
        parksResult: Result<[Park], Error> = .success([PreviewFixtures.park]),
        detailsResult: Result<ParkDetails, Error> = .success(PreviewFixtures.parkDetails)
    ) {
        self.parksResult = parksResult
        self.detailsResult = detailsResult
    }

    func fetchParks() async throws -> [Park] { try parksResult.get() }
    func fetchParkDetails(parkId: UUID) async throws -> ParkDetails { try detailsResult.get() }
    func ratePark(userId: UUID, parkId: UUID, quality: Int, facilities: Int, activity: Int) async throws {}
    func hasUserRated(userId: UUID, parkId: UUID) async throws -> Bool { false }
}

@MainActor
final class PreviewGameService: GamesFetching, GameCreating, GameInfoServing {

    let gamesResult: Result<[Game], Error>
    let detailsResult: Result<GameDetails, Error>
    let membersResult: Result<[GameMember], Error>

    init(
        gamesResult: Result<[Game], Error> = .success(PreviewFixtures.games),
        detailsResult: Result<GameDetails, Error> = .success(PreviewFixtures.gameDetails),
        membersResult: Result<[GameMember], Error> = .success(PreviewFixtures.members)
    ) {
        self.gamesResult = gamesResult
        self.detailsResult = detailsResult
        self.membersResult = membersResult
    }

    func fetchGamesByPark(parkId: UUID) async throws -> [Game] { try gamesResult.get() }
    func fetchUserGames() async throws -> [Game] { try gamesResult.get() }
    func createGame(parkId: UUID, sportId: UUID, startsAt: Date) async throws -> UUID { PreviewFixtures.gameID }
    func fetchGameDetails(gameId: UUID) async throws -> GameDetails { try detailsResult.get() }
    func fetchGameMembers(gameId: UUID) async throws -> [GameMember] { try membersResult.get() }
    func joinGame(gameId: UUID, team: Team) async throws {}
    func leaveGame(gameId: UUID) async throws {}
    func voteMVP(gameId: UUID, votedUserId: UUID) async throws {}
}

@MainActor
final class PreviewRealtimeService:
    GamesRealtimeSubscribing,
    GameInfoRealtimeSubscribing,
    ProfileRealtimeSubscribing,
    @unchecked Sendable {

    func subscribe(onChange: @escaping @MainActor @Sendable () async -> Void) async throws {}
    func subscribe(gameId: UUID, onChange: @escaping @MainActor @Sendable () async -> Void) async throws {}
    func subscribe(
        userId: UUID,
        onProfileChange: @escaping @MainActor @Sendable (Profile) async -> Void,
        onStatsChange: @escaping @MainActor @Sendable () async -> Void
    ) async throws {}
    func unsubscribe() async {}
}

@MainActor
final class PreviewAvatarService: AvatarStoring {
    func uploadAvatar(_ image: UIImage, userId: UUID) async throws -> URL {
        URL(string: "gamespot-preview://avatar")!
    }
    func removeAvatar(userId: UUID) async throws {}
}

@MainActor
final class PreviewWeatherService: WeatherFetching {
    func fetchWeather(latitude: Double, longitude: Double, date: Date) async throws -> Weather {
        PreviewFixtures.weather
    }
}

final class PreviewSportService: SportFetching, @unchecked Sendable {
    let result: Result<[Sport], Error>

    init(result: Result<[Sport], Error> = .success(PreviewFixtures.sports)) {
        self.result = result
    }

    func fetchSports() async throws -> [Sport] { try result.get() }
}

@MainActor
final class PreviewSafetyService: UserSafetyServing, @unchecked Sendable {
    let result: Result<[BlockedUser], Error>

    init(result: Result<[BlockedUser], Error> = .success(PreviewFixtures.blockedUsers)) {
        self.result = result
    }

    func submitReport(userId: UUID, reason: ReportReason, details: String?) async throws -> Bool { true }
    func setBlocked(userId: UUID, isBlocked: Bool) async throws {}
    func fetchBlockedUsers() async throws -> [BlockedUser] { try result.get() }
}

@MainActor
struct PreviewAccountDeletionService: AccountDeleting {
    func deleteAccount() async throws {}
}

@MainActor
enum PreviewFactory {

    static func session(
        signedIn: Bool = true,
        profile: Profile? = PreviewFixtures.profile
    ) -> SessionManager {
        let auth = PreviewAuthService(
            currentUser: signedIn ? PreviewFixtures.user : nil
        )
        let session = SessionManager(
            authService: auth,
            profileService: PreviewProfileService(),
            restoreSessionOnInit: false
        )
        session.user = auth.currentUser
        session.profile = signedIn ? profile : nil
        session.didCheckSession = true
        return session
    }

    static func map(
        parks: Result<[Park], Error> = .success([PreviewFixtures.park])
    ) -> MapViewModel {
        MapViewModel(service: PreviewParkService(parksResult: parks))
    }

    static func parkDetails(
        result: Result<ParkDetails, Error> = .success(PreviewFixtures.parkDetails)
    ) -> ParkDetailsViewModel {
        ParkDetailsViewModel(service: PreviewParkService(detailsResult: result))
    }

    static func games(
        result: Result<[Game], Error> = .success(PreviewFixtures.games)
    ) -> GamesViewModel {
        GamesViewModel(
            service: PreviewGameService(gamesResult: result),
            realtime: PreviewRealtimeService(),
            minimumLoadingDuration: 0
        )
    }

    static func profile(
        service: PreviewProfileService = PreviewProfileService()
    ) -> ProfileViewModel {
        ProfileViewModel(
            service: service,
            realtime: PreviewRealtimeService(),
            avatarStorage: PreviewAvatarService(),
            avatarUpdater: service,
            minimumLoadingDuration: 0
        )
    }

    static func publicProfile(
        service: PreviewProfileService = PreviewProfileService(
            profileResult: .success(PreviewFixtures.publicProfile)
        )
    ) -> PublicProfileViewModel {
        PublicProfileViewModel(service: service)
    }

    static func profileSetup() -> ProfileSetupViewModel {
        ProfileSetupViewModel(
            profileService: PreviewProfileService(),
            sportService: PreviewSportService(),
            avatarStorage: PreviewAvatarService(),
            minimumLoadingDuration: 0
        )
    }

    static func blockedUsers(
        result: Result<[BlockedUser], Error> = .success(PreviewFixtures.blockedUsers)
    ) -> BlockedUsersViewModel {
        BlockedUsersViewModel(service: PreviewSafetyService(result: result))
    }

    static func gameInfo() -> GameInfoViewModel {
        GameInfoViewModel(
            gameService: PreviewGameService(),
            weatherService: PreviewWeatherService(),
            realtime: PreviewRealtimeService()
        )
    }

    static func createGame() -> CreateGameViewModel {
        CreateGameViewModel(
            service: PreviewGameService(),
            loadingDelay: .zero
        )
    }
}

#endif
