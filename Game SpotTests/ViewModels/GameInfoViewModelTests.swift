import XCTest
@testable import Game_Spot

@MainActor
final class GameInfoViewModelTests: XCTestCase {

    func testInitialState() {
        let viewModel = makeViewModel()

        XCTAssertNil(viewModel.details)
        XCTAssertNil(viewModel.weather)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSubmittingVote)
    }

    func testLoadPublishesDetailsWeatherAndSubscribes() async {
        let startsAt = Date(timeIntervalSince1970: 1_800_000_000)
        let details = TestFixtures.gameDetails(startsAt: startsAt)
        let service = GameInfoServiceStub(detailsResult: .success(details))
        let weatherService = WeatherServiceStub(
            result: .success(
                Weather(temperature: 18, windSpeed: 7, rainChance: 20)
            )
        )
        let realtime = GameInfoRealtimeStub()
        let viewModel = makeViewModel(
            gameService: service,
            weatherService: weatherService,
            realtime: realtime
        )

        await viewModel.load(gameId: TestFixtures.gameId)

        XCTAssertEqual(viewModel.details?.id, TestFixtures.gameId)
        XCTAssertEqual(viewModel.weather?.temperature, 18)
        XCTAssertEqual(weatherService.receivedLatitude, 50.45)
        XCTAssertEqual(weatherService.receivedLongitude, 30.52)
        XCTAssertEqual(weatherService.receivedDate, startsAt)
        XCTAssertEqual(realtime.receivedGameIds, [TestFixtures.gameId])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadFailureStopsLoadingWithoutWeatherOrRealtime() async {
        let service = GameInfoServiceStub(
            detailsResult: .failure(GameInfoTestError.failed)
        )
        let weatherService = WeatherServiceStub()
        let realtime = GameInfoRealtimeStub()
        let viewModel = makeViewModel(
            gameService: service,
            weatherService: weatherService,
            realtime: realtime
        )

        await viewModel.load(gameId: TestFixtures.gameId)

        XCTAssertNil(viewModel.details)
        XCTAssertEqual(
            viewModel.errorMessage,
            GameInfoTestError.failed.localizedDescription
        )
        XCTAssertEqual(weatherService.fetchCallCount, 0)
        XCTAssertTrue(realtime.receivedGameIds.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testCancelledLoadAlwaysStopsLoading() async {
        let service = CancellingGameInfoServiceStub()
        let viewModel = makeViewModel(gameService: service)

        let task = Task {
            await viewModel.load(gameId: TestFixtures.gameId)
        }

        while !service.isFetchingDetails {
            await Task.yield()
        }

        task.cancel()
        await task.value

        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSubmitVoteWithoutDetailsDoesNotCallService() async {
        let service = GameInfoServiceStub()
        let viewModel = makeViewModel(gameService: service)

        await viewModel.submitVote(playerId: TestFixtures.userId)

        XCTAssertEqual(service.voteCallCount, 0)
        XCTAssertFalse(viewModel.isSubmittingVote)
    }

    func testSubmitVoteKeepsFlagVisibleAndForwardsArguments() async {
        let service = SuspendedVoteGameInfoServiceStub()
        let viewModel = makeViewModel(gameService: service)
        viewModel.details = TestFixtures.gameDetails(
            startsAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let playerId = UUID()

        let task = Task {
            await viewModel.submitVote(playerId: playerId)
        }

        while !service.isVoteSuspended {
            await Task.yield()
        }

        XCTAssertTrue(viewModel.isSubmittingVote)

        service.resumeVote()
        await task.value

        XCTAssertEqual(service.receivedVoteGameId, TestFixtures.gameId)
        XCTAssertEqual(service.receivedVotedUserId, playerId)
        XCTAssertFalse(viewModel.isSubmittingVote)
    }

    func testJoinFailureShowsError() async {
        let service = GameInfoServiceStub(joinError: GameInfoTestError.failed)
        let viewModel = makeViewModel(gameService: service)

        await viewModel.joinGame(
            gameId: TestFixtures.gameId,
            team: .alpha
        )

        XCTAssertEqual(service.receivedJoinTeam, .alpha)
        XCTAssertEqual(
            viewModel.errorMessage,
            GameInfoTestError.failed.localizedDescription
        )
    }

    private func makeViewModel(
        gameService: (any GameInfoServing)? = nil,
        weatherService: (any WeatherFetching)? = nil,
        realtime: (any GameInfoRealtimeSubscribing)? = nil
    ) -> GameInfoViewModel {

        GameInfoViewModel(
            gameService: gameService ?? GameInfoServiceStub(),
            weatherService: weatherService ?? WeatherServiceStub(),
            realtime: realtime ?? GameInfoRealtimeStub()
        )
    }
}

@MainActor
private class GameInfoServiceStub: GameInfoServing {

    private let detailsResult: Result<GameDetails, Error>
    private let joinError: Error?

    private(set) var voteCallCount = 0
    private(set) var receivedJoinTeam: Team?

    init(
        detailsResult: Result<GameDetails, Error> = .success(
            TestFixtures.gameDetails(
                startsAt: Date(timeIntervalSince1970: 1_800_000_000)
            )
        ),
        joinError: Error? = nil
    ) {

        self.detailsResult = detailsResult
        self.joinError = joinError
    }

    func fetchGameDetails(
        gameId: UUID
    ) async throws -> GameDetails {

        try detailsResult.get()
    }

    func joinGame(
        gameId: UUID,
        team: Team
    ) async throws {

        receivedJoinTeam = team

        if let joinError {
            throw joinError
        }
    }

    func leaveGame(
        gameId: UUID
    ) async throws {}

    func voteMVP(
        gameId: UUID,
        votedUserId: UUID
    ) async throws {

        voteCallCount += 1
    }
}

@MainActor
private final class CancellingGameInfoServiceStub: GameInfoServiceStub {

    private(set) var isFetchingDetails = false

    override func fetchGameDetails(
        gameId: UUID
    ) async throws -> GameDetails {

        isFetchingDetails = true
        try await Task.sleep(for: .seconds(60))
        throw CancellationError()
    }
}

@MainActor
private final class SuspendedVoteGameInfoServiceStub: GameInfoServiceStub {

    private var voteContinuation: CheckedContinuation<Void, Never>?
    private(set) var isVoteSuspended = false
    private(set) var receivedVoteGameId: UUID?
    private(set) var receivedVotedUserId: UUID?

    override func voteMVP(
        gameId: UUID,
        votedUserId: UUID
    ) async throws {

        receivedVoteGameId = gameId
        receivedVotedUserId = votedUserId
        isVoteSuspended = true

        await withCheckedContinuation { continuation in
            voteContinuation = continuation
        }
    }

    func resumeVote() {
        voteContinuation?.resume()
        voteContinuation = nil
    }
}

@MainActor
private final class WeatherServiceStub: WeatherFetching {

    private let result: Result<Weather, Error>
    private(set) var fetchCallCount = 0
    private(set) var receivedLatitude: Double?
    private(set) var receivedLongitude: Double?
    private(set) var receivedDate: Date?

    init(
        result: Result<Weather, Error> = .success(
            Weather(temperature: 20, windSpeed: 5, rainChance: 10)
        )
    ) {

        self.result = result
    }

    func fetchWeather(
        latitude: Double,
        longitude: Double,
        date: Date
    ) async throws -> Weather {

        fetchCallCount += 1
        receivedLatitude = latitude
        receivedLongitude = longitude
        receivedDate = date
        return try result.get()
    }
}

@MainActor
private final class GameInfoRealtimeStub: GameInfoRealtimeSubscribing {

    private(set) var receivedGameIds: [UUID] = []

    func subscribe(
        gameId: UUID,
        onChange: @escaping @MainActor @Sendable () async -> Void
    ) async throws {

        receivedGameIds.append(gameId)
    }

    func unsubscribe() async {}
}

private enum GameInfoTestError: LocalizedError {

    case failed

    var errorDescription: String? {
        "Game request failed"
    }
}
